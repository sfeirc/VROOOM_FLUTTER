const express = require('express');
const mysql = require('mysql2');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const session = require('express-session');
const MySQLStore = require('express-mysql-session')(session);
const path = require('path');
const fs = require('fs');
// Replace node-fetch with undici fetch which is compatible with CommonJS
const { fetch } = require('undici');
require('dotenv').config();

const app = express();

// Serve static files from the assets directory
const assetsPath = path.join(__dirname, '../assets');
console.log(`Serving static files from: ${assetsPath}`);
// Check if directory exists
if (fs.existsSync(assetsPath)) {
    console.log(`Assets directory exists at: ${assetsPath}`);
} else {
    console.log(`WARNING: Assets directory does not exist at: ${assetsPath}`);
    // Create the directory
    try {
        fs.mkdirSync(path.join(assetsPath, 'images'), { recursive: true });
        fs.mkdirSync(path.join(assetsPath, 'logos'), { recursive: true });
        console.log('Created assets directories');
    } catch (err) {
        console.error('Error creating assets directory:', err);
    }
}

// Enable static file caching
const staticOptions = {
    etag: true,
    lastModified: true,
    setHeaders: (res, path) => {
        // Set caching headers for images
        if (path.endsWith('.jpg') || path.endsWith('.jpeg') || 
            path.endsWith('.png') || path.endsWith('.gif') ||
            path.endsWith('.svg')) {
            res.setHeader('Cache-Control', 'public, max-age=86400'); // 24 hours
            res.setHeader('Access-Control-Allow-Origin', '*');
        }
    }
};

// Serve static files with caching enabled
app.use('/assets', express.static(assetsPath, staticOptions));
// Also serve static files directly from the root path for backward compatibility
app.use(express.static(path.join(__dirname, '..'), staticOptions));

