if (process.argv.includes('--setup-ui')) {
    require('./setup').start();
} else {
    startCalculator();
}

function startCalculator() {
const { app, BrowserWindow, ipcMain } = require('electron');
const path = require('path');
const { autoUpdater } = require('electron-updater');

autoUpdater.autoDownload = true;
autoUpdater.autoInstallOnAppQuit = true;

let mainWindow = null;
let updatesEnabled = true;

function sendUpdateStatus(status) {
    if (mainWindow && !mainWindow.isDestroyed()) {
        mainWindow.webContents.send('updates:status', status);
    }
}

function checkForUpdates() {
    if (!updatesEnabled || !app.isPackaged) return;

    autoUpdater.checkForUpdates().catch((error) => {
        sendUpdateStatus({ state: 'error', message: error.message });
    });
}

ipcMain.on('updates:set-enabled', (_event, enabled) => {
    updatesEnabled = Boolean(enabled);
    autoUpdater.autoInstallOnAppQuit = updatesEnabled;
    if (updatesEnabled) checkForUpdates();
});

autoUpdater.on('update-available', (info) => {
    sendUpdateStatus({ state: 'available', version: info.version });
});

autoUpdater.on('update-not-available', () => {
    sendUpdateStatus({ state: 'current' });
});

autoUpdater.on('update-downloaded', (info) => {
    sendUpdateStatus({ state: 'downloaded', version: info.version });
});

autoUpdater.on('error', (error) => {
    sendUpdateStatus({ state: 'error', message: error == null ? 'unknown' : error.message });
});

function createWindow() {
    mainWindow = new BrowserWindow({
        width: 460,
        height: 780,
        minWidth: 320,
        minHeight: 480,
        backgroundColor: '#0f0f0f',
        autoHideMenuBar: true,
        icon: path.join(__dirname, 'build', 'icon.png'),
        webPreferences: {
            preload: path.join(__dirname, 'preload.js'),
            contextIsolation: true,
            nodeIntegration: false,
        },
    });

    mainWindow.loadFile(path.join(__dirname, 'index.html'));
}

app.whenReady().then(createWindow);

app.on('window-all-closed', () => {
    if (process.platform !== 'darwin') {
        app.quit();
    }
});
}
