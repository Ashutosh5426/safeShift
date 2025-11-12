import db from "../db/database.js";

export const createUser = (req, res) => {
  const { id, name, email, photo, mobileNo } = req.body;

  if (!id || !email) {
    return res.status(400).json({ message: "id and email are required" });
  }

  const insertQuery = `
    INSERT INTO users (id, name, email, photo, mobileNo, createdAt, updatedAt)
    VALUES (?, ?, ?, ?, ?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
    ON CONFLICT(id) DO UPDATE SET
      name = excluded.name,
      email = excluded.email,
      photo = excluded.photo,
      mobileNo = excluded.mobileNo,
      updatedAt = CURRENT_TIMESTAMP
  `;

  db.run(
    insertQuery,
    [id, name ?? null, email, photo ?? null, mobileNo ?? null],
    function (err) {
      if (err) {
        console.error("❌ Error inserting/upserting user:", err);
        return res.status(500).json({ message: "Database error" });
      }
      return res.status(200).json({ message: "User saved/updated" });
    }
  );
};

export const listUsers = (_req, res) => {
  const query = `SELECT id, name, email, photo, mobileNo, createdAt, updatedAt FROM users`;
  db.all(query, [], (err, rows) => {
    if (err) {
      console.error("❌ Error listing users:", err);
      return res.status(500).json({ message: "Database error" });
    }
    return res.json(rows);
  });
};

export const getUserById = (req, res) => {
  const { id } = req.params;
  const query = `SELECT id, name, email, photo, mobileNo, createdAt, updatedAt FROM users WHERE id = ?`;
  db.get(query, [id], (err, row) => {
    if (err) {
      console.error("❌ Error fetching user:", err);
      return res.status(500).json({ message: "Database error" });
    }
    if (!row) {
      return res.status(404).json({ message: "User not found" });
    }
    return res.json(row);
  });
};

export const updateUser = (req, res) => {
  const { id } = req.params;
  const { name, email, photo, mobileNo } = req.body;

  const query = `
    UPDATE users
    SET
      name = COALESCE(?, name),
      email = COALESCE(?, email),
      photo = COALESCE(?, photo),
      mobileNo = COALESCE(?, mobileNo),
      updatedAt = CURRENT_TIMESTAMP
    WHERE id = ?
  `;

  db.run(query, [name ?? null, email ?? null, photo ?? null, mobileNo ?? null, id], function (err) {
    if (err) {
      console.error("❌ Error updating user:", err);
      return res.status(500).json({ message: "Database error" });
    }
    if (this.changes === 0) {
      return res.status(404).json({ message: "User not found" });
    }
    return res.json({ message: "User updated" });
  });
};

export const deleteUser = (req, res) => {
  const { id } = req.params;
  const query = `DELETE FROM users WHERE id = ?`;
  db.run(query, [id], function (err) {
    if (err) {
      console.error("❌ Error deleting user:", err);
      return res.status(500).json({ message: "Database error" });
    }
    if (this.changes === 0) {
      return res.status(404).json({ message: "User not found" });
    }
    return res.json({ message: "User deleted" });
  });
};