// Special endpoint to fetch local images with proper content type
app.get('/assets/images/:filename', (req, res) => {
  const filename = req.params.filename;
  const imagePath = path.join(__dirname, '..', 'assets', 'images', filename);
  
  console.log(`Fetching image file: ${imagePath}`);
  
  fs.stat(imagePath, (err, stats) => {
    if (err || !stats.isFile()) {
      console.log(`Image not found: ${imagePath}`);
      // Generate a placeholder image with car name
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
    
    // Set proper content type based on file extension
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
    
    // Set caching headers
    res.setHeader('Cache-Control', 'public, max-age=86400');
    res.setHeader('Access-Control-Allow-Origin', '*');
    
    // Send the file
    res.sendFile(imagePath);
  });
});

// Special endpoint to serve placeholder images
app.get('/api/assets/images/:filename', (req, res) => {
  const filename = req.params.filename;
  console.log(`Received request for placeholder image: ${filename}`);
  
  // Generate a placeholder image (colored rectangle with text)
  const svg = `
    <svg xmlns="http://www.w3.org/2000/svg" width="200" height="150" viewBox="0 0 200 150">
      <rect width="200" height="150" fill="#${Math.floor(Math.random()*16777215).toString(16)}" />
      <text x="50%" y="50%" font-family="Arial" font-size="16" fill="white" text-anchor="middle">${filename}</text>
    </svg>
  `;
  
  // Ensure proper caching headers
  res.setHeader('Cache-Control', 'public, max-age=86400'); // Cache for 24 hours
  res.setHeader('Content-Type', 'image/svg+xml');
  res.send(svg);
});

// Session store options
const options = {
    host: process.env.DB_HOST || 'localhost',
    port: 3306,
    user: process.env.DB_USER || 'clovis',
    password: process.env.DB_PASSWORD || 'clovis',
    database: process.env.DB_NAME || 'vroom_prestige',
    clearExpired: true,
    checkExpirationInterval: 900000,
    expiration: 86400000, // 24 hours
    createDatabaseTable: true,
    schema: {
        tableName: 'sessions',
        columnNames: {
            session_id: 'session_id',
            expires: 'expires',
            data: 'data'
        }
    }
};

// Create session store
const sessionStore = new MySQLStore(options);

// Middleware
app.use(cors({
    origin: '*', // Allow all origins
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With', 'X-User-Id', 'Cache-Control', 'Accept']
}));
app.use(express.json());

// Add OPTIONS handling for the user update endpoint
app.options('/api/admin/users/:id', cors());

// Session middleware
app.use(session({
    key: 'connect.sid',
    secret: process.env.SESSION_SECRET || 'vroom_prestige',
    store: sessionStore,
    resave: false,
    saveUninitialized: true, // Changed to true to ensure session is always created
    cookie: {
        secure: false, // Set to false for development over HTTP
        httpOnly: true,
        maxAge: 24 * 60 * 60 * 1000, // 24 hours
        sameSite: 'lax' // Changed to lax to work better in development
    }
}));

// Database connection
const db = mysql.createPool({
    host: process.env.DB_HOST || 'localhost',
    user: process.env.DB_USER || 'clovis',
    password: process.env.DB_PASSWORD || 'clovis',
    database: process.env.DB_NAME || 'vroom_prestige',
    waitForConnections: true,
    connectionLimit: 10,
    queueLimit: 0
});

// Authentication middleware with better error handling
const authenticateSession = (req, res, next) => {
    console.log('Authentication check:', req.session);
    console.log('Session ID:', req.sessionID);
    console.log('Headers:', req.headers);
    
    // Allow authentication via X-User-Id header (for Flutter app)
    if (req.headers['x-user-id']) {
        console.log('Authentication via X-User-Id header:', req.headers['x-user-id']);
        // Set the user in session if it doesn't exist
        if (!req.session.user) {
            // For this specific user ID, assign SUPERADMIN role
            const userId = req.headers['x-user-id'];
            req.session.user = {
                id: userId,
                role: 'SUPERADMIN'  // Always set to SUPERADMIN for now
            };
            console.log('Created session from X-User-Id header with SUPERADMIN role');
        }
        return next();
    }
    
    if (!req.session) {
        console.log('No session object found');
        return res.status(401).json({ message: 'No session found' });
    }
    
    if (!req.session.user) {
        console.log('No user in session');
        return res.status(401).json({ message: 'Session expired or invalid credentials' });
    }
    
    console.log('User authenticated:', req.session.user.email);
    next();
};

// AUTH ROUTES

// Login
app.post('/api/auth/login', async (req, res) => {
    const { email, password } = req.body;
    console.log('Login attempt for:', email);

    try {
        // Normal database authentication
        const [rows] = await db.promise().query(
            'SELECT * FROM Users WHERE Email = ?',
            [email]
        );

        if (rows.length === 0) {
            console.log('User not found:', email);
            return res.status(401).json({ message: 'Invalid credentials' });
        }

        const user = rows[0];
        const isPasswordValid = await bcrypt.compare(password, user.MotDePasse);

        if (!isPasswordValid) {
            console.log('Invalid password for:', email);
            return res.status(401).json({ message: 'Invalid credentials' });
        }

        // Set session data
        req.session.user = {
            id: user.IdUser,
            email: user.Email,
            role: user.Role,
            nom: user.Nom,
            prenom: user.Prenom,
            photo: user.PhotoProfil
        };
        
        // Save session explicitly
        req.session.save(err => {
            if (err) {
                console.error('Session save error:', err);
                return res.status(500).json({ message: 'Session error' });
            }
            
            console.log('Session saved successfully, ID:', req.sessionID);
            console.log('User data in session:', req.session.user);
            
            res.json({
                success: true,
                user: req.session.user
            });
        });
    } catch (error) {
        console.error('Login error:', error);
        res.status(500).json({ message: 'Server error' });
    }
});

// Logout
app.post('/api/auth/logout', (req, res) => {
    req.session.destroy((err) => {
        if (err) {
            return res.status(500).json({ message: 'Error logging out' });
        }
        res.clearCookie('connect.sid');
        res.json({ message: 'Logged out successfully' });
    });
});

// Check auth status
app.get('/api/auth/check', (req, res) => {
    console.log('Auth check request received');
    console.log('Session data:', req.session);
    console.log('Session ID:', req.sessionID);
    
    if (req.session && req.session.user) {
        console.log('User is authenticated:', req.session.user.email);
        res.json({
            isAuthenticated: true,
            user: req.session.user,
            sessionID: req.sessionID
        });
    } else {
        console.log('User is not authenticated');
        res.json({
            isAuthenticated: false,
            sessionID: req.sessionID
        });
    }
});

// Register
app.post('/api/auth/register', async (req, res) => {
    const { email, password, nom, prenom, tel, adresse } = req.body;

    try {
        const [existing] = await db.promise().query(
            'SELECT Email FROM Users WHERE Email = ?',
            [email]
        );

        if (existing.length > 0) {
            return res.status(400).json({ message: 'Email already exists' });
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

        res.status(201).json({ message: 'Registration successful' });
    } catch (error) {
        console.error('Registration error:', error);
        res.status(500).json({ message: 'Server error' });
    }
});

// CAR ROUTES

// Get all cars
app.get('/api/cars', async (req, res) => {
    try {
        // Get filter parameters from query
        const { brand, type, search } = req.query;
        
        // Build the base query with joins
        let query = `
            SELECT v.*, m.NomMarque, t.NomType
            FROM Voiture v
            JOIN MarqueVoiture m ON v.IdMarque = m.IdMarque
            JOIN TypeVehicule t ON v.IdType = t.IdType
            WHERE 1=1
        `;
        
        // Add filter conditions
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
        
        console.log('Executing car query with filters:', { brand, type, search });
        console.log('SQL Query:', query);
        console.log('SQL Parameters:', params);
        
        // Execute the query with parameters
        const [rows] = await db.promise().query(query, params);
        console.log(`Found ${rows.length} cars matching filters`);
        res.json(rows);
    } catch (error) {
        console.error('Error fetching cars:', error);
        res.status(500).json({ message: 'Server error', error: error.message });
    }
});

// Get all brands
app.get('/api/cars/brands', async (req, res) => {
    try {
        console.log('Fetching brands from database...');
        const [rows] = await db.promise().query('SELECT * FROM MarqueVoiture');
        console.log(`Found ${rows.length} brands`);
        res.json(rows);
    } catch (error) {
        console.error('Error fetching brands:', error);
        res.status(500).json({ message: 'Server error', error: error.message });
    }
});

// Get all types
app.get('/api/cars/types', async (req, res) => {
    try {
        console.log('Fetching vehicle types from database...');
        const [rows] = await db.promise().query('SELECT * FROM TypeVehicule');
        console.log(`Found ${rows.length} vehicle types`);
        res.json(rows);
    } catch (error) {
        console.error('Error fetching types:', error);
        res.status(500).json({ message: 'Server error', error: error.message });
    }
});

// Get featured cars
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
        res.status(500).json({ message: 'Server error' });
    }
});

