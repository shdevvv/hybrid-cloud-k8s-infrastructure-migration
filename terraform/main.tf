# Otomatisasi pendaftaran IP VM ke inventaris Ansible
resource "local_file" "ansible_inventory" {
  filename = "${path.module}/../ansible/inventory.ini"
  content  = <<EOF
[cloud_servers]
k8s-master ansible_host=192.168.1.103 ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/id_rsa
EOF
}

# Output file untuk menampilkan IP Server
resource "local_file" "outputs" {
  filename = "${path.module}/outputs.tf"
  content  = <<EOF
output "server_ip" {
  value       = "192.168.1.103"
  description = "IP Public / Local dari VM VirtualBox"
}
EOF
}
