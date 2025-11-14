# Storage volumes for the VM

# Create a base Ubuntu 24.04 volume from cloud image
# This downloads the official Ubuntu 24.04 LTS server cloud image
resource "libvirt_volume" "ubuntu_base" {
  name   = "ubuntu-24.04-base.qcow2"
  pool   = "default"
  format = "qcow2"

  create = {
    content = {
      url = "https://cloud-images.ubuntu.com/releases/24.04/release/ubuntu-24.04-server-cloudimg-amd64.img"
    }
  }
}

# Create a volume for the VM based on Ubuntu 24.04
# This creates a copy-on-write volume using the base image
resource "libvirt_volume" "vm_disk" {
  name     = "${var.vm_name}-disk.qcow2"
  pool     = "default"
  format   = "qcow2"
  capacity = var.vm_disk_size

  backing_store = {
    path   = libvirt_volume.ubuntu_base.path
    format = "qcow2"
  }
}