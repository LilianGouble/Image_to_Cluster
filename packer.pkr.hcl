packer {
  required_plugins {
    docker = {
      version = ">= 0.0.7"
      source  = "github.com/hashicorp/docker"
    }
  }
}

source "docker" "nginx" {
  image  = "nginx:latest"
  commit = true
}

build {
  name = "k3d-packer"
  sources = [
    "source.docker.nginx"
  ]

  # Copie du fichier index.html local vers le conteneur
  provisioner "file" {
    source      = "index.html"
    destination = "/usr/share/nginx/html/index.html"
  }

  post-processors {
    post-processor "docker-tag" {
      repository = "custom-nginx"
      tags       = ["latest"]
    }
  }
}