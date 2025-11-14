# Main Terraform configuration for libvirt Ubuntu 24.04 VM
# 
# This file orchestrates the creation of a complete Ubuntu 24.04 VM
# with network connectivity, SSH access, and console support.
#
# File structure:
# - providers.tf     : Provider configuration
# - variables.tf     : Input variables
# - volumes.tf       : Storage volumes (base image + VM disk)
# - vm.tf           : VM domain and cloud-init configuration  
# - provisioners.tf  : Post-creation configuration and testing
# - outputs.tf       : Output values
# - cloud_init.yml   : Cloud-init configuration template
#
# Usage:
#   terraform init
#   terraform plan
#   terraform apply
#
# Or use the Makefile:
#   make deploy        # Full deployment
#   make vm-ssh        # SSH to VM
#   make vm-console    # Console access
#   make vm-status     # Check VM status

# This main.tf file is intentionally minimal - all resources are defined
# in separate files for better organization and maintainability.