// Importation des modules nécessairese
// Import d'express (serveur web)
const express = require('express');
// Import de mysql2 (base de données)
const mysql = require('mysql2');
// Import de cors (gestion des requêtes cross-origin)
const cors = require('cors');
// Import de bcryptjs (cryptage des mots de passe)
const bcrypt = require('bcryptjs');
// Import d'express-session (gestion des sessions)
const session = require('express-session');
// Import d'express-mysql-session (stockage des sessions dans MySQL)
const MySQLStore = require('express-mysql-session')(session);
// Import de path (gestion des chemins de fichiers)
const path = require('path');
// Import de fs (système de fichiers)
const fs = require('fs');
// Import de undici fetch (requêtes HTTP)
const { fetch } = require('undici');
// Import de dotenv (variables d'environnement)
require('dotenv').config();

// Configuration de la base de données
const dbConfig = {
    host: '172.16.199.254',
    port: 3306,
    user: 'root',
    password: 'clovis',
    database: 'vroom_prestige'
};

// Création de l'application Express
const app = express();

// Définition du chemin des assets (ressources statiques)
const assetsPath = path.join(__dirname, '../assets');
console.log(`Serving static files from: ${assetsPath}`);

// Vérification de l'existence du répertoire des assets
if (fs.existsSync(assetsPath)) {
    console.log(`Le répertoire des assets existe à: ${assetsPath}`);
} else {
    console.log(`ATTENTION: Le répertoire des assets n'existe pas à: ${assetsPath}`);
    // Création des répertoires nécessaires
    try {
        fs.mkdirSync(path.join(assetsPath, 'images'), { recursive: true });
        fs.mkdirSync(path.join(assetsPath, 'logos'), { recursive: true });
        console.log('Répertoires des assets créés');
    } catch (err) {
        console.error('Erreur lors de la création des répertoires:', err);
    }
}

// Options de mise en cache pour les fichiers statiques
const staticOptions = {
    etag: true, // Active l'utilisation des ETags
    lastModified: true, // Active l'utilisation des dates de dernière modification
    setHeaders: (res, path) => {
        // Configuration des en-têtes de cache pour les images
        if (path.endsWith('.jpg') || path.endsWith('.jpeg') || 
            path.endsWith('.png') || path.endsWith('.gif') ||
            path.endsWith('.svg')) {
            res.setHeader('Cache-Control', 'public, max-age=86400'); // Cache de 24 heures
            res.setHeader('Access-Control-Allow-Origin', '*'); // Autorise toutes les origines
        }
    }
};

// Configuration des middlewares pour servir les fichiers statiques
app.use('/assets', express.static(assetsPath, staticOptions));
// Sert aussi les fichiers statiques depuis la racine pour la compatibilité
app.use(express.static(path.join(__dirname, '..'), staticOptions));

// Point d'accès spécial pour récupérer les images locales avec le bon type de contenu
app.get('/assets/images/:filename', (req, res) => {
  const filename = req.params.filename;
  const imagePath = path.join(__dirname, '..', 'assets', 'images', filename);
  
  console.log(`Récupération du fichier image: ${imagePath}`);
  
  fs.stat(imagePath, (err, stats) => {
    if (err || !stats.isFile()) {
      console.log(`Image non trouvée: ${imagePath}`);
      // Génération d'une image placeholder avec le nom de la voiture
      const svg = `
        <svg xmlns="http://www.w3.org/2000/svg" width="200" height="150" viewBox="0 0 200 150">
          <rect width="200" height="150" fill="#${Math.floor(Math.random()*16777215).toString(16)}" />
          <text x="50%" y="50%" font-family="Arial" font-size="16" fill="white" text-anchor="middle">${filename}</text>
        </svg>
      `;
      
      res.setHeader('Content-Type', 'image/svg+xml');
      res.setHeader('Cache-Control', 'public, max-age=3600');
      return res.send(svg);
    }
    
    // Définition du type de contenu en fonction de l'extension
    const ext = path.extname(filename).toLowerCase();
    switch(ext) {
      case '.jpg':
      case '.jpeg':
        res.setHeader('Content-Type', 'image/jpeg');
        break;
      case '.png':
        res.setHeader('Content-Type', 'image/png');
        break;
      case '.gif':
        res.setHeader('Content-Type', 'image/gif');
        break;
      case '.svg':
        res.setHeader('Content-Type', 'image/svg+xml');
        break;
    }
    
    // Configuration des en-têtes de cache
    res.setHeader('Cache-Control', 'public, max-age=86400');
    res.setHeader('Access-Control-Allow-Origin', '*');
    
    // Envoi du fichier
    res.sendFile(imagePath);
  });
});

// Point d'accès spécial pour servir des images placeholder
app.get('/api/assets/images/:filename', (req, res) => {
  const filename = req.params.filename;
  console.log(`Demande d'image placeholder reçue: ${filename}`);
  
  // Génération d'une image placeholder (rectangle coloré avec texte)
  const svg = `
    <svg xmlns="http://www.w3.org/2000/svg" width="200" height="150" viewBox="0 0 200 150">
      <rect width="200" height="150" fill="#${Math.floor(Math.random()*16777215).toString(16)}" />
      <text x="50%" y="50%" font-family="Arial" font-size="16" fill="white" text-anchor="middle">${filename}</text>
    </svg>
  `;
  
  // Configuration des en-têtes de cache appropriés
  res.setHeader('Cache-Control', 'public, max-age=86400'); // Cache de 24 heures
  res.setHeader('Content-Type', 'image/svg+xml');
  res.send(svg);
});

// Options de stockage des sessions utilisant la même configuration de base de données
const options = {
    ...dbConfig,
    clearExpired: true, // Nettoie les sessions expirées
    checkExpirationInterval: 900000, // Vérifie toutes les 15 minutes
    expiration: 86400000, // Expire après 24 heures
    createDatabaseTable: true, // Crée la table si elle n'existe pas
    schema: {
        tableName: 'sessions',
        columnNames: {
            session_id: 'session_id',
            expires: 'expires',
            data: 'data'
        }
    }
};

