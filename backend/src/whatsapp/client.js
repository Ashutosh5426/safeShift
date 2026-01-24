import pkg from 'whatsapp-web.js';
const { Client, LocalAuth } = pkg;
import qrcode from 'qrcode';

const client = new Client({
    authStrategy: new LocalAuth({
        dataPath: '/tmp/safeShift/.wwebjs_auth'
    }),
    puppeteer: {
        headless: true,
        args: ['--no-sandbox', '--disable-setuid-sandbox']
    }
});

let qrCodeData = null;
let connectionStatus = 'DISCONNECTED'; // DISCONNECTED, WAITING_FOR_QR, CONNECTED

client.on('qr', async (qr) => {
    console.log('QR RECEIVED', qr);
    try {
        qrCodeData = await qrcode.toDataURL(qr);
        connectionStatus = 'WAITING_FOR_QR';
    } catch (err) {
        console.error('Error generating QR code', err);
    }
});

client.on('ready', () => {
    console.log('WhatsApp Client is ready!');
    connectionStatus = 'CONNECTED';
    qrCodeData = null; // Clear QR code on successful connection
});

client.on('authenticated', () => {
    console.log('WhatsApp Client authenticated!');
    connectionStatus = 'AUTHENTICATED';
});

client.on('auth_failure', msg => {
    console.error('AUTHENTICATION FAILURE', msg);
    connectionStatus = 'DISCONNECTED';
});

client.on('disconnected', (reason) => {
    console.log('Client was logged out', reason);
    connectionStatus = 'DISCONNECTED';
    client.initialize(); // Re-initialize to allow new login
});

export const initializeWhatsApp = () => {
    console.log('Initializing WhatsApp Client...');
    client.initialize();
};

const cleanup = async () => {
    console.log('Stopping WhatsApp Client...');
    try {
        await client.destroy();
        console.log('WhatsApp Client stopped.');
    } catch (err) {
        console.error('Error stopping WhatsApp Client:', err);
    }
};

process.on('SIGINT', async () => {
    await cleanup();
    process.exit(0);
});

process.on('SIGTERM', async () => {
    await cleanup();
    process.exit(0);
});

export const getQr = () => qrCodeData;
export const getStatus = () => connectionStatus;
export const getClient = () => client;
