


# API Driven - Contrôle d'une instance EC2 via API Gateway et Lambda

## Objectif du TP

L'objectif de cet atelier est de mettre en place une architecture **API-driven** permettant de piloter une ressource cloud à partir d'une simple requête HTTP.

Dans ce projet, une requête HTTP envoyée à une API Gateway déclenche une fonction Lambda. Cette Lambda agit ensuite sur une instance EC2 simulée dans LocalStack afin de :

- consulter son état ;
- l'arrêter ;
- la redémarrer.

L'ensemble de l'environnement AWS est simulé localement grâce à **LocalStack**.

---

## Schéma global de l'architecture

```text
Utilisateur
   |
   | Requête HTTP : /status, /stop ou /start
   v
API Gateway
   |
   | Déclenchement de la route demandée
   v
Lambda Python
   |
   | Appel AWS SDK boto3 vers EC2
   v
Instance EC2 simulée dans LocalStack
```

Le scénario attendu est donc :

```text
GET /status  -> affiche l'état de l'instance EC2
GET /stop    -> arrête l'instance EC2
GET /start   -> démarre l'instance EC2
```

---

## Services utilisés

Ce TP utilise les services suivants :

| Service | Rôle dans le projet |
|---|---|
| LocalStack | Simule un environnement AWS local |
| EC2 | Ressource simulée à contrôler |
| Lambda | Fonction Python qui reçoit l'action à exécuter |
| API Gateway | Point d'entrée HTTP exposant les routes `/status`, `/stop`, `/start` |
| IAM | Rôle utilisé par Lambda |
| boto3 | SDK Python utilisé pour interagir avec EC2 |

---

## Structure du dépôt

```text
.
├── lambda_function.py
├── scripts/
│   ├── deploy.sh
│   └── test_api.sh
├── Makefile
├── README.md
└── .gitignore
```

### Détail des fichiers

| Fichier | Description |
|---|---|
| `lambda_function.py` | Code Python de la Lambda |
| `scripts/deploy.sh` | Script de déploiement automatique de l'architecture |
| `scripts/test_api.sh` | Script de test automatique du scénario |
| `Makefile` | Raccourcis pour installer, démarrer, déployer et tester |
| `.gitignore` | Exclut les fichiers temporaires et l'environnement virtuel |

---

## Fonctionnement détaillé

### 1. Création de l'instance EC2

Le script de déploiement crée une instance EC2 simulée avec LocalStack.

Cette instance n'est pas une vraie machine AWS. Elle est simulée localement pour le TP.

Exemple d'état attendu après création :

```text
Instance EC2 : running
```

---

### 2. Création de la Lambda

La Lambda est écrite en Python.

Elle récupère l'action demandée depuis l'URL :

```text
/status
/stop
/start
```

Puis elle exécute l'action correspondante :

| Action | Méthode EC2 appelée |
|---|---|
| `status` | `describe_instances` |
| `stop` | `stop_instances` |
| `start` | `start_instances` |

---

### 3. Création de l'API Gateway

L'API Gateway expose une route dynamique :

```text
/{action}
```

Cela permet d'utiliser une seule logique pour plusieurs routes :

```text
/status
/stop
/start
```

Chaque requête HTTP est transmise à la Lambda.

---

## Prérequis

Pour exécuter ce projet, il faut :

- un environnement Linux ou GitHub Codespaces ;
- Docker disponible ;
- Python 3 ;
- un compte LocalStack si la version utilisée demande un token ;
- LocalStack ;
- AWS CLI ;
- awscli-local.

Depuis les versions récentes de LocalStack, un token d'authentification peut être demandé.

Le token LocalStack ne doit jamais être ajouté dans le dépôt Git.

---

## Installation

### 1. Cloner le dépôt

```bash
git clone https://github.com/OceanAquatique/API_Driven.git
```

Cette commande récupère le dépôt GitHub en local.

```bash
cd API_Driven
```

Cette commande place le terminal dans le dossier du projet.

---

### 2. Initialiser l'environnement

