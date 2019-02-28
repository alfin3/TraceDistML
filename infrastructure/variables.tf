/* 
variables.tf

Variable declarations.

Terraform v0.11.11
+ provider.aws v1.60.0
+ provider.external v1.0.0
+ provider.null v2.0.0
*/

variable "aws_region" {
    default = "us-west-2"
}

variable "keypair_name" {} 

variable "owner_name" {}

variable "path_to_private_key" {} 

variable "cluster_name" {
    default = "k8s"
}

variable "ssh_port" {
    default = 22
}

variable "ssh_user" {
    default = "ubuntu"
}