// Création du stockage des sessions
const sessionStore = new MySQLStore(options);

// Configuration des middlewares
app.use(cors({
    origin: '*', // Autorise toutes les origines
    credentials: true, // Important pour les sessions
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With', 'X-User-Id', 'Cache-Control', 'Accept']
}));
app.use(express.json());

// Configuration du middleware de session
app.use(session({
    key: 'connect.sid',
    secret: 'vroom_prestige',
    store: sessionStore,
    resave: false,
    saveUninitialized: true, // Modifié à true pour assurer la création de session
    cookie: {
        secure: false, // Désactivé pour le développement en HTTP
        httpOnly: true,
        maxAge: 24 * 60 * 60 * 1000, // 24 heures
        sameSite: 'lax' // Modifié à lax pour un meilleur fonctionnement en développement
    }
}));

// Connexion à la base de données avec la configuration
const db = mysql.createPool({
    ...dbConfig,
    waitForConnections: true,
    connectionLimit: 10,
    queueLimit: 0
});

// Middleware d'authentification avec meilleure gestion des erreurs
const authenticateSession = (req, res, next) => {
    console.log('Vérification de l\'authentification:', req.session);
    console.log('ID de session:', req.sessionID);
    console.log('En-têtes:', req.headers);
    
    // Permet l'authentification via l'en-tête X-User-Id (pour l'app Flutter)
    if (req.headers['x-user-id']) {
        console.log('Authentification via l\'en-tête X-User-Id:', req.headers['x-user-id']);
        // Définit l'utilisateur dans la session s'il n'existe pas
        if (!req.session.user) {
            // Pour cet ID utilisateur spécifique, attribue le rôle SUPERADMIN
            const userId = req.headers['x-user-id'];
            req.session.user = {
                id: userId,
                role: 'SUPERADMIN'  // Toujours défini comme SUPERADMIN pour l'instant
            };
            console.log('Session créée depuis l\'en-tête X-User-Id avec le rôle SUPERADMIN');
        }
        return next();
    }
    
    if (!req.session) {
        console.log('Aucun objet session trouvé');
        return res.status(401).json({ message: 'Aucune session trouvée' });
    }
    
    if (!req.session.user) {
        console.log('Aucun utilisateur dans la session');
        return res.status(401).json({ message: 'Session expirée ou identifiants invalides' });
    }
    
    console.log('Utilisateur authentifié:', req.session.user.email);
    next();
};

// ROUTES D'AUTHENTIFICATION

// Connexion
app.post('/api/auth/login', async (req, res) => {
    const { email, password } = req.body;
    console.log('Tentative de connexion pour:', email);

    try {
        // Authentification normale via base de données
        const [rows] = await db.promise().query(
            'SELECT * FROM Users WHERE Email = ?',
            [email]
        );

        if (rows.length === 0) {
            console.log('Utilisateur non trouvé:', email);
            return res.status(401).json({ message: 'Identifiants invalides' });
        }

        const user = rows[0];
        const isPasswordValid = await bcrypt.compare(password, user.MotDePasse);

        if (!isPasswordValid) {
            console.log('Mot de passe invalide pour:', email);
            return res.status(401).json({ message: 'Identifiants invalides' });
        }

        // Définition des données de session
        req.session.user = {
            id: user.IdUser,
            email: user.Email,
            role: user.Role,
            nom: user.Nom,
            prenom: user.Prenom,
            photo: user.PhotoProfil
        };
        
        // Sauvegarde explicite de la session
        req.session.save(err => {
            if (err) {
                console.error('Erreur de sauvegarde de session:', err);
                return res.status(500).json({ message: 'Erreur de session' });
            }
            
            console.log('Session sauvegardée avec succès, ID:', req.sessionID);
            console.log('Données utilisateur dans la session:', req.session.user);
            
            res.json({
                success: true,
                user: req.session.user
            });
        });
    } catch (error) {
        console.error('Erreur de connexion:', error);
        res.status(500).json({ message: 'Erreur serveur' });
    }
});

// Déconnexion
app.post('/api/auth/logout', (req, res) => {
    req.session.destroy((err) => {
        if (err) {
            return res.status(500).json({ message: 'Erreur lors de la déconnexion' });
        }
        res.clearCookie('connect.sid');
        res.json({ message: 'Déconnexion réussie' });
    });
});

// Vérification du statut d'authentification
app.get('/api/auth/check', (req, res) => {
    console.log('Demande de vérification d\'authentification reçue');
    console.log('Données de session:', req.session);
    console.log('ID de session:', req.sessionID);
    
    if (req.session && req.session.user) {
        console.log('Utilisateur authentifié:', req.session.user.email);
        res.json({
            isAuthenticated: true,
            user: req.session.user,
            sessionID: req.sessionID
        });
    } else {
        console.log('Utilisateur non authentifié');
        res.json({
            isAuthenticated: false,
            sessionID: req.sessionID
        });
    }
});

// Inscription
app.post('/api/auth/register', async (req, res) => {
    const { email, password, nom, prenom, tel, adresse } = req.body;

    try {
        const [existing] = await db.promise().query(
            'SELECT Email FROM Users WHERE Email = ?',
            [email]
        );

        if (existing.length > 0) {
            return res.status(400).json({ message: 'Cet email existe déjà' });
        }

        const userId = 'USR' + Date.now() + Math.random().toString(36).substr(2, 5);
        const hashedPassword = await bcrypt.hash(password, 10);

        await db.promise().query(
            `INSERT INTO Users (
                IdUser, Nom, Prenom, Email, Tel, Adresse, MotDePasse, 
                DateInscription, PhotoProfil, Role
            ) VALUES (?, ?, ?, ?, ?, ?, ?, NOW(), ?, 'CLIENT')`,
            [userId, nom, prenom, email, tel, adresse, hashedPassword, 
             'assets/images/default-profile.png']
        );

        res.status(201).json({ message: 'Inscription réussie' });
    } catch (error) {
        console.error('Erreur d\'inscription:', error);
        res.status(500).json({ message: 'Erreur serveur' });
    }
});

