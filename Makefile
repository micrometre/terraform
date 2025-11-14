# Minimal Terraform libvirt Makefile
# Common workflows:
#   make deploy     - Full deployment (init, plan, apply)
#   make check      - Validate and format code
#   make vm-status  - Check VM status
#   make purge      - Complete cleanup
#   make help       - Show all commands

.PHONY: help init plan apply destroy clean purge

help: ## Show available commands
	@awk 'BEGIN {FS = ":.*##"} /^[a-zA-Z_-]+:.*##/ {printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# Core Terraform commands
init: ## Initialize Terraform
	terraform init

plan: ## Plan changes
	terraform plan

apply: ## Apply changes
	terraform apply

destroy: ## Destroy infrastructure
	terraform destroy

# File management
clean: ## Clean temporary files
	rm -rf .terraform/ .terraform.lock.hcl terraform.plan

purge: ## Complete cleanup (DANGEROUS!)
	@read -p "Type 'PURGE' to confirm: " confirm && [ "$$confirm" = "PURGE" ]
	-terraform destroy -auto-approve
	-sudo virsh shutdown terraform-vm
	-sudo virsh undefine terraform-vm
	-sudo virsh vol-delete terraform-vm-disk.qcow2 --pool default
	-sudo virsh vol-delete ubuntu-24.04-base.qcow2 --pool default
	-rm -rf .terraform/ terraform.tfstate* .terraform.lock.hcl terraform.plan
	@echo "✅ Complete purge finished"

# Workflows
check: ## Validate and format
	terraform fmt && terraform validate

deploy: init plan apply ## Full deployment
	@echo "✅ Deployment complete"

# VM management
vm-status: ## Show VM status
	sudo virsh list --all

vm-start: ## Start VM
	sudo virsh start terraform-vm

vm-stop: ## Stop VM
	sudo virsh shutdown terraform-vm

vm-console: ## Try to connect to VM console (may not work)
	@echo "Connecting to VM console..."
	@echo "💡 Use Ctrl+] to exit console"
	@echo "💡 If console doesn't show prompt, press Enter or try 'sudo virsh destroy terraform-vm && sudo virsh start terraform-vm'"
	sudo virsh console terraform-vm

vm-ip: ## Get VM IP address
	@echo "Checking for VM IP address..."
	@IP=$$(sudo virsh net-dhcp-leases default | grep ubuntu | awk '{print $$5}' | cut -d'/' -f1); \
	if [ -z "$$IP" ]; then \
		echo "❌ No DHCP lease found for VM"; \
		echo "Full DHCP lease table:"; \
		sudo virsh net-dhcp-leases default; \
	else \
		echo "✅ VM IP address: $$IP"; \
	fi

vm-ssh: ## SSH to VM (requires IP and SSH key)
	@IP=$$(sudo virsh net-dhcp-leases default | grep ubuntu | awk '{print $$5}' | cut -d'/' -f1); \
	if [ -z "$$IP" ]; then \
		echo "❌ No DHCP lease found for VM"; \
	else \
		echo "🔗 Connecting to VM at $$IP"; \
		ssh ubuntu@$$IP; \
	fi

vm-ping: ## Ping VM at current IP
	@IP=$$(sudo virsh net-dhcp-leases default | grep ubuntu | awk '{print $$5}' | cut -d'/' -f1); \
	if [ -z "$$IP" ]; then \
		echo "❌ No DHCP lease found for VM"; \
	else \
		echo "🏓 Pinging VM at $$IP"; \
		ping -c 4 $$IP; \
	fi

vm-info: ## Show VM configuration details
	sudo virsh dominfo terraform-vm

vm-xml: ## Show VM XML configuration
	sudo virsh dumpxml terraform-vm

test: ## Test VM
	./test_vm.sh