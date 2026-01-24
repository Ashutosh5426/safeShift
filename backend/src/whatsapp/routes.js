import express from 'express';
import { getQrCode, getQrData, sendMessage, checkStatus } from './whatsappController.js';

const router = express.Router();

router.get('/qr', getQrCode);
router.get('/qr-data', getQrData);
router.get('/status', checkStatus);
router.post('/send-sos', sendMessage);

export default router;