// ROUTES DES VOITURES

// Récupération de toutes les voitures
app.get('/api/cars', async (req, res) => {
    try {
        // Récupération des paramètres de filtrage depuis la requête
        const { brand, type, search } = req.query;
        
        // Construction de la requête de base avec les jointures
        let query = `
            SELECT v.*, m.NomMarque, t.NomType
            FROM Voiture v
            JOIN MarqueVoiture m ON v.IdMarque = m.IdMarque
            JOIN TypeVehicule t ON v.IdType = t.IdType
            WHERE 1=1
        `;
        
        // Ajout des conditions de filtrage
        const params = [];
        if (brand) {
            query += ` AND m.NomMarque = ?`;
            params.push(brand);
        }
        if (type) {
            query += ` AND t.NomType = ?`;
            params.push(type);
        }
        if (search) {
            query += ` AND (v.Modele LIKE ? OR m.NomMarque LIKE ?)`;
            params.push(`%${search}%`);
            params.push(`%${search}%`);
        }
        
        console.log('Exécution de la requête voitures avec filtres:', { brand, type, search });
        console.log('Requête SQL:', query);
        console.log('Paramètres SQL:', params);
        
        // Exécution de la requête avec les paramètres
        const [rows] = await db.promise().query(query, params);
        console.log(`${rows.length} voitures trouvées correspondant aux filtres`);
        res.json(rows);
    } catch (error) {
        console.error('Erreur lors de la récupération des voitures:', error);
        res.status(500).json({ message: 'Erreur serveur', error: error.message });
    }
});

// Récupération de toutes les marques
app.get('/api/cars/brands', async (req, res) => {
    try {
        console.log('Récupération des marques depuis la base de données...');
        const [rows] = await db.promise().query('SELECT * FROM MarqueVoiture');
        console.log(`${rows.length} marques trouvées`);
        res.json(rows);
    } catch (error) {
        console.error('Erreur lors de la récupération des marques:', error);
        res.status(500).json({ message: 'Erreur serveur', error: error.message });
    }
});

// Récupération de tous les types
app.get('/api/cars/types', async (req, res) => {
    try {
        console.log('Récupération des types de véhicules depuis la base de données...');
        const [rows] = await db.promise().query('SELECT * FROM TypeVehicule');
        console.log(`${rows.length} types de véhicules trouvés`);
        res.json(rows);
    } catch (error) {
        console.error('Erreur lors de la récupération des types:', error);
        res.status(500).json({ message: 'Erreur serveur', error: error.message });
    }
});

// Récupération des voitures en vedette
app.get('/api/cars/featured', async (req, res) => {
    try {
        const [rows] = await db.promise().query(`
            SELECT v.*, m.NomMarque, t.NomType
            FROM Voiture v
            JOIN MarqueVoiture m ON v.IdMarque = m.IdMarque
            JOIN TypeVehicule t ON v.IdType = t.IdType
            WHERE v.IdStatut = 'STAT001'
            LIMIT 6
        `);
        res.json(rows);
    } catch (error) {
        res.status(500).json({ message: 'Erreur serveur' });
    }
});

// ROUTES UTILISATEURS

// Récupération du profil utilisateur (nécessite authentification)
app.get('/api/users/profile', authenticateSession, async (req, res) => {
    try {
        const [rows] = await db.promise().query(
            'SELECT IdUser, Nom, Prenom, Email, Tel, Adresse, PhotoProfil, Role FROM Users WHERE IdUser = ?',
            [req.session.user.id]
        );

        if (rows.length === 0) {
            return res.status(404).json({ message: 'Utilisateur non trouvé' });
        }

        res.json(rows[0]);
    } catch (error) {
        console.error('Erreur lors de la récupération du profil:', error);
        res.status(500).json({ message: 'Erreur serveur', error: error.message });
    }
});

// Mise à jour du profil utilisateur (nécessite authentification)
app.put('/api/users/profile', authenticateSession, async (req, res) => {
    const { nom, prenom, tel, adresse } = req.body;

    try {
        await db.promise().query(
            'UPDATE Users SET Nom = ?, Prenom = ?, Tel = ?, Adresse = ? WHERE IdUser = ?',
            [nom, prenom, tel, adresse, req.session.user.id]
        );

        // Mise à jour des données de session
        req.session.user = {
            ...req.session.user,
            nom,
            prenom
        };

        res.json({ message: 'Profil mis à jour avec succès' });
    } catch (error) {
        res.status(500).json({ message: 'Erreur serveur' });
    }
});

// ROUTES ADMINISTRATEUR

// Récupération de tous les utilisateurs (admin uniquement)
app.get('/api/admin/users', authenticateSession, async (req, res) => {
    try {
        // Vérification si l'utilisateur est admin
        if (req.session.user.role !== 'ADMIN' && req.session.user.role !== 'SUPERADMIN') {
            return res.status(403).json({ message: 'Non autorisé' });
        }
        
        console.log('Récupération des utilisateurs depuis la base de données pour le tableau de bord admin');
        const [rows] = await db.promise().query(
            'SELECT IdUser, Nom, Prenom, Email, Tel, Role, DateInscription FROM Users'
        );
        
        console.log(`${rows.length} utilisateurs trouvés`);
        res.json(rows);
    } catch (error) {
        console.error('Erreur lors de la récupération des utilisateurs:', error);
        res.status(500).json({ message: 'Erreur serveur', error: error.message });
    }
});

// Récupération de toutes les réservations (admin uniquement)
app.get('/api/admin/reservations', authenticateSession, async (req, res) => {
    try {
        // Vérification si l'utilisateur est admin
        if (req.session.user.role !== 'ADMIN' && req.session.user.role !== 'SUPERADMIN') {
            return res.status(403).json({ message: 'Non autorisé' });
        }
        
        console.log('Récupération des réservations depuis la base de données pour le tableau de bord admin');
        const [rows] = await db.promise().query(`
            SELECT r.*, v.Modele, m.NomMarque, v.Photo
            FROM Reservation r
            JOIN Voiture v ON r.IdVoiture = v.IdVoiture
            JOIN MarqueVoiture m ON v.IdMarque = m.IdMarque
            ORDER BY r.DateReservation DESC
        `);
        
        console.log(`${rows.length} réservations trouvées`);
        res.json(rows);
    } catch (error) {
        console.error('Erreur lors de la récupération des réservations:', error);
        res.status(500).json({ message: 'Erreur serveur', error: error.message });
    }
});

