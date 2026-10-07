# File simulasi alokasi subnet jaringan lokal
resource "local_file" "network_config" {
  filename = "${path.module}/network_topology.json"
  content = jsonencode({
    vpc_cidr       = "10.0.0.0/16"
    public_subnet  = "10.0.1.0/24"
    private_subnet = "10.0.2.0/24"
    gateway        = "10.0.0.1"
    target_host    = "192.168.1.103"
  })
}