// USER ROUTES

// Get user profile (requires authentication)
app.get('/api/users/profile', authenticateSession, async (req, res) => {
    try {
        const [rows] = await db.promise().query(
            'SELECT IdUser, Nom, Prenom, Email, Tel, Adresse, PhotoProfil, Role FROM Users WHERE IdUser = ?',
            [req.session.user.id]
        );

        if (rows.length === 0) {
            return res.status(404).json({ message: 'User not found' });
        }

        res.json(rows[0]);
    } catch (error) {
        console.error('Error fetching user profile:', error);
        res.status(500).json({ message: 'Server error', error: error.message });
    }
});

// Update user profile (requires authentication)
app.put('/api/users/profile', authenticateSession, async (req, res) => {
    const { nom, prenom, tel, adresse } = req.body;

    try {
        await db.promise().query(
            'UPDATE Users SET Nom = ?, Prenom = ?, Tel = ?, Adresse = ? WHERE IdUser = ?',
            [nom, prenom, tel, adresse, req.session.user.id]
        );

        // Update session data
        req.session.user = {
            ...req.session.user,
            nom,
            prenom
        };

        res.json({ message: 'Profile updated successfully' });
    } catch (error) {
        res.status(500).json({ message: 'Server error' });
    }
});

// ADMIN ROUTES

// Get all users (admin only)
app.get('/api/admin/users', authenticateSession, async (req, res) => {
    try {
        // Check if user is admin
        if (req.session.user.role !== 'ADMIN' && req.session.user.role !== 'SUPERADMIN') {
            return res.status(403).json({ message: 'Unauthorized' });
        }
        
        console.log('Fetching users from database for admin dashboard');
        const [rows] = await db.promise().query(
            'SELECT IdUser, Nom, Prenom, Email, Tel, Role, DateInscription FROM Users'
        );
        
        console.log(`Found ${rows.length} users`);
        res.json(rows);
    } catch (error) {
        console.error('Error fetching users:', error);
        res.status(500).json({ message: 'Server error', error: error.message });
    }
});

// Get all reservations (admin only)
app.get('/api/admin/reservations', authenticateSession, async (req, res) => {
    try {
        // Check if user is admin
        if (req.session.user.role !== 'ADMIN' && req.session.user.role !== 'SUPERADMIN') {
            return res.status(403).json({ message: 'Unauthorized' });
        }
        
        console.log('Fetching reservations from database for admin dashboard');
        const [rows] = await db.promise().query(`
            SELECT r.*, v.Modele, m.NomMarque, v.Photo
            FROM Reservation r
            JOIN Voiture v ON r.IdVoiture = v.IdVoiture
            JOIN MarqueVoiture m ON v.IdMarque = m.IdMarque
            ORDER BY r.DateReservation DESC
        `);
        
        console.log(`Found ${rows.length} reservations`);
        res.json(rows);
    } catch (error) {
        console.error('Error fetching reservations:', error);
        res.status(500).json({ message: 'Server error', error: error.message });
    }
});

// RESERVATION ROUTES

// Get user reservations
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
        console.error('Error fetching reservations:', error);
        res.status(500).json({ message: 'Server error', error: error.message });
    }
});

// Create reservation
app.post('/api/reservations', authenticateSession, async (req, res) => {
    const { carId, startDate, endDate, amount } = req.body;
    const userId = req.session.user.id;

    try {
        // Check availability
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
            message: 'Reservation created successfully'
        });
    } catch (error) {
        console.error('Error creating reservation:', error);
        res.status(500).json({ message: 'Server error', error: error.message });
    }
});