// ROUTES DES RÉSERVATIONS

// Récupération des réservations utilisateur
app.get('/api/reservations/user', authenticateSession, async (req, res) => {
    try {
        const [rows] = await db.promise().query(`
            SELECT r.*, v.Modele, m.NomMarque, v.Photo
            FROM Reservation r
            JOIN Voiture v ON r.IdVoiture = v.IdVoiture
            JOIN MarqueVoiture m ON v.IdMarque = m.IdMarque
            WHERE r.IdUser = ?
            ORDER BY r.DateReservation DESC
        `, [req.session.user.id]);

        res.json(rows);
    } catch (error) {
        console.error('Erreur lors de la récupération des réservations:', error);
        res.status(500).json({ message: 'Erreur serveur', error: error.message });
    }
});

// Création d'une réservation
app.post('/api/reservations', authenticateSession, async (req, res) => {
    const { carId, startDate, endDate, amount } = req.body;
    const userId = req.session.user.id;

    try {
        // Vérification de la disponibilité
        const reservationId = 'RES' + Date.now() + Math.random().toString(36).substr(2, 5);

        await db.promise().query(`
            INSERT INTO Reservation (
                IdReservation, DateDebut, DateFin, MontantReservation,
                Statut, IdUser, IdVoiture, DateReservation
            ) VALUES (?, ?, ?, ?, 'En attente', ?, ?, NOW())
        `, [reservationId, startDate, endDate, amount, userId, carId]);

        res.status(201).json({
            success: true,
            reservationId,
            message: 'Réservation créée avec succès'
        });
    } catch (error) {
        console.error('Erreur lors de la création de la réservation:', error);
        res.status(500).json({ message: 'Erreur serveur', error: error.message });
    }
});

// Suppression d'une voiture (admin uniquement)
app.delete('/api/admin/cars/:id', authenticateSession, async (req, res) => {
    try {
        // Vérification si l'utilisateur est admin
        if (req.session.user.role !== 'ADMIN' && req.session.user.role !== 'SUPERADMIN') {
            return res.status(403).json({ message: 'Non autorisé' });
        }

        // Conversion de l'ID string en entier si nécessaire
        const carId = parseInt(req.params.id) || req.params.id;
        console.log(`Tentative de suppression de la voiture avec l'ID: ${carId}`);

        // Vérification si la voiture existe
        const [carCheck] = await db.promise().query(
            'SELECT IdVoiture FROM Voiture WHERE IdVoiture = ?',
            [carId]
        );

        if (carCheck.length === 0) {
            return res.status(404).json({ message: 'Voiture non trouvée' });
        }

        // Vérification si la voiture a des réservations
        const [reservationCheck] = await db.promise().query(
            'SELECT COUNT(*) as count FROM Reservation WHERE IdVoiture = ? AND Statut NOT IN ("Annulée", "Terminée")',
            [carId]
        );

        if (reservationCheck[0].count > 0) {
            return res.status(400).json({ 
                message: 'Impossible de supprimer une voiture avec des réservations actives. Annulez ou terminez toutes les réservations d\'abord.' 
            });
        }

        // Suppression de la voiture
        await db.promise().query(
            'DELETE FROM Voiture WHERE IdVoiture = ?',
            [carId]
        );

        console.log(`Voiture ${carId} supprimée avec succès`);
        res.json({ message: 'Voiture supprimée avec succès' });
    } catch (error) {
        console.error('Erreur lors de la suppression de la voiture:', error);
        res.status(500).json({ message: 'Erreur serveur', error: error.message });
    }
});

// Suppression d'un utilisateur (admin uniquement)
app.delete('/api/admin/users/:id', authenticateSession, async (req, res) => {
    try {
        // Vérification si l'utilisateur est admin
        if (req.session.user.role !== 'ADMIN' && req.session.user.role !== 'SUPERADMIN') {
            return res.status(403).json({ message: 'Non autorisé' });
        }

        const userId = req.params.id;
        console.log(`Tentative de suppression de l'utilisateur avec l'ID: ${userId}`);

        // Impossible de supprimer son propre compte
        if (userId === req.session.user.id) {
            return res.status(400).json({ message: 'Impossible de supprimer votre propre compte' });
        }

        // Vérification si l'utilisateur existe
        const [userCheck] = await db.promise().query(
            'SELECT IdUser FROM Users WHERE IdUser = ?',
            [userId]
        );

        if (userCheck.length === 0) {
            return res.status(404).json({ message: 'Utilisateur non trouvé' });
        }

        // Suppression de toutes les réservations associées
        await db.promise().query(
            'DELETE FROM Reservation WHERE IdUser = ?',
            [userId]
        );
        console.log(`Suppression de toutes les réservations pour l'utilisateur ${userId}`);

        // Suppression de l'utilisateur
        await db.promise().query(
            'DELETE FROM Users WHERE IdUser = ?',
            [userId]
        );

        console.log(`Utilisateur ${userId} supprimé avec succès`);
        res.json({ message: 'Utilisateur supprimé avec succès' });
    } catch (error) {
        console.error('Erreur lors de la suppression de l\'utilisateur:', error);
        res.status(500).json({ message: 'Erreur serveur', error: error.message });
    }
});

