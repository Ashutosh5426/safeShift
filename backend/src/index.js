import express from "express";
import bodyParser from "body-parser";
import cors from "cors";
import userRoutes from "./users/user.routes.js";
import authRoutes from "./auth/auth.routes.js";
import contactsRoutes from "./contacts/contacts.routes.js";
import { authenticate } from "./middleware/auth.middleware.js";

const app = express();
app.use(cors());
app.use(bodyParser.json());

// Users CRUD routes
app.use("/api/users", userRoutes);

// Auth routes
app.use("/api/auth", authRoutes);

// Contacts routes (protected)
app.use("/api/contacts", authenticate, contactsRoutes);

// ✅ Test API
app.get("/", (req, res) => {
  res.send("✅ Node.js + SQLite Server Running");
});

// ✅ Start Server
app.listen(3000, () => {
  console.log("🚀 Server running on http://localhost:3000");
});
