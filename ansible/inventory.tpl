[vm]
vm-host ansible_host=${vm_ip} ansible_user=${ansible_user} ansible_ssh_private_key_file=~/.ssh/id_rsa

[vm:vars]
ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
ansible_python_interpreter=/usr/bin/python3