// Suppression d'une réservation (admin uniquement)
app.delete('/api/admin/reservations/:id', authenticateSession, async (req, res) => {
    try {
        // Vérification si l'utilisateur est admin
        if (req.session.user.role !== 'ADMIN' && req.session.user.role !== 'SUPERADMIN') {
            return res.status(403).json({ message: 'Non autorisé' });
        }

        const reservationId = req.params.id;
        console.log(`Tentative de suppression de la réservation avec l'ID: ${reservationId}`);

        // Vérification si la réservation existe
        const [reservationCheck] = await db.promise().query(
            'SELECT IdReservation FROM Reservation WHERE IdReservation = ?',
            [reservationId]
        );

        if (reservationCheck.length === 0) {
            return res.status(404).json({ message: 'Réservation non trouvée' });
        }

        // Suppression de la réservation
        await db.promise().query(
            'DELETE FROM Reservation WHERE IdReservation = ?',
            [reservationId]
        );

        console.log(`Reservation ${reservationId} deleted successfully`);
        res.json({ message: 'Reservation deleted successfully' });
    } catch (error) {
        console.error('Error deleting reservation:', error);
        res.status(500).json({ message: 'Server error', error: error.message });
    }
});

// Points de terminaison pour créer/mettre à jour une voiture (admin uniquement)
app.post('/api/admin/cars', authenticateSession, async (req, res) => {
    try {
        // Vérification si l'utilisateur est admin
        if (req.session.user.role !== 'ADMIN' && req.session.user.role !== 'SUPERADMIN') {
            return res.status(403).json({ message: 'Non autorisé' });
        }
        
        const { 
            NomMarque, Modele, Annee, PrixLocation, IdStatut, NbPorte, 
            BoiteVitesse, Couleur, Energie, Puissance, NbPlaces, Description, Photo
        } = req.body;
        
        console.log('Création d\'une nouvelle voiture:', req.body);
        
        // Récupération de l'ID de la marque à partir du nom
        const [brandRows] = await db.promise().query(
            'SELECT IdMarque FROM MarqueVoiture WHERE NomMarque = ?',
            [NomMarque]
        );
        
        if (brandRows.length === 0) {
            return res.status(404).json({ message: 'Marque non trouvée' });
        }
        
        const IdMarque = brandRows[0].IdMarque;
        
        // Laisser MySQL gérer l'auto-incrémentation pour IdVoiture
        console.log('Insertion de la voiture avec ID auto-incrémenté');
        
        // Gestion de l'URL de la photo
        const photoUrl = Photo && Photo.trim() !== '' 
            ? Photo 
            : 'assets/images/default-car.jpg';
        
        // Insertion de la voiture (en omettant le champ IdVoiture)
        const [result] = await db.promise().query(`
            INSERT INTO Voiture (
                Modele, NbPorte, BoiteVitesse, Annee, Couleur, 
                Photo, Energie, Puissance, PrixLocation, Description,
                NbPlaces, IdStatut, IdMarque, IdType
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        `, [
            Modele, NbPorte || 4, BoiteVitesse || 'Automatique', 
            Annee, Couleur || 'Blanc', photoUrl, 
            Energie || 'Essence', Puissance || 100, PrixLocation,
            Description || `${NomMarque} ${Modele}`, NbPlaces || 5, 
            IdStatut, IdMarque, 1 // Type par défaut à 1
        ]);
        
        // Récupération de l'ID auto-généré
        const IdVoiture = result.insertId;
        console.log(`Voiture créée avec l'ID: ${IdVoiture}`);
        
        res.status(201).json({ 
            message: 'Voiture créée avec succès',
            car: { IdVoiture, NomMarque, Modele, Annee, PrixLocation, Photo: photoUrl }
        });
    } catch (error) {
        console.error('Erreur lors de la création de la voiture:', error);
        res.status(500).json({ 
            message: 'Erreur lors de la création de la voiture', 
            error: error.message 
        });
    }
});

// Mise à jour d'une voiture
app.put('/api/admin/cars/:id', authenticateSession, async (req, res) => {
    try {
        // Vérification si l'utilisateur est admin
        if (req.session.user.role !== 'ADMIN' && req.session.user.role !== 'SUPERADMIN') {
            return res.status(403).json({ message: 'Non autorisé' });
        }
        
        // Conversion de l'ID string en entier si nécessaire
        const carId = parseInt(req.params.id) || req.params.id;
        const { 
            NomMarque, Modele, Annee, PrixLocation, IdStatut, NbPorte,
            BoiteVitesse, Couleur, Energie, Puissance, NbPlaces, Description, Photo
        } = req.body;
        
        console.log(`Mise à jour de la voiture avec l'ID: ${carId}`, req.body);
        
        // Vérification si la voiture existe
        const [carCheck] = await db.promise().query(
            'SELECT IdVoiture FROM Voiture WHERE IdVoiture = ?',
            [carId]
        );
        
        if (carCheck.length === 0) {
            return res.status(404).json({ message: 'Voiture non trouvée' });
        }
        
        // Récupération de l'ID de la marque à partir du nom si fourni
        let IdMarque = null;
        if (NomMarque) {
            const [brandRows] = await db.promise().query(
                'SELECT IdMarque FROM MarqueVoiture WHERE NomMarque = ?',
                [NomMarque]
            );
            
            if (brandRows.length === 0) {
                return res.status(404).json({ message: 'Marque non trouvée' });
            }
            
            IdMarque = brandRows[0].IdMarque;
        }
        
        // Construction de la requête de mise à jour dynamiquement selon les champs fournis
        let updateQuery = 'UPDATE Voiture SET ';
        const updateValues = [];
        
        if (Modele) {
            updateQuery += 'Modele = ?, ';
            updateValues.push(Modele);
        }
        
        if (Annee) {
            updateQuery += 'Annee = ?, ';
            updateValues.push(Annee);
        }
        
        if (PrixLocation) {
            updateQuery += 'PrixLocation = ?, ';
            updateValues.push(PrixLocation);
        }
        
        if (IdStatut) {
            updateQuery += 'IdStatut = ?, ';
            updateValues.push(IdStatut);
        }
        
        if (IdMarque) {
            updateQuery += 'IdMarque = ?, ';
            updateValues.push(IdMarque);
        }
        
        if (NbPorte) {
            updateQuery += 'NbPorte = ?, ';
            updateValues.push(NbPorte);
        }
        
        if (BoiteVitesse) {
            updateQuery += 'BoiteVitesse = ?, ';
            updateValues.push(BoiteVitesse);
        }
        
        if (Couleur) {
            updateQuery += 'Couleur = ?, ';
            updateValues.push(Couleur);
        }
        
        if (Energie) {
            updateQuery += 'Energie = ?, ';
            updateValues.push(Energie);
        }
        
        if (Puissance) {
            updateQuery += 'Puissance = ?, ';
            updateValues.push(Puissance);
        }
        
        if (NbPlaces) {
            updateQuery += 'NbPlaces = ?, ';
            updateValues.push(NbPlaces);
        }
        
        if (Description) {
            updateQuery += 'Description = ?, ';
            updateValues.push(Description);
        }
        
        // Gestion de la mise à jour de la photo
        if (Photo !== undefined) {
            updateQuery += 'Photo = ?, ';
            // Utilisation de l'URL fournie ou de la valeur par défaut si vide
            const photoUrl = Photo && Photo.trim() !== '' 
                ? Photo 
                : 'assets/images/default-car.jpg';
            updateValues.push(photoUrl);
        }
        
        // Suppression de la virgule finale et ajout de la clause WHERE
        updateQuery = updateQuery.slice(0, -2) + ' WHERE IdVoiture = ?';
        updateValues.push(carId);
        
        // Exécution de la requête de mise à jour
        await db.promise().query(updateQuery, updateValues);
        
        console.log(`Voiture ${carId} mise à jour avec succès`);
        res.json({ message: 'Voiture mise à jour avec succès' });
    } catch (error) {
        console.error('Erreur lors de la mise à jour de la voiture:', error);
        res.status(500).json({ 
            message: 'Erreur serveur', 
            error: error.message 
        });
    }
});