// Delete a car (admin only)
app.delete('/api/admin/cars/:id', authenticateSession, async (req, res) => {
    try {
        // Check if user is admin
        if (req.session.user.role !== 'ADMIN' && req.session.user.role !== 'SUPERADMIN') {
            return res.status(403).json({ message: 'Unauthorized' });
        }

        // Convert string ID to integer if needed
        const carId = parseInt(req.params.id) || req.params.id;
        console.log(`Attempting to delete car with ID: ${carId}`);

        // Check if car exists
        const [carCheck] = await db.promise().query(
            'SELECT IdVoiture FROM Voiture WHERE IdVoiture = ?',
            [carId]
        );

        if (carCheck.length === 0) {
            return res.status(404).json({ message: 'Car not found' });
        }

        // Check if car has reservations
        const [reservationCheck] = await db.promise().query(
            'SELECT COUNT(*) as count FROM Reservation WHERE IdVoiture = ? AND Statut NOT IN ("Annulée", "Terminée")',
            [carId]
        );

        if (reservationCheck[0].count > 0) {
            return res.status(400).json({ 
                message: 'Cannot delete car with active reservations. Cancel or complete all reservations first.' 
            });
        }

        // Delete the car
        await db.promise().query(
            'DELETE FROM Voiture WHERE IdVoiture = ?',
            [carId]
        );

        console.log(`Car ${carId} deleted successfully`);
        res.json({ message: 'Car deleted successfully' });
    } catch (error) {
        console.error('Error deleting car:', error);
        res.status(500).json({ message: 'Server error', error: error.message });
    }
});

// Delete a user (admin only)
app.delete('/api/admin/users/:id', authenticateSession, async (req, res) => {
    try {
        // Check if user is admin
        if (req.session.user.role !== 'ADMIN' && req.session.user.role !== 'SUPERADMIN') {
            return res.status(403).json({ message: 'Unauthorized' });
        }

        const userId = req.params.id;
        console.log(`Attempting to delete user with ID: ${userId}`);

        // Cannot delete yourself
        if (userId === req.session.user.id) {
            return res.status(400).json({ message: 'Cannot delete your own account' });
        }

        // Check if user exists
        const [userCheck] = await db.promise().query(
            'SELECT IdUser FROM Users WHERE IdUser = ?',
            [userId]
        );

        if (userCheck.length === 0) {
            return res.status(404).json({ message: 'User not found' });
        }

        // Delete all associated reservations
        await db.promise().query(
            'DELETE FROM Reservation WHERE IdUser = ?',
            [userId]
        );
        console.log(`Deleted all reservations for user ${userId}`);

        // Delete the user
        await db.promise().query(
            'DELETE FROM Users WHERE IdUser = ?',
            [userId]
        );

        console.log(`User ${userId} deleted successfully`);
        res.json({ message: 'User deleted successfully' });
    } catch (error) {
        console.error('Error deleting user:', error);
        res.status(500).json({ message: 'Server error', error: error.message });
    }
});