```bash
make init
```

Cette commande crée un environnement virtuel Python nommé `rep_localstack` et installe les dépendances nécessaires : LocalStack, AWS CLI et awscli-local.

---

### 3. Configurer le token LocalStack

```bash
make auth TOKEN="VOTRE_TOKEN_LOCALSTACK"
```

Cette commande enregistre le token LocalStack nécessaire pour démarrer LocalStack.

Le token doit être remplacé par un vrai token personnel LocalStack.

Il ne faut pas écrire ce token dans le README, dans un script ou dans un commit Git.

---

### 4. Démarrer LocalStack

```bash
make start
```

Cette commande démarre LocalStack en arrière-plan via Docker.

---

### 5. Vérifier l'état de LocalStack

```bash
make status
```

Cette commande vérifie que LocalStack fonctionne et que les services nécessaires sont disponibles.

Un retour attendu contient notamment :

```text
apigateway  running
ec2         running
iam         running
lambda      running
```

---

## Déploiement de l'architecture

Pour déployer automatiquement toute l'architecture :

```bash
make deploy
```

Cette commande exécute le script `scripts/deploy.sh`.

Le script réalise automatiquement les étapes suivantes :

```text
1. Création d'une instance EC2 simulée
2. Création du fichier ZIP de la Lambda
3. Création du rôle IAM
4. Création ou mise à jour de la Lambda
5. Création de l'API Gateway
6. Création de la route dynamique /{action}
7. Intégration de l'API Gateway avec la Lambda
8. Déploiement de l'API sur le stage dev
9. Sauvegarde des informations utiles dans .localstack-tp.env
```

Exemple de sortie attendue :

```text
Déploiement terminé.
Instance EC2 : i-xxxxxxxxxxxxxxxxx
API Gateway : http://localhost:4566/_aws/execute-api/xxxxxxxxxx/dev
Routes disponibles : /status, /stop, /start
```

---

## Tests automatiques

Pour tester le scénario complet :

```bash
make test
```

Cette commande exécute le script `scripts/test_api.sh`.

Le script teste automatiquement :

```text
1. La route /status
2. La route /stop
3. La vérification de l'état stopped
4. La route /start
5. La vérification de l'état running
```

Exemple de résultat attendu :

```text
Test /status
{"action": "status", "instance_id": "i-xxxxxxxxxxxxxxxxx", "message": "Instance i-xxxxxxxxxxxxxxxxx état actuel : running."}

Test /stop
{"action": "stop", "instance_id": "i-xxxxxxxxxxxxxxxxx", "message": "Instance i-xxxxxxxxxxxxxxxxx arrêtée."}

État EC2 après /stop
[
    "stopped"
]

Test /start
{"action": "start", "instance_id": "i-xxxxxxxxxxxxxxxxx", "message": "Instance i-xxxxxxxxxxxxxxxxx démarrée."}

État EC2 après /start
[
    "running"
]
```

---

## Tests manuels avec curl

Après le déploiement, le script affiche une URL de base de ce type :

```text
http://localhost:4566/_aws/execute-api/<API_ID>/dev
```

Il est possible de tester manuellement les routes.

### Vérifier l'état de l'instance

```bash
curl http://localhost:4566/_aws/execute-api/<API_ID>/dev/status
```

Cette commande appelle la route `/status` et retourne l'état actuel de l'instance EC2.

---

### Arrêter l'instance

```bash
curl http://localhost:4566/_aws/execute-api/<API_ID>/dev/stop
```

Cette commande appelle la route `/stop` et arrête l'instance EC2 simulée.

---

### Démarrer l'instance

```bash
curl http://localhost:4566/_aws/execute-api/<API_ID>/dev/start
```

Cette commande appelle la route `/start` et redémarre l'instance EC2 simulée.

---

## Code de la Lambda

La Lambda récupère l'action depuis les paramètres d'URL.

Extrait logique :

```python
action = path_params.get("action") or query_params.get("action")
```

Si l'action vaut `start`, la Lambda démarre l'instance :

