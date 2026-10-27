const { contextBridge, ipcRenderer } = require('electron');

contextBridge.exposeInMainWorld('linkmax', {
  load: () => ipcRenderer.invoke('data:load'),
  save: (data) => ipcRenderer.invoke('data:save', data),
  openLink: (url) => ipcRenderer.invoke('link:open', url),
  pickImport: () => ipcRenderer.invoke('dialog:import'),
  pickExport: (opts) => ipcRenderer.invoke('dialog:export', opts),
  fetchFavicon: (url) => ipcRenderer.invoke('favicon:fetch', url),
  setThemeOverlay: (theme) => ipcRenderer.invoke('theme:overlay', theme),
  onDataChanged: (cb) => {
    ipcRenderer.on('data:external-update', () => cb());
  },
  getHotkey: () => ipcRenderer.invoke('hotkey:get')
});