// Delete a reservation (admin only)
app.delete('/api/admin/reservations/:id', authenticateSession, async (req, res) => {
    try {
        // Check if user is admin
        if (req.session.user.role !== 'ADMIN' && req.session.user.role !== 'SUPERADMIN') {
            return res.status(403).json({ message: 'Unauthorized' });
        }

        const reservationId = req.params.id;
        console.log(`Attempting to delete reservation with ID: ${reservationId}`);

        // Check if reservation exists
        const [reservationCheck] = await db.promise().query(
            'SELECT IdReservation FROM Reservation WHERE IdReservation = ?',
            [reservationId]
        );

        if (reservationCheck.length === 0) {
            return res.status(404).json({ message: 'Reservation not found' });
        }

        // Delete the reservation
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

// Create/Update Car endpoints (admin only)
app.post('/api/admin/cars', authenticateSession, async (req, res) => {
    try {
        // Check if user is admin
        if (req.session.user.role !== 'ADMIN' && req.session.user.role !== 'SUPERADMIN') {
            return res.status(403).json({ message: 'Unauthorized' });
        }
        
        const { 
            NomMarque, Modele, Annee, PrixLocation, IdStatut, NbPorte, 
            BoiteVitesse, Couleur, Energie, Puissance, NbPlaces, Description, Photo
        } = req.body;
        
        console.log('Creating new car:', req.body);
        
        // Get brand ID from name
        const [brandRows] = await db.promise().query(
            'SELECT IdMarque FROM MarqueVoiture WHERE NomMarque = ?',
            [NomMarque]
        );
        
        if (brandRows.length === 0) {
            return res.status(404).json({ message: 'Brand not found' });
        }
        
        const IdMarque = brandRows[0].IdMarque;
        
        // Let MySQL handle the auto-increment for IdVoiture
        console.log('Inserting car with auto-increment ID');
        
        // Handle photo URL
        const photoUrl = Photo && Photo.trim() !== '' 
            ? Photo 
            : 'assets/images/default-car.jpg';
        
        // Insert the car (omitting IdVoiture field)
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
            IdStatut, IdMarque, 1 // Default type to 1
        ]);
        
        // Get the auto-generated ID
        const IdVoiture = result.insertId;
        console.log(`Car created with auto-generated ID: ${IdVoiture}`);
        
        res.status(201).json({ 
            message: 'Car created successfully',
            car: { IdVoiture, NomMarque, Modele, Annee, PrixLocation, Photo: photoUrl }
        });
    } catch (error) {
        console.error('Error creating car:', error);
        const errorMessage = error.code === 'ER_DATA_TOO_LONG' 
            ? 'One of the values is too long for the database column'
            : error.message;
            
        res.status(500).json({ 
            message: 'Error creating car', 
            error: errorMessage 
        });
    }
});

// Update a car
app.put('/api/admin/cars/:id', authenticateSession, async (req, res) => {
    try {
        // Check if user is admin
        if (req.session.user.role !== 'ADMIN' && req.session.user.role !== 'SUPERADMIN') {
            return res.status(403).json({ message: 'Unauthorized' });
        }
        
        // Convert string ID to integer if needed
        const carId = parseInt(req.params.id) || req.params.id;
        const { 
            NomMarque, Modele, Annee, PrixLocation, IdStatut, NbPorte,
            BoiteVitesse, Couleur, Energie, Puissance, NbPlaces, Description, Photo
        } = req.body;
        
        console.log(`Updating car with ID: ${carId}`, req.body);
        
        // Check if car exists
        const [carCheck] = await db.promise().query(
            'SELECT IdVoiture FROM Voiture WHERE IdVoiture = ?',
            [carId]
        );
        
        if (carCheck.length === 0) {
            return res.status(404).json({ message: 'Car not found' });
        }
        
        // Get brand ID from name if provided
        let IdMarque = null;
        if (NomMarque) {
            const [brandRows] = await db.promise().query(
                'SELECT IdMarque FROM MarqueVoiture WHERE NomMarque = ?',
                [NomMarque]
            );
            
            if (brandRows.length === 0) {
                return res.status(404).json({ message: 'Brand not found' });
            }
            
            IdMarque = brandRows[0].IdMarque;
        }
        
        // Build the update query dynamically based on provided fields
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
        
        // Handle photo URL update
        if (Photo !== undefined) {
            updateQuery += 'Photo = ?, ';
            // Use provided URL or default if empty
            const photoUrl = Photo && Photo.trim() !== '' 
                ? Photo 
                : 'assets/images/default-car.jpg';
            updateValues.push(photoUrl);
        }
        
        // Remove trailing comma and add WHERE clause
        updateQuery = updateQuery.slice(0, -2) + ' WHERE IdVoiture = ?';
        updateValues.push(carId);
        
        // Execute the update query
        await db.promise().query(updateQuery, updateValues);
        
        console.log(`Car ${carId} updated successfully`);
        res.json({ message: 'Car updated successfully' });
    } catch (error) {
        console.error('Error updating car:', error);
        res.status(500).json({ message: 'Server error', error: error.message });
    }
});

// Create a new user (admin only)
app.post('/api/admin/users', authenticateSession, async (req, res) => {
    try {
        // Check if user is admin
        if (req.session.user.role !== 'ADMIN' && req.session.user.role !== 'SUPERADMIN') {
            return res.status(403).json({ message: 'Unauthorized' });
        }
        
        const { Nom, Prenom, Email, Tel, MotDePasse, Role } = req.body;
        
        // Check if email already exists
        const [emailCheck] = await db.promise().query(
            'SELECT Email FROM Users WHERE Email = ?',
            [Email]
        );
        
        if (emailCheck.length > 0) {
            return res.status(400).json({ message: 'Email already in use' });
        }
        
        // Hash password
        const hashedPassword = await bcrypt.hash(MotDePasse, 10);
        
        // Generate user ID
        const IdUser = 'USR' + Date.now().toString() + Math.random().toString(36).substring(2, 7);
        
        // Insert user
        await db.promise().query(`
            INSERT INTO Users (
                IdUser, Nom, Prenom, Email, Tel, MotDePasse,
                Role, DateInscription, PhotoProfil
            ) VALUES (?, ?, ?, ?, ?, ?, ?, NOW(), ?)
        `, [
            IdUser, Nom, Prenom, Email, Tel, hashedPassword,
            Role || 'CLIENT', 'assets/images/default-profile.png'
        ]);
        
        console.log(`User created with ID: ${IdUser}`);
        res.status(201).json({ 
            message: 'User created successfully',
            user: { IdUser, Nom, Prenom, Email, Role }
        });
    } catch (error) {
        console.error('Error creating user:', error);
        res.status(500).json({ message: 'Server error', error: error.message });
    }
});

// Update a user
app.put('/api/admin/users/:id', cors(), authenticateSession, async (req, res) => {
    try {
        // Log the incoming request
        console.log('Received user update request:');
        console.log('URL:', req.url);
        console.log('Method:', req.method);
        console.log('Headers:', req.headers);
        console.log('Body:', req.body);
        console.log('Params:', req.params);
        
        // Check if user is admin
        if (req.session.user.role !== 'ADMIN' && req.session.user.role !== 'SUPERADMIN') {
            return res.status(403).json({ 
                success: false,
                message: 'Unauthorized' 
            });
        }
        
        const userId = req.params.id;
        const { Nom, Prenom, Email, Tel, MotDePasse, Role, Adresse } = req.body;
        
        console.log(`Updating user with ID: ${userId}`, req.body);
        
        // Check if user exists
        const [userCheck] = await db.promise().query(
            'SELECT IdUser, Email FROM Users WHERE IdUser = ?',
            [userId]
        );
        
        if (userCheck.length === 0) {
            console.log(`User not found with ID: ${userId}`);
            return res.status(404).json({ 
                success: false,
                message: 'User not found' 
            });
        }
        
        // Check if email is being changed and already exists
        if (Email && Email !== userCheck[0].Email) {
            const [emailCheck] = await db.promise().query(
                'SELECT Email FROM Users WHERE Email = ? AND IdUser != ?',
                [Email, userId]
            );
            
            if (emailCheck.length > 0) {
                return res.status(400).json({ 
                    success: false,
                    message: 'Email already in use by another user' 
                });
            }
        }
        
        // Build the update query dynamically based on provided fields
        const updateFields = [];
        const updateValues = [];
        
        // Handle each field, including null values
        if (Nom !== undefined) updateFields.push('Nom = ?') && updateValues.push(Nom);
        if (Prenom !== undefined) updateFields.push('Prenom = ?') && updateValues.push(Prenom);
        if (Email !== undefined) updateFields.push('Email = ?') && updateValues.push(Email);
        if (Tel !== undefined) updateFields.push('Tel = ?') && updateValues.push(Tel);
        if (Role !== undefined) updateFields.push('Role = ?') && updateValues.push(Role);
        if (Adresse !== undefined) updateFields.push('Adresse = ?') && updateValues.push(Adresse);
        
        // Handle password separately
        if (MotDePasse !== undefined && MotDePasse.trim() !== '') {
            const hashedPassword = await bcrypt.hash(MotDePasse, 10);
            updateFields.push('MotDePasse = ?');
            updateValues.push(hashedPassword);
        }
        
        // If no fields to update, return success
        if (updateFields.length === 0) {
            return res.json({ 
                success: true,
                message: 'No fields to update',
                user: userCheck[0]
            });
        }
        
        // Build and execute the query
        const updateQuery = `UPDATE Users SET ${updateFields.join(', ')} WHERE IdUser = ?`;
        updateValues.push(userId);
        
        console.log('Update query:', updateQuery);
        console.log('Update values:', updateValues);
        
        const [result] = await db.promise().query(updateQuery, updateValues);
        
        if (result.affectedRows === 0) {
            console.log(`No rows affected when updating user ${userId}`);
            return res.status(404).json({ 
                success: false,
                message: 'User not found or no changes made' 
            });
        }
        
        // Fetch the updated user data
        const [updatedUser] = await db.promise().query(
            'SELECT IdUser, Nom, Prenom, Email, Tel, Role, Adresse FROM Users WHERE IdUser = ?',
            [userId]
        );
        
        console.log(`User ${userId} updated successfully`);
        res.json({ 
            success: true,
            message: 'User updated successfully',
            user: updatedUser[0]
        });
    } catch (error) {
        console.error('Error updating user:', error);
        res.status(500).json({ 
            success: false,
            message: 'Server error', 
            error: error.message 
        });
    }
});

// Create a reservation for admin
app.post('/api/admin/reservations', authenticateSession, async (req, res) => {
    try {
        // Check if user is admin
        if (req.session.user.role !== 'ADMIN' && req.session.user.role !== 'SUPERADMIN') {
            return res.status(403).json({ message: 'Unauthorized' });
        }
        
        const { IdUser, IdVoiture, DateDebut, DateFin, MontantReservation, Statut } = req.body;
        
        // Convert IDs to proper format if needed
        const userId = IdUser;
        const carId = parseInt(IdVoiture) || IdVoiture;
        
        console.log('Creating new reservation with data:', { userId, carId, DateDebut, DateFin, MontantReservation, Statut });
        
        // Check if user exists
        const [userCheck] = await db.promise().query(
            'SELECT IdUser FROM Users WHERE IdUser = ?',
            [userId]
        );
        
        if (userCheck.length === 0) {
            return res.status(404).json({ message: 'User not found' });
        }
        
        // Check if car exists and is available
        const [carCheck] = await db.promise().query(
            'SELECT IdVoiture, IdStatut FROM Voiture WHERE IdVoiture = ?',
            [carId]
        );
        
        if (carCheck.length === 0) {
            return res.status(404).json({ message: 'Car not found' });
        }
        
        // Generate reservation ID
        const IdReservation = 'RES' + Date.now() + Math.random().toString(36).substr(2, 5);
        
        // Insert reservation
        await db.promise().query(`
            INSERT INTO Reservation (
                IdReservation, DateDebut, DateFin, MontantReservation,
                Statut, IdUser, IdVoiture, DateReservation
            ) VALUES (?, ?, ?, ?, ?, ?, ?, NOW())
        `, [
            IdReservation, DateDebut, DateFin, MontantReservation,
            Statut || 'En attente', userId, carId
        ]);
        
        // Update car status if reservation is confirmed
        if (Statut === 'Confirmée') {
            await db.promise().query(
                'UPDATE Voiture SET IdStatut = "STAT002" WHERE IdVoiture = ?',
                [carId]
            );
        }
        
        console.log(`Reservation created with ID: ${IdReservation}`);
        res.status(201).json({ 
            message: 'Reservation created successfully',
            reservation: { IdReservation, DateDebut, DateFin, MontantReservation, Statut }
        });
    } catch (error) {
        console.error('Error creating reservation:', error);
        res.status(500).json({ message: 'Server error', error: error.message });
    }
});

// Update a reservation (admin only)
app.put('/api/admin/reservations/:id', authenticateSession, async (req, res) => {
    try {
        // Check if user is admin
        if (req.session.user.role !== 'ADMIN' && req.session.user.role !== 'SUPERADMIN') {
            return res.status(403).json({ message: 'Unauthorized' });
        }
        
        const reservationId = req.params.id;
        const { IdUser, IdVoiture, DateDebut, DateFin, MontantReservation, Statut } = req.body;
        
        console.log(`Updating reservation with ID: ${reservationId}`, req.body);
        
        // Format dates to MySQL datetime format (YYYY-MM-DD HH:mm:ss)
        const formatDate = (dateString) => {
            const date = new Date(dateString);
            return date.toISOString().slice(0, 19).replace('T', ' ');
        };
        
        const formattedDateDebut = formatDate(DateDebut);
        const formattedDateFin = formatDate(DateFin);
        
        console.log('Formatted dates:', { formattedDateDebut, formattedDateFin });
        
        // Check if reservation exists
        const [reservationCheck] = await db.promise().query(
            'SELECT IdReservation, IdVoiture, Statut FROM Reservation WHERE IdReservation = ?',
            [reservationId]
        );
        
        if (reservationCheck.length === 0) {
            return res.status(404).json({ message: 'Reservation not found' });
        }
        
        // Check if user exists
        const [userCheck] = await db.promise().query(
            'SELECT IdUser FROM Users WHERE IdUser = ?',
            [IdUser]
        );
        
        if (userCheck.length === 0) {
            return res.status(404).json({ message: 'User not found' });
        }
        
        // Check if car exists
        const [carCheck] = await db.promise().query(
            'SELECT IdVoiture FROM Voiture WHERE IdVoiture = ?',
            [IdVoiture]
        );
        
        if (carCheck.length === 0) {
            return res.status(404).json({ message: 'Car not found' });
        }
        
        // Update reservation with formatted dates
        await db.promise().query(`
            UPDATE Reservation 
            SET IdUser = ?, IdVoiture = ?, DateDebut = ?, DateFin = ?, 
                MontantReservation = ?, Statut = ?
            WHERE IdReservation = ?
        `, [IdUser, IdVoiture, formattedDateDebut, formattedDateFin, MontantReservation, Statut, reservationId]);
        
        // If status is changed to "Confirmée", update car status to "Loué" (STAT002)
        if (Statut === 'Confirmée' && reservationCheck[0].Statut !== 'Confirmée') {
            await db.promise().query(
                'UPDATE Voiture SET IdStatut = "STAT002" WHERE IdVoiture = ?',
                [IdVoiture]
            );
        }
        // If status is changed from "Confirmée" to something else, update car status back to "Disponible" (STAT001)
        else if (reservationCheck[0].Statut === 'Confirmée' && Statut !== 'Confirmée') {
            await db.promise().query(
                'UPDATE Voiture SET IdStatut = "STAT001" WHERE IdVoiture = ?',
                [reservationCheck[0].IdVoiture]
            );
        }
        
        console.log(`Reservation ${reservationId} updated successfully`);
        res.json({ 
            message: 'Reservation updated successfully',
            reservation: { 
                IdReservation: reservationId, 
                DateDebut: formattedDateDebut, 
                DateFin: formattedDateFin, 
                MontantReservation, 
                Statut 
            }
        });
    } catch (error) {
        console.error('Error updating reservation:', error);
        res.status(500).json({ message: 'Server error', error: error.message });
    }
});

// Proxy for external images to bypass CORS
app.use('/api/proxy-image', (req, res, next) => {
    // Set comprehensive CORS headers for the proxy endpoint
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 
        'Origin, X-Requested-With, Content-Type, Accept, Authorization, Cache-Control');
    res.setHeader('Access-Control-Max-Age', '86400'); // 24 hours

    // Handle preflight OPTIONS request
    if (req.method === 'OPTIONS') {
        return res.status(200).end();
    }
    
    next();
});

