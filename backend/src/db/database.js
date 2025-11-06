import sqlite3pkg from 'sqlite3';

const sqlite3 = sqlite3pkg.verbose();

// Create or connect to SQLite database file
const db = new sqlite3.Database('./users.db', (err) => {
  if (err) {
    console.error("❌ Error connecting to SQLite:", err);
  } else {
    console.log("✅ Connected to SQLite database.");
  }
});

// Create table if not exists
db.run(`
  CREATE TABLE IF NOT EXISTS users (
    id TEXT PRIMARY KEY,       -- Firebase UID
    name TEXT,
    email TEXT,
    photo TEXT,
    mobileNo TEXT,
    createdAt DATETIME DEFAULT CURRENT_TIMESTAMP,
    updatedAt DATETIME
  )
`);

export default db;
