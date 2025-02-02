const sqlite3 = require('sqlite3').verbose();
const bcrypt = require('bcrypt');
require('dotenv').config();

async function initializeDatabase() {
  const db = new sqlite3.Database('auth.db');

  try {
    await new Promise((resolve, reject) => {
      db.serialize(() => {
        // Create the users table if it doesn't exist
        db.run(
          `CREATE TABLE IF NOT EXISTS users (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          username TEXT UNIQUE NOT NULL,
          password TEXT NOT NULL
        )`,
          (err) => {
            if (err) reject('Error creating table: ' + err.message);
            else resolve();
          }
        );
      });
    });

    const defaultUsername = process.env.DEFAULT_ADMIN_USERNAME || 'admin';
    const defaultPassword = process.env.DEFAULT_ADMIN_PASSWORD || 'admin';
    const hashedPassword = await bcrypt.hash(defaultPassword, 10);

    // Check if there are any users in the table
    const existingUserCount = await new Promise((resolve, reject) => {
      db.get(`SELECT COUNT(*) AS count FROM users`, (err, row) => {
        if (err) reject('Error checking users count: ' + err.message);
        else resolve(row.count);
      });
    });

    if (existingUserCount === 0) {
      // No users exist, create the default admin user
      await new Promise((resolve, reject) => {
        db.run(
          `INSERT INTO users (username, password) VALUES (?, ?)`,
          [defaultUsername, hashedPassword],
          (err) => {
            if (err) reject('Error creating default user: ' + err.message);
            else resolve();
          }
        );
      });
      console.log('Default admin user created.');
    } else {
      console.log('Users already exist, skipping admin creation.');
    }
  } catch (err) {
    console.error('Error initializing database:', err);
  } finally {
    db.close((closeErr) => {
      if (closeErr) {
        console.error('Error closing database:', closeErr.message);
      } else {
        console.log('Database closed successfully.');
      }
    });
  }
}

module.exports = initializeDatabase;
