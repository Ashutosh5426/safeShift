import sqlite3pkg from 'sqlite3';

const sqlite3 = sqlite3pkg.verbose();

// Create or connect to SQLite database file - SINGLE INSTANCE
const db = new sqlite3.Database('./users.db', (err) => {
  if (err) {
    console.error("❌ Error connecting to SQLite:", err);
  } else {
    console.log("✅ Connected to SQLite database.");
    // Initialize tables after connection
    initializeTables();
  }
});

function initializeTables() {
  // Create users table
  db.run(`
    CREATE TABLE IF NOT EXISTS users (
      id TEXT PRIMARY KEY,
      name TEXT,
      email TEXT,
      photo TEXT,
      mobileNo TEXT,
      createdAt DATETIME DEFAULT CURRENT_TIMESTAMP,
      updatedAt DATETIME
    )
  `);

  // Create contacts table
  db.run(`
    CREATE TABLE IF NOT EXISTS contacts (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      userId TEXT NOT NULL,
      name TEXT NOT NULL,
      phone TEXT NOT NULL,
      relationship TEXT,
      isPrimary INTEGER DEFAULT 0,
      createdAt DATETIME DEFAULT CURRENT_TIMESTAMP,
      updatedAt DATETIME,
      FOREIGN KEY (userId) REFERENCES users(id) ON DELETE CASCADE
    )
  `, (err) => {
    if (err) {
      console.error("❌ Error creating contacts table:", err);
      return;
    }
    
    // Function to create unique index
    const createUniqueIndex = () => {
      // First, try to drop the index if it exists (in case it's in a broken state)
      db.run(`DROP INDEX IF EXISTS idx_contacts_user_phone`, (dropErr) => {
        // Ignore drop errors - index might not exist
        // Now create the unique index
        db.run(`
          CREATE UNIQUE INDEX idx_contacts_user_phone 
          ON contacts(userId, phone)
        `, (indexErr) => {
          if (indexErr) {
            console.error("❌ Error creating unique index:", indexErr);
          } else {
            console.log("✅ Unique index on (userId, phone) created.");
          }
        });
      });
    };

    // Clean up duplicate contacts before creating unique index
    // Find and delete duplicates, keeping only the one with the highest id
    db.all(`
      SELECT userId, phone, MAX(id) as keepId
      FROM contacts
      GROUP BY userId, phone
      HAVING COUNT(*) > 1
    `, (findErr, duplicates) => {
      if (findErr) {
        console.error("❌ Error finding duplicates:", findErr);
        createUniqueIndex();
        return;
      }

      if (duplicates.length === 0) {
        console.log("✅ No duplicates found.");
        createUniqueIndex();
        return;
      }

      // Delete duplicates for each userId+phone combination, keeping the highest id
      let deletedCount = 0;
      let processed = 0;
      
      duplicates.forEach((dup) => {
        db.run(`
          DELETE FROM contacts
          WHERE userId = ? AND phone = ? AND id < ?
        `, [dup.userId, dup.phone, dup.keepId], function(deleteErr) {
          if (deleteErr) {
            console.error(`❌ Error deleting duplicates for ${dup.userId}/${dup.phone}:`, deleteErr);
          } else {
            deletedCount += this.changes;
          }
          
          processed++;
          if (processed === duplicates.length) {
            if (deletedCount > 0) {
              console.log(`✅ Cleaned up ${deletedCount} duplicate contact(s).`);
            }
            createUniqueIndex();
          }
        });
      });
    });

    // Ensure new columns exist when upgrading existing tables
    db.all(`PRAGMA table_info(contacts)`, (err, columns) => {
      if (err) {
        console.error("❌ Error inspecting contacts table:", err);
        return;
      }

      const columnNames = columns.map((column) => column.name);

      const ensureColumn = (name, definition) => {
        if (!columnNames.includes(name)) {
          db.run(`ALTER TABLE contacts ADD COLUMN ${definition}`, (alterErr) => {
            if (alterErr) {
              console.error(`❌ Error adding ${name} column to contacts:`, alterErr);
            } else {
              console.log(`✅ Added ${name} column to contacts table.`);
            }
          });
        }
      };

      ensureColumn("relationship", "relationship TEXT");
      ensureColumn("isPrimary", "isPrimary INTEGER DEFAULT 0");
      ensureColumn("createdAt", "createdAt DATETIME DEFAULT CURRENT_TIMESTAMP");
      ensureColumn("updatedAt", "updatedAt DATETIME");
    });
  });
}

// Export the SINGLE database instance
export default db;
