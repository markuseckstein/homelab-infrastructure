terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.91.0" 
    }
  }
}

provider "proxmox" {
  endpoint = "https://192.168.178.41:8006/"
  api_token = "root@pam!terraform=645a1af1-c3f2-400c-bc10-0abe53df9f3d" # Create this in Proxmox UI
  insecure = true # Set to false if you have valid SSL

  ssh {
    agent    = true
    username = "root" 
    # If not using an ssh-agent, uncomment the line below:
    private_key = file("~/.ssh/id_ed25519")
  }
}