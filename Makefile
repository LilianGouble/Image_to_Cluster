# Variables
CLUSTER_NAME=lab
IMAGE_NAME=custom-nginx:latest
APP_NAME=my-custom-app

# Phony targets
.PHONY: help all install create-cluster build import deploy expose clean

help:
	@echo "Usage dans Codespaces :"
	@echo "  make all      : Installe tout, crée le cluster, build et déploie"
	@echo "  make clean    : Supprime le cluster et les fichiers temporaires"

# 1. Orchestration complète
all: install create-cluster build import deploy expose
	@echo "🚀 Déploiement terminé avec succès !"

# 2. Installation des outils (CORRIGÉ - Tolérance aux erreurs apt)
install:
	@echo "--- 🛠️ Vérification / Installation des prérequis ---"
	@if ! command -v packer > /dev/null; then \
		echo "Packer non trouvé. Installation..."; \
		curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -; \
		sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $$(lsb_release -cs) main" -y; \
		echo "Mise à jour des dépôts (ignorer les erreurs tierces)..."; \
		sudo apt-get update || true; \
		sudo apt-get install packer -y; \
	else \
		echo "✅ Packer est déjà installé."; \
	fi
	@echo "Installation des librairies Python..."
	@pip install ansible kubernetes --quiet
	@ansible-galaxy collection install kubernetes.core > /dev/null

# 3. Gestion du Cluster K3d
create-cluster:
	@echo "--- ☸️ Vérification du cluster K3d ---"
	@if k3d cluster list | grep -q $(CLUSTER_NAME); then \
		echo "✅ Le cluster '$(CLUSTER_NAME)' existe déjà."; \
	else \
		echo "Création du cluster '$(CLUSTER_NAME)'..."; \
		k3d cluster create $(CLUSTER_NAME) --servers 1 --agents 2; \
	fi

# 4. Build de l'image
build:
	@echo "--- 🏗️ Construction de l'image Docker avec Packer ---"
	packer init packer.pkr.hcl
	packer build packer.pkr.hcl

# 5. Import dans K3d
import:
	@echo "--- 📦 Import de l'image dans le cluster ---"
	k3d image import $(IMAGE_NAME) -c $(CLUSTER_NAME)

# 6. Déploiement Ansible
deploy:
	@echo "--- 🚀 Déploiement via Ansible ---"
	ansible-playbook -i inventory.ini playbook.yml

# 7. Accès
expose:
	@echo "--- 🌍 Exposition de l'application ---"
	@pkill -f "kubectl port-forward svc/$(APP_NAME)" || true
	@nohup kubectl port-forward svc/$(APP_NAME) 8081:80 > /dev/null 2>&1 &
	@echo "✅ Application accessible sur le port 8081 (Mettez-le en Public)."

clean:
	@echo "--- 🧹 Nettoyage ---"
	k3d cluster delete $(CLUSTER_NAME) || true
	docker rmi $(IMAGE_NAME) || true
	pkill -f "kubectl port-forward" || true