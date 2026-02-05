# Variables
CLUSTER_NAME=lab
IMAGE_NAME=custom-nginx:latest
APP_NAME=my-custom-app

# Phony targets (déclare que ce ne sont pas des fichiers physiques)
.PHONY: help all install create-cluster build import deploy expose clean

# Aide par défaut
help:
	@echo "Usage dans Codespaces :"
	@echo "  make all      : Installe tout, crée le cluster, build et déploie (La commande magique)"
	@echo "  make clean    : Supprime le cluster et les fichiers temporaires"
	@echo "  make install  : Installe uniquement les dépendances (Packer, Ansible)"

# 1. Commande principale (Orchestration complète)
all: install create-cluster build import deploy expose
	@echo "🚀 Déploiement terminé avec succès ! Vérifiez l'onglet PORTS."

# 2. Installation des outils (Si nécessaire)
install:
	@echo "--- 🛠️ Vérification / Installation des prérequis ---"
	@# Installation de Packer si absent
	@if ! command -v packer > /dev/null; then \
		echo "Packer non trouvé. Installation..."; \
		curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -; \
		sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"; \
		sudo apt-get update && sudo apt-get install packer -y; \
	else \
		echo "✅ Packer est déjà installé."; \
	fi
	@# Installation des libs Python pour Ansible
	@echo "Installation des librairies Python pour Kubernetes..."
	@pip install ansible kubernetes --quiet
	@# Installation de la collection Ansible Kubernetes
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

# 4. Build de l'image (Packer)
build:
	@echo "--- 🏗️ Construction de l'image Docker avec Packer ---"
	packer init packer.pkr.hcl
	packer build packer.pkr.hcl

# 5. Import de l'image dans K3d (Crucial pour que K3d voie l'image locale)
import:
	@echo "--- 📦 Import de l'image dans le cluster ---"
	k3d image import $(IMAGE_NAME) -c $(CLUSTER_NAME)

# 6. Déploiement (Ansible)
deploy:
	@echo "--- 🚀 Déploiement via Ansible ---"
	ansible-playbook -i inventory.ini playbook.yml

# 7. Accès (Port Forwarding)
expose:
	@echo "--- 🌍 Exposition de l'application ---"
	@echo "Mise en place du port-forwarding sur le port 8081..."
	@# On tue l'ancien port-forward s'il existe pour éviter les conflits
	@pkill -f "kubectl port-forward svc/$(APP_NAME)" || true
	@# Lancement en arrière-plan
	@nohup kubectl port-forward svc/$(APP_NAME) 8081:80 > /dev/null 2>&1 &
	@echo "✅ L'application est accessible !"
	@echo "👉 Ouvrez l'onglet 'PORTS', cherchez '8081', clic-droit > 'Port Visibility: Public' > Ouvrir dans le navigateur."

# Nettoyage complet
clean:
	@echo "--- 🧹 Nettoyage ---"
	k3d cluster delete $(CLUSTER_NAME) || true
	docker rmi $(IMAGE_NAME) || true
	pkill -f "kubectl port-forward" || true