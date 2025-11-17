import { Router } from "express";
import {
  createContact,
  listContacts,
  getContactById,
  updateContact,
  deleteContact,
} from "./contacts.controller.js";

const router = Router();

router.post("/", createContact);
router.get("/", listContacts);
router.get("/:id", getContactById);
router.put("/:id", updateContact);
router.delete("/:id", deleteContact);

export default router;
