import { getQr, getStatus, getClient } from './client.js';

export const getQrCode = (req, res) => {
    const qr = getQr();
    const status = getStatus();

    const htmlContent = (qrImage, statusMsg) => `
        <html>
            <head>
                <title>WhatsApp QR Code</title>
                <meta http-equiv="refresh" content="5">
                <style>
                    body { font-family: sans-serif; text-align: center; padding-top: 50px; }
                    img { border: 1px solid #ccc; padding: 10px; border-radius: 10px; }
                    .status { margin-top: 20px; font-weight: bold; }
                </style>
            </head>
            <body>
                <h1>WhatsApp Connection</h1>
                ${qrImage ? `<img src="${qrImage}" alt="QR Code" />` : ''}
                <div class="status">Status: ${statusMsg}</div>
                <p>Scan this QR code with your WhatsApp to connect.</p>
                <p>Page refreshes every 5 seconds.</p>
            </body>
        </html>
    `;

    // If connected, we don't need to show QR
    if (status === 'CONNECTED') {
        return res.send(htmlContent(null, 'CONNECTED - Client is already ready'));
    }

    if (qr) {
        return res.send(htmlContent(qr, status));
    }

    res.send(htmlContent(null, `${status} - QR code not yet available, please wait...`));
};

export const getQrData = (req, res) => {
    const qr = getQr();
    const status = getStatus();

    if (status === 'CONNECTED') {
        return res.status(200).json({ status: 'CONNECTED', qr: null });
    }

    // Return the Data URL (e.g., "data:image/png;base64,....")
    // This allows the frontend to strip the prefix and decode base64 if needed, 
    // or use it directly in an Image.network or similar web view.
    if (qr) {
        return res.status(200).json({ status, qr });
    }

    res.status(200).json({ status, qr: null });
};

export const sendMessage = async (req, res) => {
    const { numbers, message } = req.body;
    const client = getClient();
    const status = getStatus();

    if (status !== 'CONNECTED') {
        return res.status(503).json({ error: 'WhatsApp client is not connected' });
    }

    if (!numbers || !Array.isArray(numbers) || numbers.length === 0) {
        return res.status(400).json({ error: 'Invalid or missing numbers array' });
    }

    if (!message) {
        return res.status(400).json({ error: 'Missing message content' });
    }

    const results = [];

    for (const number of numbers) {
        try {
            // Append @c.us if not present for standard numbers.
            // Check if number is valid (simple check)
            const sanitizedNumber = number.replace(/\D/g, '');
            // Warning: This simple sanitization assumes cleaner input. 
            // Ideally we should use a library or more robust checks, but for now this suffices.
            // whatsapp-web.js expects '1234567890@c.us'

            const chatId = sanitizedNumber.includes('@c.us') ? sanitizedNumber : `${sanitizedNumber}@c.us`;

            await client.sendMessage(chatId, message);
            results.push({ number, status: 'sent' });
        } catch (error) {
            console.error(`Failed to send to ${number}:`, error);
            results.push({ number, status: 'failed', error: error.message });
        }
    }

    res.status(200).json({ results });
};

export const checkStatus = (req, res) => {
    res.status(200).json({ status: getStatus() });
};
