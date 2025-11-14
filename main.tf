# Configure the libvirt provider
terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "~> 0.9"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}

# Configure the libvirt provider  
provider "libvirt" {
  uri = "qemu:///system"
}

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

# Create cloud-init disk
resource "libvirt_cloudinit_disk" "commoninit" {
  name = "${var.vm_name}-cloudinit.iso"
  user_data = templatefile("${path.module}/cloud_init.yml", {
    hostname = var.vm_name
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

# Post-creation configuration to add network and disk
resource "null_resource" "vm_config" {
  depends_on = [
    libvirt_domain.vm,
    libvirt_volume.vm_disk,
    libvirt_cloudinit_disk.commoninit
  ]

  # Trigger re-configuration when VM or volumes change
  triggers = {
    vm_id        = libvirt_domain.vm.id
    disk_id      = libvirt_volume.vm_disk.id
    cloudinit_id = libvirt_cloudinit_disk.commoninit.id
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "=== Configuring VM with network and storage ==="
      
      # Ensure VM is shut down
      echo "Shutting down VM..."
      sudo virsh shutdown ${var.vm_name} 2>/dev/null || true
      sudo virsh destroy ${var.vm_name} 2>/dev/null || true
      
      # Wait for shutdown
      echo "Waiting for shutdown..."
      sleep 5
      
      # Remove all existing devices by recreating domain definition
      echo "Cleaning up VM configuration..."
      sudo virsh undefine ${var.vm_name} --nvram 2>/dev/null || true
      
      # Recreate the domain with clean configuration
      cat > /tmp/vm_config.xml << 'EOF'
<domain type='kvm'>
  <name>${var.vm_name}</name>
  <memory unit='KiB'>${var.vm_memory * 1024}</memory>
  <currentMemory unit='KiB'>${var.vm_memory * 1024}</currentMemory>
  <vcpu placement='static'>${var.vm_vcpu}</vcpu>
  <os>
    <type arch='x86_64' machine='pc-i440fx-noble'>hvm</type>
    <boot dev='hd'/>
  </os>
  <cpu mode='host-model'/>
  <clock offset='utc'/>
  <on_poweroff>destroy</on_poweroff>
  <on_reboot>restart</on_reboot>
  <on_crash>restart</on_crash>
  <devices>
    <emulator>/usr/bin/qemu-system-x86_64</emulator>
    <disk type='file' device='disk'>
      <driver name='qemu' type='qcow2'/>
      <source file='${libvirt_volume.vm_disk.path}'/>
      <target dev='vda' bus='virtio'/>
    </disk>
    <disk type='file' device='cdrom'>
      <driver name='qemu' type='raw'/>
      <source file='${libvirt_cloudinit_disk.commoninit.path}'/>
      <target dev='hdb' bus='ide'/>
      <readonly/>
    </disk>
    <interface type='network'>
      <source network='default'/>
      <model type='virtio'/>
    </interface>
    <serial type='pty'>
      <target port='0'/>
    </serial>
    <console type='pty'>
      <target type='serial' port='0'/>
    </console>
    <graphics type='spice' autoport='yes'/>
    <video>
      <model type='qxl'/>
    </video>
    <memballoon model='virtio'/>
  </devices>
</domain>
EOF

      echo "Defining VM with clean configuration..."
      sudo virsh define /tmp/vm_config.xml
      rm -f /tmp/vm_config.xml
      
      # Start VM
      echo "Starting VM..."
      sudo virsh start ${var.vm_name}
      
      echo "✅ VM configuration complete"
      echo "Waiting 60 seconds for boot and cloud-init..."
      sleep 60
      
      echo "VM Status:"
      sudo virsh list --all | grep "${var.vm_name}" || echo "VM not found"
      echo ""
      echo "Network interfaces:"
      sudo virsh domiflist ${var.vm_name}
      echo ""
      echo "Checking for DHCP lease:"
      sudo virsh net-dhcp-leases default
    EOT
  }

  provisioner "local-exec" {
    when    = destroy
    command = "echo 'VM configuration cleanup complete'"
  }
}

# Test provisioner to verify VM functionality
resource "null_resource" "vm_test" {
  count      = var.enable_vm_tests ? 1 : 0
  depends_on = [libvirt_domain.vm]

  # Trigger re-provisioning when VM changes
  triggers = {
    vm_id = libvirt_domain.vm.id
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "=== VM Test Results ==="
      echo "VM Name: ${var.vm_name}"
      echo "VM ID: ${libvirt_domain.vm.id}"
      echo ""
      echo "Waiting for VM to be ready..."
      sleep 10
      echo ""
      echo "VM Status:"
      sudo virsh list --all | grep "${var.vm_name}" || echo "VM not found in virsh list"
      echo ""
      echo "VM Info:"
      sudo virsh dominfo "${var.vm_name}" 2>/dev/null || echo "Could not get VM info"
      echo ""
      echo "VM State:"
      sudo virsh domstate "${var.vm_name}" 2>/dev/null || echo "Could not get VM state"
      echo ""
      echo "Storage volumes:"
      sudo virsh vol-list default | grep "${var.vm_name}" || echo "No volumes found for ${var.vm_name}"
      echo ""
      echo "=== Test Complete ==="
    EOT
  }

  provisioner "local-exec" {
    when    = destroy
    command = "echo 'Cleaning up VM test resources'"
  }
}

# Output the VM information
output "vm_name" {
  value       = libvirt_domain.vm.name
  description = "Name of the VM"
}

output "vm_id" {
  value       = libvirt_domain.vm.id
  description = "ID of the VM domain"
}