const { contextBridge, ipcRenderer } = require('electron');

contextBridge.exposeInMainWorld('updates', {
    setEnabled(enabled) {
        ipcRenderer.send('updates:set-enabled', Boolean(enabled));
    },
    onStatus(callback) {
        ipcRenderer.on('updates:status', (_event, status) => callback(status));
    },
});
