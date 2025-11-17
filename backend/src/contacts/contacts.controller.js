import db from "../db/database.js";

const mapContact = (row) => {
  if (!row) return null;
  // Handle id - use rowid as fallback since SQLite always has rowid
  // rowid is the actual internal row identifier and is always present
  const contactId = row.id ?? row.ID ?? row.rowid ?? null;
  const finalId = contactId != null ? Number(contactId) : null;
  
  // If id is still null, log a warning
  if (finalId === null && row.rowid != null) {
    console.warn("⚠️  Contact has null id but rowid exists:", row.rowid);
  }
  
  return {
    id: finalId,
    userId: row.userId,
    name: row.name,
    phone: row.phone,
    relationship: row.relationship,
    isPrimary: Boolean(row.isPrimary),
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  };
};

export const createContact = (req, res) => {
  const userId = req.user?.id;
  const { name, phone, relationship, isPrimary } = req.body;

  if (!userId) {
    return res.status(401).json({ message: "Unauthorized" });
  }

  if (!name || !phone) {
    return res.status(400).json({ message: "name and phone are required" });
  }

  // Check if phone number already exists for this user
  db.get(
    `SELECT id FROM contacts WHERE userId = ? AND phone = ?`,
    [userId, phone],
    (checkErr, existing) => {
      if (checkErr) {
        console.error("❌ Error checking duplicate phone:", checkErr);
        return res.status(500).json({ message: "Database error" });
      }

      if (existing) {
        return res.status(409).json({ 
          message: "Contact with this phone number already exists" 
        });
      }

      // Phone is unique, proceed with insert
      const query = `
        INSERT INTO contacts (userId, name, phone, relationship, isPrimary, createdAt, updatedAt)
        VALUES (?, ?, ?, ?, ?, datetime('now'), datetime('now'))
      `;

      db.run(
        query,
        [userId, name, phone, relationship ?? null, isPrimary ? 1 : 0],
        function (err) {
          if (err) {
            // Check if it's a unique constraint violation
            if (err.code === 'SQLITE_CONSTRAINT_UNIQUE' || err.message.includes('UNIQUE constraint')) {
              return res.status(409).json({ 
                message: "Contact with this phone number already exists" 
              });
            }
            console.error("❌ Error creating contact:", err);
            return res.status(500).json({ message: "Database error" });
          }

          const contactId = this.lastID;
          if (!contactId) {
            console.error("❌ No lastID returned after INSERT");
            return res.status(500).json({ message: "Failed to create contact" });
          }

          // Return the contact data directly since we have all the information
          // This avoids timing issues with SELECT after INSERT
          const now = new Date().toISOString().replace('T', ' ').substring(0, 19);
          const contact = {
            id: contactId,
            userId: userId,
            name: name,
            phone: phone,
            relationship: relationship ?? null,
            isPrimary: Boolean(isPrimary),
            createdAt: now,
            updatedAt: now,
          };

          return res.status(201).json(contact);
        }
      );
    }
  );
};

export const listContacts = (req, res) => {
  const userId = req.user?.id;

  if (!userId) {
    return res.status(401).json({ message: "Unauthorized" });
  }

  const query = `
    SELECT id, rowid, userId, name, phone, relationship, isPrimary, createdAt, updatedAt
    FROM contacts
    WHERE userId = ?
    ORDER BY isPrimary DESC, createdAt DESC
  `;

  db.all(query, [userId], (err, rows) => {
    if (err) {
      console.error("❌ Error listing contacts:", err);
      return res.status(500).json({ message: "Database error" });
    }
    // Debug: log first row to see what we're getting
    if (rows.length > 0) {
      console.log("🔍 Sample row from DB:", JSON.stringify(rows[0], null, 2));
      console.log("🔍 Row keys:", Object.keys(rows[0]));
      console.log("🔍 id value:", rows[0].id, "type:", typeof rows[0].id);
      console.log("🔍 rowid value:", rows[0].rowid, "type:", typeof rows[0].rowid);
    }
    return res.json(rows.map(mapContact));
  });
};

