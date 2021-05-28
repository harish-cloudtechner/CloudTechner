#output "vpc_id" {
#  description = "ID of project VPC"
#  value       = aws_vpc.main.id
#}
#output "pub_instance_ip" {
#  description = "ID of project VPC"
#  value= aws_instance.publicinstance.private_ip
#}
#output "pri_instance_ip" {
#  description = "ID of project VPC"
#  value= aws_instance.privateinstance.private_ip
#}
### The Ansible inventory file
resource "local_file" "AnsibleInventory" {
 content = templatefile("inventory.tmpl",
 {
  pubinstance-dns = aws_instance.publicinstance.public_dns,
  pubinstance-ip = aws_instance.publicinstance.private_ip,
#  bastion-id = aws_instance.bastion.id,
  private-dns = aws_instance.privateinstance.private_dns,
  priinstance-ip = aws_instance.privateinstance.private_ip,
#  private-id = aws_instance.i-private.*.id
 }
 )
 filename = "inventory"
}