app.get('/api/proxy-image', async (req, res) => {
    const imageUrl = req.query.url;
    
    if (!imageUrl) {
        return res.status(400).json({ message: 'Missing image URL' });
    }
    
    console.log(`Proxying image from: ${imageUrl}`);
    
    try {
        // Set a timeout for the fetch request to avoid hanging
        const controller = new AbortController();
        const timeoutId = setTimeout(() => controller.abort(), 10000); // 10 second timeout
        
        // Make sure we handle all types of URLs
        const fetchUrl = imageUrl.startsWith('http') ? imageUrl : `http://${imageUrl}`;
        console.log(`Fetching from URL: ${fetchUrl}`);
        
        // Add specific referrer for cdn.motor1.com images
        const headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
        };
        
        if (fetchUrl.includes('cdn.motor1.com')) {
            headers['Referer'] = 'https://www.motor1.com/';
            console.log('Using motor1.com referer for CDN image');
        }
        
        const response = await fetch(fetchUrl, {
            signal: controller.signal,
            headers: headers,
            method: 'GET'
        });
        
        // Clear the timeout if fetch completes
        clearTimeout(timeoutId);
        
        if (!response.ok) {
            console.log(`Image fetch failed with status: ${response.status} - ${response.statusText}`);
            return res.status(response.status).json({ 
                message: `Failed to fetch image: ${response.statusText}` 
            });
        }
        
        // Get the content type from the original response
        const contentType = response.headers.get('content-type');
        if (contentType) {
            console.log(`Image content type: ${contentType}`);
            res.setHeader('Content-Type', contentType);
        }
        
        // Add caching headers
        res.setHeader('Cache-Control', 'public, max-age=86400'); // Cache for 24 hours
        
        // Read the response data as arrayBuffer
        const arrayBuffer = await response.arrayBuffer();
        
        // Send the image data
        res.end(Buffer.from(arrayBuffer));
    } catch (error) {
        console.error('Error proxying image:', error);
        
        // Check if it's a timeout error
        if (error.name === 'AbortError') {
            return res.status(504).json({ 
                message: 'Request timeout when fetching image' 
            });
        }
        
        res.status(500).json({ 
            message: 'Error fetching image', 
            error: error.message 
        });
    }
});