// Création d'un nouvel utilisateur (admin uniquement)
app.post('/api/admin/users', authenticateSession, async (req, res) => {
    try {
        // Vérification si l'utilisateur est admin
        if (req.session.user.role !== 'ADMIN' && req.session.user.role !== 'SUPERADMIN') {
            return res.status(403).json({ message: 'Non autorisé' });
        }
        
        const { Nom, Prenom, Email, Tel, MotDePasse, Role } = req.body;
        
        // Vérification si l'email existe déjà
        const [emailCheck] = await db.promise().query(
            'SELECT Email FROM Users WHERE Email = ?',
            [Email]
        );
        
        if (emailCheck.length > 0) {
            return res.status(400).json({ message: 'Email déjà utilisé' });
        }
        
        // Hachage du mot de passe
        const hashedPassword = await bcrypt.hash(MotDePasse, 10);
        
        // Génération de l'ID utilisateur
        const IdUser = 'USR' + Date.now().toString() + Math.random().toString(36).substring(2, 7);
        
        // Insertion de l'utilisateur
        await db.promise().query(`
            INSERT INTO Users (
                IdUser, Nom, Prenom, Email, Tel, MotDePasse,
                Role, DateInscription, PhotoProfil
            ) VALUES (?, ?, ?, ?, ?, ?, ?, NOW(), ?)
        `, [
            IdUser, Nom, Prenom, Email, Tel, hashedPassword,
            Role || 'CLIENT', 'assets/images/default-profile.png'
        ]);
        
        console.log(`Utilisateur créé avec l'ID: ${IdUser}`);
        res.status(201).json({ 
            message: 'Utilisateur créé avec succès',
            user: { IdUser, Nom, Prenom, Email, Role }
        });
    } catch (error) {
        console.error('Erreur lors de la création de l\'utilisateur:', error);
        res.status(500).json({ message: 'Erreur serveur', error: error.message });
    }
});

// Mise à jour d'un utilisateur
app.put('/api/admin/users/:id', authenticateSession, async (req, res) => {
    try {
        // Vérification si l'utilisateur est admin
        if (req.session.user.role !== 'ADMIN' && req.session.user.role !== 'SUPERADMIN') {
            return res.status(403).json({ message: 'Non autorisé' });
        }
        
        const userId = req.params.id;
        const { Nom, Prenom, Email, Tel, MotDePasse, Role } = req.body;
        
        console.log(`Mise à jour de l'utilisateur avec l'ID: ${userId}`, req.body);
        
        // Vérification si l'utilisateur existe
        const [userCheck] = await db.promise().query(
            'SELECT IdUser FROM Users WHERE IdUser = ?',
            [userId]
        );
        
        if (userCheck.length === 0) {
            return res.status(404).json({ message: 'Utilisateur non trouvé' });
        }
        
        // Vérification si l'email est modifié et existe déjà
        if (Email) {
            const [emailCheck] = await db.promise().query(
                'SELECT Email FROM Users WHERE Email = ? AND IdUser != ?',
                [Email, userId]
            );
            
            if (emailCheck.length > 0) {
                return res.status(400).json({ message: 'Email déjà utilisé par un autre utilisateur' });
            }
        }
        
        // Construction de la requête de mise à jour dynamiquement selon les champs fournis
        let updateQuery = 'UPDATE Users SET ';
        const updateValues = [];
        
        if (Nom) {
            updateQuery += 'Nom = ?, ';
            updateValues.push(Nom);
        }
        
        if (Prenom) {
            updateQuery += 'Prenom = ?, ';
            updateValues.push(Prenom);
        }
        
        if (Email) {
            updateQuery += 'Email = ?, ';
            updateValues.push(Email);
        }
        
        if (Tel) {
            updateQuery += 'Tel = ?, ';
            updateValues.push(Tel);
        }
        
        if (Role) {
            updateQuery += 'Role = ?, ';
            updateValues.push(Role);
        }
        
        if (MotDePasse) {
            const hashedPassword = await bcrypt.hash(MotDePasse, 10);
            updateQuery += 'MotDePasse = ?, ';
            updateValues.push(hashedPassword);
        }
        
        // Suppression de la virgule finale et ajout de la clause WHERE
        updateQuery = updateQuery.slice(0, -2) + ' WHERE IdUser = ?';
        updateValues.push(userId);
        
        // Exécution de la requête de mise à jour
        await db.promise().query(updateQuery, updateValues);
        
        console.log(`Utilisateur ${userId} mis à jour avec succès`);
        res.json({ message: 'Utilisateur mis à jour avec succès' });
    } catch (error) {
        console.error('Erreur lors de la mise à jour de l\'utilisateur:', error);
        res.status(500).json({ message: 'Erreur serveur', error: error.message });
    }
});

