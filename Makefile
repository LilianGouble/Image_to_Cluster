# Variables
CLUSTER_NAME=lab
IMAGE_NAME=custom-nginx:latest
APP_NAME=app-lilial-docker

# Phony targets
.PHONY: help all install create-cluster build import deploy expose clean

help:
	@echo "Usage dans Codespaces :"
	@echo "  make all      : Installe tout, crée le cluster, build et déploie"
	@echo "  make clean    : Supprime le cluster et les fichiers temporaires"

# 1. Orchestration complète
all: install create-cluster build import deploy expose
	@echo "🚀 Déploiement terminé avec succès !"

# 2. Installation des outils
install:
	@echo "--- 🛠️ Vérification / Installation des prérequis ---"
	@# Installation de Packer si absent
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
	@# Installation de K3d si absent
	@if ! command -v k3d > /dev/null; then \
		echo "K3d non trouvé. Installation..."; \
		curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash; \
	else \
		echo "✅ K3d est déjà installé."; \
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
	@# On passe le nom de l'app en paramètre pour être sûr
	ansible-playbook -i inventory.ini playbook.yml -e "app_name=$(APP_NAME) image_name=$(IMAGE_NAME)"

# 7. Accès (Version Codespaces Safe)
expose:
	@echo "--- 🌍 Exposition de l'application ---"
	@echo "⏳ Attente que le déploiement soit prêt (timeout 60s)..."
	@kubectl wait --for=condition=available --timeout=60s deployment/$(APP_NAME)
	@echo "Mise en place du port-forwarding sur le port 8081..."
	@# Nettoyage propre basé sur le PID
	@if [ -f port-forward.pid ]; then \
		echo "Arrêt de l'ancien processus..."; \
		kill $$(cat port-forward.pid) 2>/dev/null || true; \
		rm port-forward.pid; \
	fi
	@# On écoute sur 0.0.0.0 pour être sûr que Codespaces le capte
	@nohup kubectl port-forward svc/$(APP_NAME) --address 0.0.0.0 8081:80 > port-forward.log 2>&1 < /dev/null & echo $$! > port-forward.pid
	@echo "⏳ Vérification de la stabilité du tunnel (3s)..."
	@sleep 3
	@if ps -p $$(cat port-forward.pid) > /dev/null; then \
		echo "✅ Tunnel établi avec succès !"; \
		echo "👉 Vérifiez l'onglet PORTS : Le port 8081 doit être actif."; \
	else \
		echo "❌ Le tunnel a échoué. Voici le log d'erreur :"; \
		cat port-forward.log; \
		exit 1; \
	fi

clean:
	@echo "--- 🧹 Nettoyage ---"
	k3d cluster delete $(CLUSTER_NAME) || true
	docker rmi $(IMAGE_NAME) || true
	@if [ -f port-forward.pid ]; then kill $$(cat port-forward.pid) 2>/dev/null || true; rm port-forward.pid; fi
	rm -f port-forward.log