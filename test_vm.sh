#!/bin/bash
# Enhanced VM testing script
# Usage: ./test_vm.sh [vm_name]

VM_NAME="${1:-terraform-vm}"

echo "=== Enhanced VM Test Script ==="
echo "VM Name: $VM_NAME"
echo "Timestamp: $(date)"
echo ""

# Check if VM exists
echo "1. Checking if VM exists..."
if sudo virsh dominfo "$VM_NAME" >/dev/null 2>&1; then
    echo "✅ VM '$VM_NAME' found"
else
    echo "❌ VM '$VM_NAME' not found"
    exit 1
fi

# Get VM current state
echo ""
echo "2. Current VM state:"
VM_STATE=$(sudo virsh domstate "$VM_NAME" 2>/dev/null)
echo "   State: $VM_STATE"

# Start VM if it's shut off
if [ "$VM_STATE" = "shut off" ]; then
    echo ""
    echo "3. Starting VM..."
    if sudo virsh start "$VM_NAME"; then
        echo "✅ VM started successfully"
        echo "   Waiting for boot (30 seconds)..."
        sleep 30
    else
        echo "❌ Failed to start VM"
        echo ""
        echo "   Common issues:"
        echo "   - KVM permissions: User needs to be in 'kvm' group"
        echo "   - Hardware virtualization: Check if enabled in BIOS"  
        echo "   - Run 'make check-kvm' for detailed diagnostics"
        echo ""
        echo "   Continuing with tests on shut off VM..."
    fi
else
    echo ""
    echo "3. VM is already running or in transitional state"
fi

# Check VM info after potential startup
echo ""
echo "4. VM Information:"
sudo virsh dominfo "$VM_NAME" | grep -E "(State|CPU|Memory|Autostart)"

# Check storage
echo ""
echo "5. Storage Information:"
echo "   VM Disk:"
sudo virsh vol-info --pool default "${VM_NAME}-disk.qcow2" 2>/dev/null || echo "   Could not get disk info"
echo "   Ubuntu Base Image:"
sudo virsh vol-info --pool default "ubuntu-24.04-base.qcow2" 2>/dev/null || echo "   Could not get base image info"

# Check network (if available)
echo ""
echo "6. Network Information:"
VM_INTERFACES=$(sudo virsh domiflist "$VM_NAME" 2>/dev/null)
if [ $? -eq 0 ]; then
    echo "$VM_INTERFACES"
else
    echo "   Could not get network interface info"
fi

# Final status
echo ""
echo "7. Final Status Check:"
FINAL_STATE=$(sudo virsh domstate "$VM_NAME" 2>/dev/null)
echo "   Final VM State: $FINAL_STATE"

if [ "$FINAL_STATE" = "running" ]; then
    echo "✅ VM is running successfully"
    echo ""
    echo "8. Connection Information:"
    echo "   To connect to console: sudo virsh console $VM_NAME"
    echo "   To get VM IP (if DHCP assigned): sudo virsh net-dhcp-leases default"
    echo "   To shutdown: sudo virsh shutdown $VM_NAME"
else
    echo "⚠️  VM is not in running state"
fi

echo ""
echo "=== Test Complete ==="