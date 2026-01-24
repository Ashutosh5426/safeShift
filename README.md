# safeShift
SafeShift – A Mobile Application for Ensuring Safety of Late-Night Employees

## Backend Setup

### Prerequisites
- Node.js (v18+ recommended)
- `npm` (usually comes with Node.js)

### Installation
1. Navigate to the backend directory:
   ```bash
   cd backend
   ```
2. Install dependencies:
   ```bash
   npm install
   ```

### Running the Server
To start the backend server in development mode (with auto-restart on changes):
```bash
npm run dev
```
The server will start at `http://localhost:3000`.

### Exposing Local Server (Ngrok)
This project includes a script to expose your local server to the internet using `ngrok`, which is useful for testing with the mobile app or webhooks.

1. Ensure the server is running (`npm run dev`) in one terminal.
2. In a **new** terminal window, navigate to the `backend` directory and run:
   ```bash
   npm run share
   ```
   This command runs `ngrok http 3000`. You will see a `https://....ngrok-free.app` URL in the output. Use this URL in your Flutter app config.

## Todo -
* Complete save profile - Profile Image Upload
* Add animations where possible like - Hero Icons
* Use toast instead of snackbar
* Remove hardcoded strings from everywhere
* Confirm user user if he/she's safe or not
* Backend Integration for Stationary Alerts
* PiP Mode on Location Tracking