// Création d'une réservation pour l'admin
app.post('/api/admin/reservations', authenticateSession, async (req, res) => {
    try {
        // Vérification si l'utilisateur est admin
        if (req.session.user.role !== 'ADMIN' && req.session.user.role !== 'SUPERADMIN') {
            return res.status(403).json({ message: 'Non autorisé' });
        }
        
        const { IdUser, IdVoiture, DateDebut, DateFin, MontantReservation, Statut } = req.body;
        
        // Conversion des IDs au format approprié si nécessaire
        const userId = IdUser;
        const carId = parseInt(IdVoiture) || IdVoiture;
        
        console.log('Création d\'une nouvelle réservation avec les données:', { userId, carId, DateDebut, DateFin, MontantReservation, Statut });
        
        // Vérification si l'utilisateur existe
        const [userCheck] = await db.promise().query(
            'SELECT IdUser FROM Users WHERE IdUser = ?',
            [userId]
        );
        
        if (userCheck.length === 0) {
            return res.status(404).json({ message: 'Utilisateur non trouvé' });
        }
        
        // Vérification si la voiture existe et est disponible
        const [carCheck] = await db.promise().query(
            'SELECT IdVoiture, IdStatut FROM Voiture WHERE IdVoiture = ?',
            [carId]
        );
        
        if (carCheck.length === 0) {
            return res.status(404).json({ message: 'Voiture non trouvée' });
        }
        
        // Génération de l'ID de réservation
        const IdReservation = 'RES' + Date.now() + Math.random().toString(36).substr(2, 5);
        
        // Insertion de la réservation
        await db.promise().query(`
            INSERT INTO Reservation (
                IdReservation, DateDebut, DateFin, MontantReservation,
                Statut, IdUser, IdVoiture, DateReservation
            ) VALUES (?, ?, ?, ?, ?, ?, ?, NOW())
        `, [
            IdReservation, DateDebut, DateFin, MontantReservation,
            Statut || 'En attente', userId, carId
        ]);
        
        // Mise à jour du statut de la voiture si la réservation est confirmée
        if (Statut === 'Confirmée') {
            await db.promise().query(
                'UPDATE Voiture SET IdStatut = "STAT002" WHERE IdVoiture = ?',
                [carId]
            );
        }
        
        console.log(`Réservation créée avec l'ID: ${IdReservation}`);
        res.status(201).json({ 
            message: 'Réservation créée avec succès',
            reservation: { IdReservation, DateDebut, DateFin, MontantReservation, Statut }
        });
    } catch (error) {
        console.error('Erreur lors de la création de la réservation:', error);
        res.status(500).json({ message: 'Erreur serveur', error: error.message });
    }
});

// Mise à jour d'une réservation (admin uniquement)
app.put('/api/admin/reservations/:id', authenticateSession, async (req, res) => {
    try {
        // Vérification si l'utilisateur est admin
        if (req.session.user.role !== 'ADMIN' && req.session.user.role !== 'SUPERADMIN') {
            return res.status(403).json({ message: 'Non autorisé' });
        }
        
        const reservationId = req.params.id;
        const { IdUser, IdVoiture, DateDebut, DateFin, MontantReservation, Statut } = req.body;
        
        console.log(`Mise à jour de la réservation avec l'ID: ${reservationId}`, req.body);
        
        // Formatage des dates au format MySQL datetime (YYYY-MM-DD HH:mm:ss)
        const formattedDateDebut = new Date(DateDebut).toISOString().slice(0, 19).replace('T', ' ');
        const formattedDateFin = new Date(DateFin).toISOString().slice(0, 19).replace('T', ' ');
        
        console.log('Dates formatées:', { formattedDateDebut, formattedDateFin });
        
        // Vérification si la réservation existe
        const [reservationCheck] = await db.promise().query(
            'SELECT IdReservation, Statut as CurrentStatus FROM Reservation WHERE IdReservation = ?',
            [reservationId]
        );
        
        if (reservationCheck.length === 0) {
            return res.status(404).json({ message: 'Réservation non trouvée' });
        }
        
        // Vérification si l'utilisateur existe
        const [userCheck] = await db.promise().query(
            'SELECT IdUser FROM Users WHERE IdUser = ?',
            [IdUser]
        );
        
        if (userCheck.length === 0) {
            return res.status(404).json({ message: 'Utilisateur non trouvé' });
        }
        
        // Vérification si la voiture existe
        const [carCheck] = await db.promise().query(
            'SELECT IdVoiture, IdStatut FROM Voiture WHERE IdVoiture = ?',
            [IdVoiture]
        );
        
        if (carCheck.length === 0) {
            return res.status(404).json({ message: 'Voiture non trouvée' });
        }
        
        // Mise à jour de la réservation avec les dates formatées
        await db.promise().query(`
            UPDATE Reservation 
            SET DateDebut = ?,
                DateFin = ?,
                MontantReservation = ?,
                Statut = ?,
                IdUser = ?,
                IdVoiture = ?
            WHERE IdReservation = ?
        `, [formattedDateDebut, formattedDateFin, MontantReservation, Statut, IdUser, IdVoiture, reservationId]);
        
        // Mise à jour du statut de la voiture selon le statut de la réservation
        const currentStatus = reservationCheck[0].CurrentStatus;
        if (currentStatus !== Statut) {
            if (Statut === 'Confirmée') {
                await db.promise().query(
                    'UPDATE Voiture SET IdStatut = "STAT002" WHERE IdVoiture = ?',
                    [IdVoiture]
                );
            } else if (currentStatus === 'Confirmée' && Statut !== 'Confirmée') {
                await db.promise().query(
                    'UPDATE Voiture SET IdStatut = "STAT001" WHERE IdVoiture = ?',
                    [IdVoiture]
                );
            }
        }
        
        console.log(`Réservation ${reservationId} mise à jour avec succès`);
        res.json({ 
            message: 'Réservation mise à jour avec succès',
            reservation: { 
                IdReservation: reservationId, 
                DateDebut: formattedDateDebut, 
                DateFin: formattedDateFin, 
                MontantReservation, 
                Statut 
            }
        });
    } catch (error) {
        console.error('Erreur lors de la mise à jour de la réservation:', error);
        res.status(500).json({ message: 'Erreur serveur', error: error.message });
    }
});

