/* 
main.tf

Main configuration file for a one-step provisioning of a k8s cluster. A k8s cluster 
is provisioned on AWS as a demonstration. General information is available at 
https://docs.nvidia.com/datacenter/kubernetes/kubernetes-install-guide/index.html

If worker nodes are added to an existing cluster, new nodes will be joined with the master. 
To control gpu costs, however, a more practical way is to i) drain and delete nodes via kubectl 
and ii) to stop and start nodes.

Terraform v0.11.11
+ provider.aws v1.60.0
+ provider.external v1.0.0
+ provider.null v2.0.0
*/

# provider specs

provider "aws" {
    region   = "${var.aws_region}"
    version  = "~> 1.14"
}

# availability zones

data "aws_availability_zones" "all" {}

# vpc

module "sandbox_vpc" {
    source  = "terraform-aws-modules/vpc/aws"
    version = "1.30.0"
    name = "${var.owner_name}-vpc"

    cidr             = "10.0.0.0/16"
    azs              = ["${data.aws_availability_zones.all.names}"]
    public_subnets   = ["10.0.0.0/28"]

    enable_dns_support   = true
    enable_dns_hostnames = true
    enable_s3_endpoint = true

    tags = {
        Owner       = "${var.owner_name}"
        Environment = "dev"
        Terraform   = "true"
    }
}  

# vpc security groups
/*
This setup is not secure and is only intended for development and experimentation purposes.
*/

resource "aws_security_group" "ssh_sg_ext_ssh" {
    description = "externally ssh"
    vpc_id	= "${module.sandbox_vpc.vpc_id}"

    ingress {
        protocol  = "tcp"
        from_port = 22
        to_port   = 22
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        protocol    = "-1"
        from_port   = 0
        to_port     = 0
        cidr_blocks = ["0.0.0.0/0"]
    }
    
    tags = {
        Name        = "vpc-ssh-sg-ext_ssh"
        Owner       = "${var.owner_name}"
        Environment = "dev"
        Terraform   = "true"
    }
}

resource "aws_security_group" "ssh_sg_int_open" {
    description = "internally open"
    vpc_id	= "${module.sandbox_vpc.vpc_id}"

    ingress {
        protocol  = "-1"
        from_port = 0
        to_port   = 0
        cidr_blocks   = ["10.0.0.0/28"]
    }

    egress {
        protocol    = "-1"
        from_port   = 0
        to_port     = 0
        cidr_blocks   = ["10.0.0.0/28"]
    }
    
    tags = {
        Name        = "vpc-ssh-sg-int_open"
        Owner       = "${var.owner_name}"
        Environment = "dev"
        Terraform   = "true"
    }
}

# configuration of a k8s master and worker instances
/*
If there are connectivity issues (e.g. download failures) during provisioning, hit terraform apply 
again to provision the remaining/failed parts.
*/

resource "aws_instance" "cluster_master" {
    ami             = "ami-0b294f219d14e6a82"
    instance_type   = "m4.large"
    key_name        = "${var.keypair_name}"
    count           = 1

    vpc_security_group_ids      = ["${aws_security_group.ssh_sg_ext_ssh.id}", 
                                   "${aws_security_group.ssh_sg_int_open.id}"]
    subnet_id                   = "${module.sandbox_vpc.public_subnets[0]}"
    associate_public_ip_address = true
    
    root_block_device {
        volume_size = 100
        volume_type = "standard"
    }

    connection {
        type = "ssh"
        user = "${var.ssh_user}"
        port = "${var.ssh_port}"
        private_key = "${file("${var.path_to_private_key}")}"
    }
    
    provisioner "remote-exec" {
        inline = [
            "curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -",
            "curl -s -L https://nvidia.github.io/kubernetes/gpgkey | sudo apt-key add -",
            "curl -s -L https://nvidia.github.io/kubernetes/ubuntu16.04/nvidia-kubernetes.list | sudo tee /etc/apt/sources.list.d/nvidia-kubernetes.list",
            "sudo apt update",
            "sudo rm /var/lib/dpkg/lock",
            "sudo rm /var/lib/dpkg/lock-frontend",
            "sudo dpkg --configure -a",
            "VERSION=1.10.11+nvidia",
            "sudo apt install -y kubectl=$${VERSION} kubelet=$${VERSION} kubeadm=$${VERSION} helm=$${VERSION}",
            "sudo kubeadm init --ignore-preflight-errors=all --config /etc/kubeadm/config.yml",
            "sudo chmod 644 /etc/apt/sources.list.d/nvidia-kubernetes.list"
        ]
    }

    tags {
        Name        = "${var.cluster_name}-master-${count.index}"
        Owner       = "${var.owner_name}"
        Environment = "dev"
        Terraform   = "true"
    }
}

