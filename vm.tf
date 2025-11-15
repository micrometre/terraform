# VM configuration

# Create cloud-init disk
resource "libvirt_cloudinit_disk" "commoninit" {
  name = "${var.vm_name}-cloudinit.iso"
  user_data = templatefile("${path.module}/cloud_init.yml", {
    hostname       = var.vm_name
    ssh_public_key = file("~/.ssh/id_rsa.pub")
  })
  meta_data = ""
}

# VM creation is handled entirely by the null_resource provisioner
# This approach bypasses Terraform libvirt provider syntax issues