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

# Create the VM domain with Ubuntu 24.04
resource "libvirt_domain" "vm" {
  name   = var.vm_name
  memory = var.vm_memory
  vcpu   = var.vm_vcpu

  os = {
    type = "hvm"
  }
}