// Add a catch-all route for image files to provide better error handling
app.get('*.jpg|*.jpeg|*.png|*.gif|*.svg', (req, res, next) => {
  const requestPath = req.path;
  const filePath = path.join(__dirname, '..', requestPath);
  
  console.log(`Image requested: ${requestPath}, checking at path: ${filePath}`);
  
  // Check if the file exists
  fs.stat(filePath, (err, stats) => {
    if (err || !stats.isFile()) {
      console.log(`Image file not found or is not a file: ${filePath}`);
      
      // Return a default placeholder image
      res.setHeader('Content-Type', 'image/svg+xml');
      res.setHeader('Cache-Control', 'public, max-age=3600');
      
      const colorHex = Math.floor(Math.random()*16777215).toString(16).padStart(6, '0');
      const baseName = path.basename(requestPath);
      
      res.send(`
        <svg xmlns="http://www.w3.org/2000/svg" width="200" height="150" viewBox="0 0 200 150">
          <rect width="200" height="150" fill="#${colorHex}" />
          <text x="50%" y="40%" font-family="Arial" font-size="16" fill="white" text-anchor="middle">Image not found</text>
          <text x="50%" y="60%" font-family="Arial" font-size="12" fill="white" text-anchor="middle">${baseName}</text>
        </svg>
      `);
    } else {
      // Set proper Content-Type based on file extension
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
      
      // Set caching headers
      res.setHeader('Cache-Control', 'public, max-age=86400');
      
      // Send the file
      res.sendFile(filePath);
    }
  });
});

// Start the server
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
    console.log(`Access the API at http://localhost:${PORT}`);
});