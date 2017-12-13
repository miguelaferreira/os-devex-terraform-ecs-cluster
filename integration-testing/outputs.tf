output "public_ip" {
  # value = "${aws_eip.test.public_ip}"
  value = "${data.aws_instances.test.public_ips[0]}"
}
