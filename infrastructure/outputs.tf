/* 
outputs.tf

Outputs.

Terraform v0.11.11
+ provider.aws v1.60.0
+ provider.external v1.0.0
+ provider.null v2.0.0

 */

output "cluster_size" {
   value = "${aws_instance.cluster_master.count + aws_instance.cluster_workers.count}"
}

output "ips" {
   value = ["${aws_eip.elastic_ips.*.public_ip}"]
}

output "token_command" {
   value = "${lookup(data.external.generate-token.result, "token_command")}"
}

output "public_master_dns" {
   value = "${aws_instance.cluster_master.public_dns}"
}

output "public_master_ip" {
   value = "${aws_instance.cluster_master.public_ip}"
}

