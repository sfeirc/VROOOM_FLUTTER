# VROOOM - Tableau de Bord d'Administration pour Location de Voitures de Luxe

Un tableau de bord d'administration Flutter élégant pour le service de location de voitures de luxe VROOOM.


## Fonctionnalités

- 🚗 Gestion complète des véhicules
- 👥 Système de gestion des utilisateurs
- 📊 Gestion et suivi des réservations
- 🎨 Interface moderne avec animations élégantes
- 🔒 Authentification sécurisée
- 🌐 Backend Node.js avec base de données MySQL

## Stack Technique

### Frontend (Flutter)
- Flutter & Dart
- Google Fonts
- Flutter Animate (pour les animations)
- Provider (pour la gestion d'état)
- HTTP package (pour la communication API)

### Backend (Node.js)
- Express.js
- Base de données MySQL
- Authentification par session
- Architecture API RESTful
- Support CORS

## Pour Commencer

### Prérequis
- Flutter 3.0+
- Node.js 14+
- MySQL 8.0+
- Visual Studio 2019 ou plus récent (pour Windows)
- Windows 10 ou plus récent
- Git pour Windows

### Installation

1. Clonez le dépôt :
```bash
git clone https://github.com/sfeirc/VROOOM_FLUTTER.git
cd VROOOM_FLUTTER
```

2. Installez les dépendances Flutter :
```bash
flutter pub get
```

3. Configurez le serveur :
```bash
cd server
npm install
```

4. Créez une base de données MySQL en utilisant le schéma fourni dans `server/schema.sql`

5. Créez un fichier `.env` dans le répertoire du serveur en copiant le fichier `.env.example` :
```bash
copy .env.example .env
```

6. Modifiez le fichier `.env` avec vos informations :
```env
DB_HOST=172.16.199.254
DB_USER=votre_utilisateur
DB_PASSWORD=votre_mot_de_passe
DB_NAME=vroom_prestige
SESSION_SECRET=votre_clé_secrète
PORT=3000
```

### Lancement de l'Application

#### Version Serveur (Backend)
1. Démarrez le serveur backend :
```bash
cd server
node server.js
```

#### Version Windows (Desktop)
1. Assurez-vous que le mode Windows est activé :
```bash
flutter config --enable-windows-desktop
```

2. Vérifiez que Windows est disponible comme plateforme cible :
```bash
flutter devices
```

3. Compilez et lancez l'application Windows :
```bash
flutter run -d windows
```

4. Pour créer un exécutable Windows :
```bash
flutter build windows
```
L'exécutable se trouvera dans `build/windows/runner/Release/`

### Configuration Windows

Pour une installation sur Windows :

1. Installez les prérequis :
   - Visual Studio 2019 ou plus récent avec :
     - "Développement Desktop en C++"
     - Windows 10 SDK
   - Flutter SDK
   - Git pour Windows

2. Configuration du pare-feu Windows :
   - Autorisez le port 3000 pour le serveur backend
   - Autorisez l'application dans le pare-feu Windows

3. Installation en tant qu'application Windows :
   - Copiez le dossier Release complet
   - Créez un raccourci sur le bureau
   - L'application peut être installée via l'installateur dans `build/windows/runner/Release/`

## Structure du Projet

- `/lib` - Code de l'application Flutter
  - `/providers` - Gestion d'état
  - `/screens` - Écrans de l'interface
  - `/services` - Couche de services API
  - `/models` - Modèles de données
- `/server` - Backend Node.js
  - `server.js` - Serveur Express principal
  - `/routes` - Points d'entrée API
  - `/models` - Modèles de base de données
- `/windows` - Configuration spécifique à Windows
  - `/runner` - Fichiers de configuration Windows



## Sécurité

- Les mots de passe sont hashés avec bcrypt
- Authentification par session sécurisée
- Protection CORS configurée
- Variables d'environnement pour les données sensibles
- Configuration du pare-feu Windows pour la sécurité réseau

## Dépannage Windows

Si vous rencontrez des problèmes :

1. Erreurs de connexion au serveur :
   - Vérifiez que le serveur backend est en cours d'exécution
   - Vérifiez les règles du pare-feu Windows
   - Assurez-vous que le port 3000 est disponible

2. Erreurs de compilation :
   - Exécutez `flutter clean`
   - Supprimez le dossier build
   - Réinstallez les dépendances avec `flutter pub get`

3. Erreurs d'exécution :
   - Vérifiez les logs dans `%APPDATA%\vrooom_lourd\logs`
   - Assurez-vous que tous les services requis sont en cours d'exécution