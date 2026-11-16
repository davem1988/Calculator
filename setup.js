const { app, BrowserWindow, dialog, ipcMain } = require('electron');
const { spawn } = require('child_process');
const fs = require('fs');
const path = require('path');

function readArg(flag) {
    const prefix = `${flag}=`;
    const found = process.argv.find((item) => item.startsWith(prefix));
    if (!found) return '';
    return found.slice(prefix.length).replace(/^"|"$/g, '');
}

function readPayloadFile(payload, name) {
    if (!payload) return '';
    const file = path.join(payload, name);
    if (!fs.existsSync(file)) return '';
    const asUtf16 = fs.readFileSync(file, 'utf16le').replace(/^\uFEFF/, '').replace(/\0/g, '').trim();
    if (asUtf16.includes(':\\') || asUtf16.startsWith('\\\\')) return asUtf16;
    return fs.readFileSync(file, 'utf8').replace(/^\uFEFF/, '').trim();
}

function withAppFolder(dir) {
    if (!dir) return dir;
    if (dir.toLowerCase().includes('calculator')) return dir;
    return path.join(dir, 'Calculator');
}

function safeDir(dir) {
    if (typeof dir !== 'string') return '';
    const cleaned = dir.trim();
    if (!path.isAbsolute(cleaned)) return '';
    if (/["\r\n]/.test(cleaned)) return '';
    return cleaned;
}

function runInstaller(installer, dir) {
    return new Promise((resolve) => {
        const child = spawn(installer, ['/S', `/D=${dir}`], {
            windowsVerbatimArguments: true,
            stdio: 'ignore',
        });
        child.on('error', (error) => resolve({ ok: false, message: error.message }));
        child.on('exit', (code) => {
            if (code === 0) resolve({ ok: true });
            else resolve({ ok: false, message: `Setup stopped (${code}).` });
        });
    });
}

function openApp(dir) {
    const exe = path.join(dir, 'Calculator.exe');
    const child = spawn(exe, [], { detached: true, stdio: 'ignore' });
    child.unref();
}

function start() {
    const payload = readArg('--payload');
    let window = null;

    const savedDir = readPayloadFile(payload, 'install-dir.txt');
    const installer = readPayloadFile(payload, 'installer-path.txt');
    const fallbackDir = path.join(process.env.LOCALAPPDATA || '', 'Programs', 'Calculator');

    ipcMain.handle('setup:defaults', () => ({
        dir: savedDir || fallbackDir,
        packaged: Boolean(installer),
    }));

    ipcMain.handle('setup:choose-folder', async (_event, current) => {
        const result = await dialog.showOpenDialog(window, {
            title: 'Install Calculator to',
            defaultPath: safeDir(current) || fallbackDir,
            properties: ['openDirectory', 'createDirectory'],
        });
        if (result.canceled || !result.filePaths[0]) return '';
        return withAppFolder(result.filePaths[0]);
    });

    ipcMain.handle('setup:install', async (_event, options) => {
        const dir = withAppFolder(safeDir(options && options.dir));
        if (!dir) return { ok: false, message: 'Choose a folder.' };
        if (!installer || !fs.existsSync(installer)) {
            return { ok: false, message: 'Open the packaged setup to install.' };
        }
        const result = await runInstaller(installer, dir);
        if (result.ok && options && options.launch) openApp(dir);
        return { ...result, dir };
    });

    ipcMain.handle('setup:open', (_event, dir) => {
        const target = safeDir(dir);
        if (!target) return false;
        openApp(target);
        return true;
    });

    ipcMain.on('setup:close', () => {
        if (window && !window.isDestroyed()) window.close();
    });

    app.whenReady().then(() => {
        window = new BrowserWindow({
            width: 500,
            height: 520,
            resizable: false,
            maximizable: false,
            minimizable: false,
            fullscreenable: false,
            frame: false,
            roundedCorners: true,
            thickFrame: false,
            backgroundColor: '#0f0f0f',
            autoHideMenuBar: true,
            title: 'Install Calculator',
            icon: path.join(__dirname, 'build', 'icon.png'),
            webPreferences: {
                preload: path.join(__dirname, 'setup-preload.js'),
                contextIsolation: true,
                nodeIntegration: false,
            },
        });
        window.setMenuBarVisibility(false);
        window.loadFile(path.join(__dirname, 'setup.html'));
    });

    app.on('window-all-closed', () => {
        app.quit();
    });
}

module.exports = { start };