```python
ec2.start_instances(InstanceIds=[INSTANCE_ID])
```

Si l'action vaut `stop`, la Lambda arrête l'instance :

```python
ec2.stop_instances(InstanceIds=[INSTANCE_ID])
```

Si l'action vaut `status`, la Lambda récupère l'état actuel :

```python
ec2.describe_instances(InstanceIds=[INSTANCE_ID])
```

Si l'action est invalide, la Lambda retourne une erreur HTTP 400.

---

## Automatisation mise en place

Le projet est automatisé avec :

```text
- un script de déploiement : scripts/deploy.sh
- un script de test : scripts/test_api.sh
- un Makefile
```

Le Makefile permet de simplifier l'utilisation du projet.

| Commande | Rôle |
|---|---|
| `make init` | Installe l'environnement local |
| `make auth TOKEN="..."` | Configure le token LocalStack |
| `make start` | Démarre LocalStack |
| `make status` | Vérifie l'état des services |
| `make deploy` | Déploie l'architecture complète |
| `make test` | Teste le scénario complet |
| `make stop` | Arrête LocalStack |
| `make clean` | Supprime les fichiers temporaires |

---

## Nettoyage

Pour supprimer les fichiers temporaires générés localement :

```bash
make clean
```

Cette commande supprime les fichiers temporaires comme `function.zip`, `response.json`, `trust-policy.json` et `.localstack-tp.env`.

Pour arrêter LocalStack :

```bash
make stop
```

Cette commande arrête LocalStack.

---

## Remarque sur la persistance LocalStack

Dans cet atelier, LocalStack fonctionne avec la persistance désactivée.

Cela signifie que les ressources simulées peuvent disparaître lorsque LocalStack est arrêté.

Exemple :

```text
Si LocalStack est arrêté, l'instance EC2 simulée peut disparaître.
```

Ce comportement est normal.

Le script `deploy.sh` permet donc de recréer automatiquement toute l'architecture lorsque nécessaire.

---

## Résultat obtenu

Le scénario final fonctionne ainsi :

```text
1. Une instance EC2 simulée est créée.
2. Une Lambda Python est déployée.
3. Une API Gateway expose les routes /status, /stop et /start.
4. Une requête HTTP déclenche la Lambda.
5. La Lambda contrôle l'état de l'instance EC2.
```

Résultat vérifié :

```text
/status -> retourne l'état courant de l'instance
/stop   -> passe l'instance en stopped
/start  -> repasse l'instance en running
```

---

## Correspondance avec le barème

### Repository exécutable sans erreur majeure

Le projet peut être exécuté avec :

```bash
make init
make start
make deploy
make test
```

Ces commandes permettent d'installer, lancer, déployer et tester le projet.

---

### Fonctionnement conforme au scénario annoncé

Le scénario API Gateway vers Lambda vers EC2 est fonctionnel.

Les routes `/status`, `/stop` et `/start` agissent bien sur l'instance EC2 simulée.

---

### Degré d'automatisation

Le projet contient :

```text
- un Makefile ;
- un script de déploiement ;
- un script de test.
```

L'ensemble du scénario peut être rejoué automatiquement.

---

### Qualité du README

Le README décrit :

```text
- l'objectif du projet ;
- l'architecture ;
- les prérequis ;
- l'installation ;
- le déploiement ;
- les tests ;
- le fonctionnement de la Lambda ;
- les limites liées à LocalStack.
```

---

### Processus de travail

Le projet a été construit progressivement avec des commits dédiés :

```text
- implémentation du scénario ;
- ajout de l'automatisation ;
- documentation du projet.
```

---

## Conclusion

Ce TP démontre une architecture cloud pilotée par API.

L'utilisateur envoie une requête HTTP à API Gateway. API Gateway déclenche une Lambda. La Lambda utilise boto3 pour contrôler une instance EC2 simulée dans LocalStack.

Le projet permet donc de comprendre le principe d'une infrastructure pilotée par API et automatisée par scripts.