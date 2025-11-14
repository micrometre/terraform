# Post-creation VM configuration and testing

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

# Ansible provisioner for advanced VM configuration
resource "null_resource" "ansible_provisioner" {
  count = var.enable_ansible ? 1 : 0
  
  depends_on = [
    null_resource.vm_config
  ]

  # Trigger re-provisioning when VM changes
  triggers = {
    vm_id = libvirt_domain.vm.id
    playbook_checksum = filemd5("${path.module}/ansible/playbook.yml")
  }

  # Generate Ansible inventory with actual VM IP
  provisioner "local-exec" {
    command = <<-EOT
      echo "=== Setting up Ansible provisioning ==="
      
      # Wait for VM to get IP address
      echo "Waiting for VM to get IP address..."
      for i in {1..30}; do
        VM_IP=$(sudo virsh net-dhcp-leases default | grep ubuntu | awk '{print $5}' | cut -d'/' -f1)
        if [ ! -z "$VM_IP" ]; then
          echo "VM IP found: $VM_IP"
          break
        fi
        echo "Waiting for IP... ($i/30)"
        sleep 10
      done
      
      if [ -z "$VM_IP" ]; then
        echo "❌ Could not get VM IP address"
        exit 1
      fi
      
      # Generate inventory from template
      export vm_ip="$VM_IP"
      export ansible_user="${var.ansible_user}"
      envsubst < ${path.module}/ansible/inventory.tpl > ${path.module}/ansible/inventory.ini
      
      echo "Generated Ansible inventory:"
      cat ${path.module}/ansible/inventory.ini
    EOT
  }

  # Run Ansible playbook
  provisioner "local-exec" {
    command = <<-EOT
      echo "=== Running Ansible playbook ==="
      cd ${path.module}/ansible
      
      # Test connection first
      echo "Testing Ansible connectivity..."
      ansible vm -m ping || {
        echo "❌ Ansible connection failed"
        exit 1
      }
      
      # Run the playbook
      echo "Running playbook..."
      ansible-playbook playbook.yml -v
      
      echo "✅ Ansible provisioning complete"
    EOT
  }

  provisioner "local-exec" {
    when    = destroy
    command = "echo 'Ansible provisioner cleanup complete'"
  }
}