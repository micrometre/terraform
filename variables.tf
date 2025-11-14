variable "vm_memory" {
  description = "Memory allocation for the VM in MB"
  type        = number
  default     = 2048
}

variable "vm_vcpu" {
  description = "Number of virtual CPUs for the VM"
  type        = number
  default     = 2
}

variable "vm_disk_size" {
  description = "Disk size for the VM in bytes"
  type        = number
  default     = 10737418240 # 10GB
}

variable "vm_name" {
  description = "Name of the virtual machine"
  type        = string
  default     = "terraform-vm"
}

variable "network_cidr" {
  description = "CIDR block for the VM network"
  type        = string
  default     = "192.168.100.0/24"
}

variable "base_image_url" {
  description = "URL of the base cloud image to use"
  type        = string
  default     = "https://cloud-images.ubuntu.com/releases/24.04/release/ubuntu-24.04-server-cloudimg-amd64.img"
}

variable "enable_vm_tests" {
  description = "Enable VM testing provisioner"
  type        = bool
  default     = true
}

variable "vm_static_ip" {
  description = "Static IP address for the VM"
  type        = string
  default     = "192.168.122.10"
}