resource "aws_instance" "cluster_workers" {
    ami             = "ami-0b7685a4041eafcfd"
    instance_type   = "p3.2xlarge"
    key_name        = "${var.keypair_name}"
    count           = 4

    vpc_security_group_ids      = ["${aws_security_group.ssh_sg_ext_ssh.id}", 
                                   "${aws_security_group.ssh_sg_int_open.id}"]
    subnet_id                   = "${module.sandbox_vpc.public_subnets[0]}"
    
    root_block_device {
        volume_size = 100
        volume_type = "standard"
    }

    connection {
        type = "ssh"
        user = "${var.ssh_user}"
        port = "${var.ssh_port}"
        private_key = "${file("${var.path_to_private_key}")}"
    }
 
    provisioner "remote-exec" {
        inline = [
            "curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -",
            "curl -s -L https://nvidia.github.io/kubernetes/gpgkey | sudo apt-key add -",
            "curl -s -L https://nvidia.github.io/kubernetes/ubuntu16.04/nvidia-kubernetes.list | sudo tee /etc/apt/sources.list.d/nvidia-kubernetes.list",
            "sudo rm /var/lib/apt/lists/* -vf",
            "sudo apt update",
            "sudo rm /var/lib/dpkg/lock",
            "sudo rm /var/lib/dpkg/lock-frontend",
            "sudo dpkg --configure -a",
            "VERSION=1.10.11+nvidia",
            "sudo apt install -y kubectl=$${VERSION} kubelet=$${VERSION} kubeadm=$${VERSION} helm=$${VERSION}"
        ]
    }

    tags {
        Name        = "${var.cluster_name}-worker-${count.index}"
        Owner       = "${var.owner_name}"
        Environment = "dev"
        Terraform   = "true"
    }
}

# join workers to the master
/*
If the null_resource is hanging, hit CTRL C, and check the cluster master. If worker nodes are 
not yet joined, hit terraform apply again to complete this last step.
This is an open Terraform issue: https://github.com/hashicorp/terraform/issues/12596
*/

data "external" "generate-token" {
    depends_on	= ["aws_instance.cluster_master"]
    program	= ["bash", "${path.module}/generate-token.sh"]

    query	= {
        path_to_priv_key = "${var.path_to_private_key}"
        host = "${aws_instance.cluster_master.public_ip}"
        user = "${var.ssh_user}"   
    }
}

resource "null_resource" "connect-nodes" {
    depends_on  = ["aws_instance.cluster_workers", "data.external.generate-token"]
    count	= "${aws_instance.cluster_workers.count}"
    
    connection {
        type = "ssh"
        user = "${var.ssh_user}"
        port = "${var.ssh_port}"
        private_key = "${file("${var.path_to_private_key}")}"
        host = "${element(aws_instance.cluster_workers.*.public_ip, count.index)}"
    }

    provisioner "remote-exec" {
        inline = [
            "sudo ${lookup(data.external.generate-token.result, "token_command")}"
        ] 
    }
}

# elastic IPs

resource "aws_eip" "elastic_ips" {
    vpc       = true
    instance  = "${element(concat(aws_instance.cluster_master.*.id, aws_instance.cluster_workers.*.id), count.index)}"
    count     = "${aws_instance.cluster_master.count + aws_instance.cluster_workers.count}"
}

