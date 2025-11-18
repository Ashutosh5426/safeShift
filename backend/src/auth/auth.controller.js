import jwt from "jsonwebtoken";
import dotenv from "dotenv";
import { OAuth2Client } from "google-auth-library";
import db from "../db/database.js";

dotenv.config();

const { GOOGLE_CLIENT_ID, JWT_SECRET } = process.env;
const googleClient = GOOGLE_CLIENT_ID ? new OAuth2Client(GOOGLE_CLIENT_ID) : null;

export const googleSignIn = async (req, res) => {
  try {
    const { idToken } = req.body;
    if (!idToken) {
      return res.status(400).json({ message: "idToken is required" });
    }

    if (!googleClient) {
      return res.status(500).json({ message: "Server missing GOOGLE_CLIENT_ID" });
    }

    const ticket = await googleClient.verifyIdToken({ idToken, audience: GOOGLE_CLIENT_ID });
    const payload = ticket.getPayload();
    if (!payload) {
      return res.status(401).json({ message: "Invalid Google token" });
    }

    const userId = payload.sub; // Google unique user ID
    const name = payload.name ?? null;
    const email = payload.email;
    const photo = payload.picture ?? null;

    if (!email) {
      return res.status(400).json({ message: "Email not present in Google token" });
    }

    const upsertQuery = `
      INSERT INTO users (id, name, email, photo, createdAt, updatedAt)
      VALUES (?, ?, ?, ?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
      ON CONFLICT(id) DO UPDATE SET
        name = excluded.name,
        email = excluded.email,
        photo = excluded.photo,
        updatedAt = CURRENT_TIMESTAMP
    `;

    await new Promise((resolve, reject) => {
      db.run(upsertQuery, [userId, name, email, photo], function (err) {
        if (err) return reject(err);
        resolve();
      });
    });

    const user = await new Promise((resolve, reject) => {
      db.get(
        `SELECT id, name, email, photo, mobileNo, createdAt, updatedAt FROM users WHERE id = ?`,
        [userId],
        (err, row) => {
          if (err) return reject(err);
          resolve(row);
        }
      );
    });

    const secret = JWT_SECRET;
    if (!secret) {
      return res.status(500).json({ message: "Server missing JWT_SECRET" });
    }

    const token = jwt.sign(
      { userId: user.id, email: user.email },
      secret,
      { expiresIn: "7d" }
    );

    return res.json({ token, user });
  } catch (err) {
    console.error("❌ Google sign-in error:", err);
    return res.status(500).json({ message: "Authentication failed" });
  }
};


