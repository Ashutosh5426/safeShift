import { Router } from "express";
import { createUser, listUsers, getUserById, updateUser, deleteUser } from "./user.controller.js";

const router = Router();

// Create or upsert user
router.post("/", createUser);

// List users
router.get("/", listUsers);

// Get user by id
router.get("/:id", getUserById);

// Update user by id
router.put("/:id", updateUser);

// Delete user by id
router.delete("/:id", deleteUser);

export default router;


