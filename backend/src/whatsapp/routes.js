import express from 'express';
import { getQrCode, sendMessage, checkStatus } from './whatsappController.js';

const router = express.Router();

router.get('/qr', getQrCode);
router.get('/status', checkStatus);
router.post('/send-sos', sendMessage);

export default router;
