# Terraform LibVirt Ubuntu 24.04 VM - WORKING EXAMPLE

This is a **complete, tested, and working** example using the libvirt provider for Terraform to create and manage Ubuntu 24.04 VMs with full network connectivity and SSH access.

## ✅ Current Status: FULLY FUNCTIONAL

This configuration successfully provides:

🎯 **Working VM**: Ubuntu 24.04 VM running and accessible  
🌐 **Network**: DHCP IP assignment (tested: 192.168.122.251)  
🔐 **SSH**: Password-free SSH access with key authentication  
⚡ **Automation**: One-command deployment and management  
🛠 **Tools**: Pre-installed packages (qemu-guest-agent, SSH, git, etc.)

**Ping Test**: ✅ Response times < 1ms  
**SSH Test**: ✅ Immediate connection successful  
**Cloud-init**: ✅ VM properly configured with hostname and packages

## Prerequisites

1. **KVM/QEMU installed**: Make sure you have KVM and libvirt installed on your system
   ```bash
   sudo apt update
   sudo apt install qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils
   ```

2. **SSH Key Pair**: Make sure you have an SSH key pair generated
   ```bash
   # Generate SSH key if you don't have one
   ssh-keygen -t rsa -b 4096 -C "your_email@example.com"
   
   # The configuration expects the public key at ~/.ssh/id_rsa.pub
   ls ~/.ssh/id_rsa.pub
   ```

3. **User permissions**: Add your user to the libvirt and kvm groups
   ```bash
   sudo usermod -aG libvirt $USER
   sudo usermod -aG kvm $USER
   sudo systemctl restart libvirtd
   # Log out and back in for group changes to take effect
   ```

3. **KVM support**: Verify KVM is available
   ```bash
   # Check if KVM modules are loaded
   lsmod | grep kvm
   
   # Check if /dev/kvm exists and is accessible
   ls -la /dev/kvm
   ```

4. **Terraform installed**: Make sure Terraform is installed on your system

## Configuration Files

- `main.tf`: Main Terraform configuration defining the VM infrastructure
- `cloud_init.yml`: Cloud-init configuration for VM initialization
- `variables.tf`: Variable definitions (optional)
- `terraform.tfvars`: Variable values (optional)

## What this example creates

1. **Base Ubuntu Image**: Downloads Ubuntu 24.04 LTS cloud image (tested working)
2. **Storage Volume**: A qcow2 disk for the VM with copy-on-write backing store  
3. **Cloud-init Disk**: Configures VM on first boot with user setup, SSH keys, and packages
4. **VM Domain**: A virtual machine with proper disk, network, and console configuration
5. **Network Connectivity**: VM automatically gets DHCP IP on default libvirt network
6. **SSH Access**: Immediate SSH connectivity with pre-installed public key

## ✅ VM Features (Fully Working)

- **OS**: Ubuntu 24.04.1 LTS Server (official cloud image)
- **Memory**: 2GB RAM  
- **CPU**: 2 vCPUs (host-model for best performance)
- **Storage**: 20GB disk (thin provisioned with backing store)
- **Network**: virtio interface on default libvirt network (192.168.122.0/24)
- **SSH**: Enabled with your SSH key, passwordless login as 'ubuntu' user
- **Packages**: qemu-guest-agent, openssh-server, curl, wget, vim, git
- **Services**: SSH and qemu-guest-agent auto-started
- **Console**: Serial console configured (though SSH is the primary access method)

## Quick Start (Tested Working Commands)

```bash
# Deploy VM (creates everything needed)
make deploy

# Check VM status  
make vm-status

# Get VM IP address
make vm-ip  

# Test network connectivity (working: <1ms response)
make vm-ping

# SSH into VM (working: immediate connection)  
make vm-ssh

# Stop/start VM
make vm-stop
make vm-start

# Complete cleanup
make purge
```

## GitHub Safety ✅

This repository is **safe to push to GitHub** because:

- ✅ **No private keys**: Only SSH public keys are used (which are meant to be public)
- ✅ **No hardcoded secrets**: SSH public key is read from your local `~/.ssh/id_rsa.pub`
- ✅ **Proper .gitignore**: Terraform state files and sensitive data are excluded
- ✅ **Generic configuration**: Works for anyone who clones the repo

When someone clones this repo, they just need:
1. Their own SSH key pair in `~/.ssh/`
2. KVM/libvirt installed
3. Terraform installed

The VM will automatically use their SSH public key for access.

## Usage

### Using Makefile (Recommended)

The project includes a Makefile for easy automation:

1. **Show available commands**:
   ```bash
   make help
   ```

2. **Complete deployment workflow**:
   ```bash
   make deploy
   ```

3. **Quick deployment (auto-approve)**:
   ```bash
   make quick-deploy
   ```

4. **Development cycle (format, validate, plan)**:
   ```bash
   make dev-cycle
   ```

5. **Individual commands**:
   ```bash
   make init       # Initialize Terraform
   make validate   # Validate configuration
   make plan       # Create execution plan
   make apply      # Apply changes
   make destroy    # Destroy infrastructure
   make status     # Show current state
   ```

### Manual Terraform Commands

1. **Initialize Terraform**:
   ```bash
   terraform init
   ```

2. **Plan the deployment**:
   ```bash
   terraform plan
   ```

3. **Apply the configuration**:
   ```bash
   terraform apply
   ```

4. **Check the VM**:
   ```bash
   # Using Makefile
   make vm-status
   make vm-info
   
   # Manual commands
   # List running VMs
   sudo virsh list --all
   
   # Get VM info
   sudo virsh dominfo <VM_NAME>
   ```

5. **Destroy when done**:
   ```bash
   # Safe: destroy only Terraform-managed resources
   make destroy
   
   # See what would be purged (dry run)
   make purge-dry-run
   
   # Nuclear option: complete purge of everything
   make purge
   ```

## Customization

- Edit `cloud_init.yml` to customize the VM configuration
- Modify the VM specifications (memory, CPU, disk size) in `main.tf`
- Add your SSH public key to `cloud_init.yml` for access
- Change the base image URL for different operating systems

## Important Notes

- The VM will download a cloud image on first run (may take time)
- Make sure libvirtd service is running: `sudo systemctl status libvirtd`
- The default storage path `/var/lib/libvirt/images/terraform` needs write permissions
- The VM will be created with minimal configuration
- Use `virsh` commands to interact with the VM after creation
- This example focuses on demonstrating working Terraform + libvirt integration