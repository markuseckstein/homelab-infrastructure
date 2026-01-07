resource "proxmox_virtual_environment_file" "cloud_config" {
  content_type = "snippets"
  datastore_id = "local"
  node_name    = "pve"

  source_raw {
    data = <<EOF
#cloud-config
packages:
  - qemu-guest-agent
  - docker.io
  - docker-compose
runcmd:
  - systemctl enable --now docker
  - docker volume create portainer_data
  - docker run -d -p 8000:8000 -p 9443:9443 --name portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce:lts
EOF
    file_name = "docker-setup.yaml"
  }
}


resource "proxmox_virtual_environment_download_file" "ubuntu_cloud_image" {
  content_type = "iso"
  datastore_id = "local"
  node_name    = "pve"
  url          = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
}

resource "proxmox_virtual_environment_vm" "docker_vm" {
  name      = "ubuntu-docker"
  node_name = "pve"
  vm_id     = 502

  cpu { cores = 4 }
  memory { dedicated = 13096 }

  initialization {
    user_data_file_id = proxmox_virtual_environment_file.cloud_config.id
    ip_config {
      ipv4 {
        address = "192.168.178.10/24"
        gateway = "192.168.178.1"
      }
    }
  }

  network_device { bridge = "vmbr0" }

  disk {
    datastore_id = "local-lvm"
    file_id      = proxmox_virtual_environment_download_file.ubuntu_cloud_image.id
    size         = 82
    interface    = "virtio0"
  }
}