#Output Display
output "instance_public_ip" {
    description = "Public IP"
    value = aws_eip.one.public_ip
   
}

output "instance_avaialbility_zone" {   
    description = "Availability Zone"
    value = aws_instance.project1-web-server.availability_zone

}

output "instance_type" {   
    description = "Instance Type"
    value = aws_instance.project1-web-server.instance_type

}

output "keypair" {   
    description = "Key Pair"
    value = aws_instance.project1-web-server.key_name

}
output "ebs_volume_id" {
  value = "${data.aws_ebs_volume.ebs_volume.id}"
}