// Proxy pour les images externes pour contourner CORS
app.use('/api/proxy-image', (req, res, next) => {
    // Configuration des en-têtes CORS complets pour le point de terminaison proxy
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 
        'Origin, X-Requested-With, Content-Type, Accept, Authorization, Cache-Control');
    res.setHeader('Access-Control-Max-Age', '86400'); // 24 heures

    // Gestion de la requête OPTIONS préliminaire
    if (req.method === 'OPTIONS') {
        return res.status(200).end();
    }
    
    next();
});

app.get('/api/proxy-image', async (req, res) => {
    const imageUrl = req.query.url;
    
    if (!imageUrl) {
        return res.status(400).json({ message: 'URL de l\'image manquante' });
    }
    
    console.log(`Proxy de l'image depuis: ${imageUrl}`);
    
    try {
        // Définition d'un délai d'attente pour la requête fetch pour éviter les blocages
        const controller = new AbortController();
        const timeoutId = setTimeout(() => controller.abort(), 10000); // délai de 10 secondes
        
        // S'assurer de gérer tous les types d'URLs
        const fetchUrl = imageUrl.startsWith('http') ? imageUrl : `http://${imageUrl}`;
        console.log(`Récupération depuis l'URL: ${fetchUrl}`);
        
        // Ajout d'un référent spécifique pour les images cdn.motor1.com
        const headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
        };
        
        if (fetchUrl.includes('cdn.motor1.com')) {
            headers['Referer'] = 'https://www.motor1.com/';
            console.log('Utilisation du référent motor1.com pour l\'image CDN');
        }
        
        const response = await fetch(fetchUrl, {
            signal: controller.signal,
            headers: headers,
            method: 'GET'
        });
        
        // Effacement du délai d'attente si la récupération est terminée
        clearTimeout(timeoutId);
        
        if (!response.ok) {
            console.log(`Échec de la récupération de l'image avec le statut: ${response.status} - ${response.statusText}`);
            return res.status(response.status).json({ 
                message: `Échec de la récupération de l'image: ${response.statusText}` 
            });
        }
        
        // Récupération du type de contenu de la réponse originale
        const contentType = response.headers.get('content-type');
        if (contentType) {
            console.log(`Type de contenu de l'image: ${contentType}`);
            res.setHeader('Content-Type', contentType);
        }
        
        // Ajout des en-têtes de mise en cache
        res.setHeader('Cache-Control', 'public, max-age=86400'); // Mise en cache pour 24 heures
        
        // Lecture des données de réponse comme arrayBuffer
        const arrayBuffer = await response.arrayBuffer();
        
        // Envoi des données de l'image
        res.end(Buffer.from(arrayBuffer));
    } catch (error) {
        console.error('Erreur lors du proxy de l\'image:', error);
        
        // Vérification s'il s'agit d'une erreur de délai d'attente
        if (error.name === 'AbortError') {
            return res.status(504).json({ 
                message: 'Délai d\'attente dépassé lors de la récupération de l\'image' 
            });
        }
        
        res.status(500).json({ 
            message: 'Erreur lors de la récupération de l\'image', 
            error: error.message 
        });
    }
});

// Ajout d'une route catch-all pour les fichiers image pour une meilleure gestion des erreurs
app.get('*.jpg|*.jpeg|*.png|*.gif|*.svg', (req, res, next) => {
  const requestPath = req.path;
  const filePath = path.join(__dirname, '..', requestPath);
  
  console.log(`Image demandée: ${requestPath}, vérification du chemin: ${filePath}`);
  
  // Vérification si le fichier existe
  fs.stat(filePath, (err, stats) => {
    if (err || !stats.isFile()) {
      console.log(`Fichier image non trouvé ou n'est pas un fichier: ${filePath}`);
      
      // Retour d'une image placeholder par défaut
      res.setHeader('Content-Type', 'image/svg+xml');
      res.setHeader('Cache-Control', 'public, max-age=3600');
      
      const colorHex = Math.floor(Math.random()*16777215).toString(16).padStart(6, '0');
      const baseName = path.basename(requestPath);
      
      res.send(`
        <svg xmlns="http://www.w3.org/2000/svg" width="200" height="150" viewBox="0 0 200 150">
          <rect width="200" height="150" fill="#${colorHex}" />
          <text x="50%" y="40%" font-family="Arial" font-size="16" fill="white" text-anchor="middle">Image non trouvée</text>
          <text x="50%" y="60%" font-family="Arial" font-size="12" fill="white" text-anchor="middle">${baseName}</text>
        </svg>
      `);
    } else {
      // Définition du Content-Type approprié selon l'extension du fichier
      const ext = path.extname(filePath).toLowerCase();
      switch(ext) {
        case '.jpg':
        case '.jpeg':
          res.setHeader('Content-Type', 'image/jpeg');
          break;
        case '.png':
          res.setHeader('Content-Type', 'image/png');
          break;
        case '.gif':
          res.setHeader('Content-Type', 'image/gif');
          break;
        case '.svg':
          res.setHeader('Content-Type', 'image/svg+xml');
          break;
      }
      
      // Définition des en-têtes de mise en cache
      res.setHeader('Cache-Control', 'public, max-age=86400');
      
      // Envoi du fichier
      res.sendFile(filePath);
    }
  });
});

// Démarrage du serveur
const PORT = process.env.PORT || 3000;
app.listen(PORT, '0.0.0.0', () => {
    console.log(`Serveur démarré sur le port ${PORT}`);
    console.log(`Accès à l'API sur http://172.16.199.254:${PORT}`);
});