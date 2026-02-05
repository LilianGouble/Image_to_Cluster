# 🚀 Atelier : From Image to Cluster
Bienvenue dans ce projet d'automatisation DevOps ! L'objectif est de déployer une application conteneurisée sur un cluster Kubernetes de manière entièrement automatisée au sein d'un environnement GitHub Codespaces.

## 🎯 Ce que fait ce projet
En une seule commande, ce projet va :
* Build : Construire une image Docker Nginx personnalisée avec Packer.
* Infrastructure : Monter un cluster Kubernetes léger (K3d) dans le Codespace.
* Deploy : Provisionner et déployer l'application sur le cluster via Ansible.
* Expose : Rendre l'application accessible via un tunnel sécurisé.

## 🏁 Guide de Démarrage (3 minutes chrono)
Suivez ces étapes simples pour voir le projet en action.

### Étape 1 : Fork & Codespace
1. Faites un Fork de ce dépôt (bouton en haut à droite) pour avoir votre propre copie.
2. Cliquez sur le bouton vert Code.
3. Allez dans l'onglet Codespaces.
4. Cliquez sur Create codespace on main.
5. Attendez quelques instants que l'environnement se charge...

### Étape 2 : Lancement de l'automatisation 🪄
Une fois le terminal ouvert, tapez simplement cette commande "magique" :  
```make all```

☕ Prenez une gorgée de café. Le script va automatiquement :
* Installer les outils manquants (Packer, K3d, Ansible).
* Créer le cluster.
* Construire l'image.
* Déployer l'application.

### Étape 3 : Accéder à votre site
Une fois que le terminal affiche ✅ Tunnel établi avec succès !, suivez cette procédure précise pour accéder au site :
1. Repérez l'onglet PORTS (situé en bas, à côté du TERMINAL).
2. Cherchez la ligne correspondant au port 8081.
3. Faites un Clic-droit sur la ligne du port.
4. Sélectionnez Port Visibility > Public.
5. Cliquez sur l'icône "Globe" 🌐 (Open in Browser) qui apparaît au survol de l'adresse locale.

#### 🎉 Bravo ! Vous devriez voir la page "Mission Accomplie".

### 🛠️ Sous le capot

Pour les curieux, voici comment les outils interagissent :

|Outils|Role dans le projet|
|---    |:-:    |
|Make|Le chef d'orchestre. Il coordonne l'exécution séquentielle de tous les scripts.|
|Packer|Construit l'image Docker custom-nginx en y intégrant notre fichier index.html.|
|K3d|Crée un cluster Kubernetes complet à l'intérieur de conteneurs Docker (Docker-in-Docker).|
|Ansible|Communique avec l'API Kubernetes pour créer le Deployment et le Service.|


### 🧹 Nettoyage

Une fois l'atelier terminé, pour détruire le cluster et libérer les ressources :  

```make clean```
