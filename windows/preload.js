// Gives the page the same bridge the macOS app provides (window.webkit.messageHandlers.darkroom).
const { contextBridge, ipcRenderer } = require('electron');
contextBridge.exposeInMainWorld('webkit', {
  messageHandlers: { darkroom: { postMessage: (msg) => ipcRenderer.invoke('darkroom', msg) } },
});
