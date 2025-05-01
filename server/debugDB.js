// Script to debug database schema
const mysql = require('mysql2');
require('dotenv').config();

// Create a database connection
const db = mysql.createConnection({
  host: process.env.DB_HOST || 'localhost',
  user: process.env.DB_USER || 'clovis',
  password: process.env.DB_PASSWORD || 'clovis',
  database: process.env.DB_NAME || 'vroom_prestige',
});

// Connect to the database
db.connect((err) => {
  if (err) {
    console.error('Error connecting to database:', err);
    return;
  }
  
  console.log('Connected to database');
  
  // 1. Check table structure for Voiture
  db.query('DESCRIBE Voiture', (err, results) => {
    if (err) {
      console.error('Error getting Voiture table structure:', err);
    } else {
      console.log('Voiture table structure:');
      console.table(results);
      
      // Find the IdVoiture column
      const idColumn = results.find(col => col.Field === 'IdVoiture');
      console.log('\nIdVoiture column details:', idColumn);
    }
    
    // 2. Check sample data in Voiture
    db.query('SELECT * FROM Voiture LIMIT 1', (err, results) => {
      if (err) {
        console.error('Error getting sample Voiture data:', err);
      } else {
        console.log('\nSample Voiture data:');
        console.log(results);
      }
      
      // Close connection
      db.end();
    });
  });
}); 