export const getContactById = (req, res) => {
  const userId = req.user?.id;
  const { id } = req.params;

  if (!userId) {
    return res.status(401).json({ message: "Unauthorized" });
  }

  // Try to find by id first, then by rowid if id is null in database
  // Convert id param to number for comparison
  const contactId = Number(id);
  
  db.get(
    `SELECT *, rowid FROM contacts 
     WHERE (id = ? OR rowid = ?) AND userId = ?`,
    [contactId, contactId, userId],
    (err, row) => {
      if (err) {
        console.error("❌ Error fetching contact:", err);
        return res.status(500).json({ message: "Database error" });
      }
      if (!row) {
        return res.status(404).json({ message: "Contact not found" });
      }
      return res.json(mapContact(row));
    }
  );
};

export const updateContact = (req, res) => {
  const userId = req.user?.id;
  const { id } = req.params;
  const { name, phone, relationship, isPrimary } = req.body;

  if (!userId) {
    return res.status(401).json({ message: "Unauthorized" });
  }

  const contactId = Number(id);

  // If phone is being updated, check for duplicates
  if (phone !== undefined) {
    db.get(
      `SELECT id, rowid FROM contacts 
       WHERE userId = ? AND phone = ? AND (id != ? OR rowid != ?)`,
      [userId, phone, contactId, contactId],
      (checkErr, existing) => {
        if (checkErr) {
          console.error("❌ Error checking duplicate phone:", checkErr);
          return res.status(500).json({ message: "Database error" });
        }

        if (existing) {
          return res.status(409).json({ 
            message: "Contact with this phone number already exists" 
          });
        }

        // No duplicate, proceed with update
        performUpdate();
      }
    );
  } else {
    // No phone update, proceed directly
    performUpdate();
  }

  function performUpdate() {
    const setClauses = [];
    const params = [];

    if (name !== undefined) {
      setClauses.push("name = ?");
      params.push(name);
    }
    if (phone !== undefined) {
      setClauses.push("phone = ?");
      params.push(phone);
    }
    if (relationship !== undefined) {
      setClauses.push("relationship = ?");
      params.push(relationship);
    }
    if (isPrimary !== undefined) {
      setClauses.push("isPrimary = ?");
      params.push(isPrimary ? 1 : 0);
    }

    if (setClauses.length === 0) {
      return res.status(400).json({ message: "No fields provided to update" });
    }

    setClauses.push("updatedAt = datetime('now')");

    const query = `
      UPDATE contacts
      SET ${setClauses.join(", ")}
      WHERE (id = ? OR rowid = ?) AND userId = ?
    `;

    db.run(query, [...params, contactId, contactId, userId], function (err) {
      if (err) {
        // Check if it's a unique constraint violation
        if (err.code === 'SQLITE_CONSTRAINT_UNIQUE' || err.message.includes('UNIQUE constraint')) {
          return res.status(409).json({ 
            message: "Contact with this phone number already exists" 
          });
        }
        console.error("❌ Error updating contact:", err);
        return res.status(500).json({ message: "Database error" });
      }
      if (this.changes === 0) {
        return res.status(404).json({ message: "Contact not found" });
      }

      db.get(
        `SELECT *, rowid FROM contacts 
         WHERE (id = ? OR rowid = ?) AND userId = ?`,
        [contactId, contactId, userId],
        (getErr, row) => {
          if (getErr) {
            console.error("❌ Error fetching updated contact:", getErr);
            return res.status(500).json({ message: "Database error" });
          }
          const contact = mapContact(row);
          if (!contact) {
            return res.status(500).json({ message: "Failed to load updated contact" });
          }
          return res.json(contact);
        }
      );
    });
  }
};

export const deleteContact = (req, res) => {
  const userId = req.user?.id;
  const { id } = req.params;

  if (!userId) {
    return res.status(401).json({ message: "Unauthorized" });
  }

  const contactId = Number(id);

  db.run(
    `DELETE FROM contacts WHERE (id = ? OR rowid = ?) AND userId = ?`,
    [contactId, contactId, userId],
    function (err) {
      if (err) {
        console.error("❌ Error deleting contact:", err);
        return res.status(500).json({ message: "Database error" });
      }
      if (this.changes === 0) {
        return res.status(404).json({ message: "Contact not found" });
      }
      return res.json({ message: "Contact deleted" });
    }
  );
};


