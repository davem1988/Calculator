const { contextBridge, ipcRenderer } = require('electron');

contextBridge.exposeInMainWorld('setup', {
    defaults() {
        return ipcRenderer.invoke('setup:defaults');
    },
    chooseFolder(current) {
        return ipcRenderer.invoke('setup:choose-folder', current);
    },
    install(options) {
        return ipcRenderer.invoke('setup:install', options);
    },
    openInstalled(dir) {
        return ipcRenderer.invoke('setup:open', dir);
    },
    close() {
        ipcRenderer.send('setup:close');
    },
});
