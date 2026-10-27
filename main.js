const { app, BrowserWindow, Menu, ipcMain, shell, dialog, net, Tray, globalShortcut, clipboard, Notification } = require('electron');
const path = require('path');
const fsp = require('fs/promises');
const fs = require('fs');
const crypto = require('crypto');

// Test-only: isolated userData so tests can run beside a real instance.
const TEST_MODE = process.env.SMOKE_TEST === '1' || process.env.LINKMAX_REAL_TEST === '1';
if (TEST_MODE && process.env.SMOKE_USER_DATA) {
  app.setPath('userData', process.env.SMOKE_USER_DATA);
}

const gotLock = app.requestSingleInstanceLock();
if (!gotLock) {
  app.quit();
}

let mainWindow = null;
let tray = null;
let isQuitting = false;
let activeHotkey = null; // canonical accelerator, e.g. 'CommandOrControl+Shift+L'
let activeHotkeyDisplay = null; // human-readable, e.g. 'Ctrl+Shift+L'
let trayHintShown = false;
const TRAY_ICON = path.join(__dirname, 'build', 'icon.ico');

function logDiag(line) {
  try {
    fs.appendFileSync(
      path.join(app.getPath('userData'), 'linkmax-log.txt'),
      new Date().toISOString() + '  ' + line + '\n'
    );
  } catch (_) {}
}

function dataFile() {
  return path.join(app.getPath('userData'), 'linkmax-data.json');
}

function faviconDir() {
  return path.join(app.getPath('userData'), 'favicons');
}

function uid(prefix) {
  return prefix + '_' + Date.now().toString(36) + Math.random().toString(36).slice(2, 8);
}

function seedData() {
  let now = Date.now();
  const cat = (id, name) => ({ id, name, createdAt: now });
  const lnk = (id, name, url, categoryId) => ({ id, name, url, categoryId, favicon: '', createdAt: (now += 1) });
  return {
    version: 1,
    settings: { view: 'grid' },
    categories: [
      cat('cat_dev', 'Development'),
      cat('cat_tools', 'Tools'),
      cat('cat_social', 'Social')
    ],
    links: [
      lnk('lnk_github', 'GitHub', 'https://github.com', 'cat_dev'),
      lnk('lnk_stack', 'Stack Overflow', 'https://stackoverflow.com', 'cat_dev'),
      lnk('lnk_mdn', 'MDN Web Docs', 'https://developer.mozilla.org', 'cat_dev'),
      lnk('lnk_chatgpt', 'ChatGPT', 'https://chatgpt.com', 'cat_tools'),
      lnk('lnk_npm', 'npm', 'https://www.npmjs.com', 'cat_tools'),
      lnk('lnk_drive', 'Google Drive', 'https://drive.google.com', 'cat_tools'),
      lnk('lnk_youtube', 'YouTube', 'https://www.youtube.com', 'cat_social'),
      lnk('lnk_x', 'X', 'https://x.com', 'cat_social'),
      lnk('lnk_reddit', 'Reddit', 'https://www.reddit.com', 'cat_social')
    ]
  };
}

function normalizeData(data) {
  const out = { version: 1, settings: {}, categories: [], links: [] };
  if (data && typeof data === 'object') {
    if (Array.isArray(data.categories)) {
      out.categories = data.categories
        .filter((c) => c && typeof c.name === 'string' && c.name.trim())
        .map((c) => ({
          id: typeof c.id === 'string' && c.id ? c.id : uid('cat'),
          name: c.name.trim(),
          color: typeof c.color === 'string' && c.color ? c.color : '#2563EB',
          createdAt: Number(c.createdAt) || Date.now()
        }));
    }
    if (Array.isArray(data.links)) {
      out.links = data.links
        .filter((l) => l && typeof l.url === 'string' && l.url.trim())
        .map((l) => ({
          id: typeof l.id === 'string' && l.id ? l.id : uid('lnk'),
          name: typeof l.name === 'string' && l.name.trim() ? l.name.trim() : l.url.trim(),
          url: l.url.trim(),
          categoryId: typeof l.categoryId === 'string' && l.categoryId ? l.categoryId : null,
          favicon: typeof l.favicon === 'string' && l.favicon ? l.favicon : '',
          createdAt: Number(l.createdAt) || Date.now(),
          pinned: l.pinned === true
        }));
    }
    if (data.settings && typeof data.settings === 'object') {
      out.settings = {
        view: data.settings.view === 'list' ? 'list' : 'grid',
        theme: data.settings.theme === 'dark' ? 'dark' : 'light',
        sortMode: ['name', 'nameDesc', 'newest', 'oldest'].includes(data.settings.sortMode)
          ? data.settings.sortMode
          : 'name'
      };
    }
  }
  return out;
}

async function loadData() {
  try {
    const raw = await fsp.readFile(dataFile(), 'utf8');
    return normalizeData(JSON.parse(raw));
  } catch (err) {
    const seeded = seedData();
    try {
      await saveData(seeded);
    } catch (_) {}
    return seeded;
  }
}

async function saveData(data) {
  const clean = normalizeData(data);
  await fsp.mkdir(path.dirname(dataFile()), { recursive: true });
  await fsp.writeFile(dataFile(), JSON.stringify(clean, null, 2), 'utf8');
  return true;
}

async function fetchFavicon(pageUrl) {
  let host;
  let origin;
  try {
    const u = new URL(pageUrl);
    if (u.protocol !== 'http:' && u.protocol !== 'https:') return null;
    host = u.hostname;
    origin = u.origin;
  } catch (_) {
    return null;
  }

  await fsp.mkdir(faviconDir(), { recursive: true });
  const key = crypto.createHash('md5').update(host).digest('hex');
  const file = path.join(faviconDir(), key + '.ico');
  if (fs.existsSync(file) && fs.statSync(file).size > 0) return file;

  const candidates = [
    `https://www.google.com/s2/favicons?sz=64&domain=${encodeURIComponent(host)}`,
    `https://icons.duckduckgo.com/ip3/${host}.ico`,
    origin + '/favicon.ico'
  ];

  for (const url of candidates) {
    try {
      const res = await net.fetch(url, { signal: AbortSignal.timeout(8000) });
      if (!res.ok) continue;
      const buf = Buffer.from(await res.arrayBuffer());
      if (buf.length < 100) continue;
      const head = buf.subarray(0, 5).toString('ascii').toLowerCase();
      if (head.startsWith('<')) continue;
      await fsp.writeFile(file, buf);
      return file;
    } catch (_) {}
  }
  return null;
}

const faviconInflight = new Map();

function extractUrl(text) {
  if (!text) return null;
  let m = text.match(/https?:\/\/[^\s<>"')\]]+/i);
  if (m) return m[0];
  m = text.match(/(^|\s)(www\.[a-z0-9-]+(?:\.[a-z0-9-]+)+[^\s<>"')\]]*)/i);
  if (m) return 'https://' + m[2];
  return null;
}

function normalizeUrlMain(u) {
  const s = (u || '').trim();
  if (!s) return '';
  if (/^[a-z][a-z0-9+.-]*:/i.test(s)) return s;
  return 'https://' + s;
}

function hostMain(u) {
  try {
    return new URL(u).hostname.replace(/^www\./, '');
  } catch (_) {
    return '';
  }
}

function notify(title, body) {
  if (TEST_MODE) return;
  try {
    if (Notification.isSupported()) new Notification({ title, body, icon: TRAY_ICON }).show();
  } catch (_) {}
}

async function readClipboardText() {
  let text = '';
  try {
    text = clipboard.readText();
  } catch (err) {
    logDiag('clipboard readText threw: ' + (err && err.message));
  }
  if (!text) {
    try {
      text = clipboard.read('CF_UNICODETEXT') || '';
    } catch (_) {}
  }
  if (!text) {
    await new Promise((r) => setTimeout(r, 150));
    try {
      text = clipboard.readText();
    } catch (_) {}
  }
  return text || '';
}

async function quickCapture(textOverride) {
  try {
    const source =
      textOverride !== undefined ? String(textOverride) : await readClipboardText();
    const formats = (() => {
      try {
        return JSON.stringify(clipboard.availableFormats());
      } catch (_) {
        return 'unavailable';
      }
    })();
    const raw = extractUrl(source);
    if (!raw) {
      logDiag('capture miss — formats=' + formats + ' textLen=' + (source || '').length);
      notify('LinkMAX', 'No link found in the clipboard — copy a URL first, then press ' + (activeHotkeyDisplay || 'the hotkey') + '.');
      return;
    }
    const url = normalizeUrlMain(raw);
    const host = hostMain(url);
    if (!host) {
      logDiag('capture invalid url: ' + raw.slice(0, 200));
      notify('LinkMAX', 'No valid link found in the clipboard.');
      return;
    }
    const base = host.split('.')[0];
    const name = base.charAt(0).toUpperCase() + base.slice(1);

    const data = await loadData();
    const key = url.toLowerCase().replace(/\/+$/, '');
    const dup = data.links.find((l) => String(l.url || '').toLowerCase().replace(/\/+$/, '') === key);
    if (dup) {
      logDiag('capture duplicate: ' + url);
      notify('LinkMAX', 'Already saved: ' + (dup.name || host));
      return;
    }

    data.links.push({
      id: uid('lnk'),
      name,
      url,
      categoryId: null,
      favicon: '',
      createdAt: Date.now(),
      pinned: false
    });
    await saveData(data);
    logDiag('capture saved: ' + url);
    notify('LinkMAX', 'Link saved: ' + name + ' (Uncategorized)');
    if (mainWindow && !mainWindow.isDestroyed()) {
      mainWindow.webContents.send('data:external-update');
    }
  } catch (err) {
    logDiag('capture error: ' + (err && err.stack ? err.stack.split('\n')[0] : err));
  }
}

function backupData() {
  try {
    const src = dataFile();
    if (!fs.existsSync(src)) return;
    const dir = path.join(app.getPath('userData'), 'backups');
    fs.mkdirSync(dir, { recursive: true });
    const stamp = new Date().toISOString().replace(/[:.]/g, '-').slice(0, 19);
    fs.copyFileSync(src, path.join(dir, 'linkmax-backup-' + stamp + '.json'));
    const files = fs.readdirSync(dir).filter((f) => f.startsWith('linkmax-backup-')).sort();
    while (files.length > 5) fs.unlinkSync(path.join(dir, files.shift()));
  } catch (_) {}
}

function showMainWindow() {
  if (!mainWindow || mainWindow.isDestroyed()) {
    createWindow();
    return;
  }
  if (mainWindow.isMinimized()) mainWindow.restore();
  mainWindow.show();
  mainWindow.focus();
}

function pickHotkey() {
  const candidates = [
    { canonical: 'CommandOrControl+Shift+L', display: 'Ctrl+Shift+L' },
    { canonical: 'CommandOrControl+Alt+L', display: 'Ctrl+Alt+L' },
    { canonical: 'CommandOrControl+Shift+K', display: 'Ctrl+Shift+K' }
  ];
  for (const c of candidates) {
    try {
      if (globalShortcut.register(c.canonical, () => quickCapture())) {
        activeHotkey = c.canonical;
        activeHotkeyDisplay = c.display;
        logDiag('hotkey registered: ' + c.display);
        return;
      }
    } catch (err) {
      logDiag('hotkey register threw for ' + c.display + ': ' + (err && err.message));
    }
  }
  logDiag('hotkey registration failed — all candidates taken');
}

function setupTray() {
  try {
    tray = new Tray(TRAY_ICON);
    const captureLabel = 'Quick Capture from Clipboard' + (activeHotkeyDisplay ? '  (' + activeHotkeyDisplay + ')' : '');
    tray.setToolTip('LinkMAX' + (activeHotkeyDisplay ? ' — Quick Capture: ' + activeHotkeyDisplay : ''));
    const menu = Menu.buildFromTemplate([
      { label: 'Open LinkMAX', click: () => showMainWindow() },
      { label: captureLabel, click: () => quickCapture() },
      { type: 'separator' },
      {
        label: 'Quit LinkMAX',
        click: () => {
          isQuitting = true;
          app.quit();
        }
      }
    ]);
    tray.setContextMenu(menu);
    tray.on('click', () => showMainWindow());
    tray.on('double-click', () => showMainWindow());
  } catch (err) {
    logDiag('tray setup failed: ' + (err && err.message));
    tray = null;
  }
}

function registerIpc() {
  ipcMain.handle('data:load', () => loadData());
  ipcMain.handle('data:save', (_e, data) => saveData(data));

  ipcMain.handle('link:open', (_e, url) => {
    try {
      const u = new URL(url);
      if (u.protocol === 'http:' || u.protocol === 'https:') {
        return shell.openExternal(u.toString()).then(() => true);
      }
      return false;
    } catch (_) {
      return false;
    }
  });

  ipcMain.handle('dialog:import', async () => {
    const res = await dialog.showOpenDialog(mainWindow, {
      title: 'Import links',
      properties: ['openFile'],
      filters: [
        { name: 'Bookmarks & JSON', extensions: ['json', 'html', 'htm'] },
        { name: 'All Files', extensions: ['*'] }
      ]
    });
    if (res.canceled || !res.filePaths[0]) return { ok: false };
    const p = res.filePaths[0];
    try {
      const content = await fsp.readFile(p, 'utf8');
      return { ok: true, path: p, name: path.basename(p), content };
    } catch (err) {
      return { ok: false, error: 'Could not read file: ' + err.message };
    }
  });

  ipcMain.handle('dialog:export', async (_e, opts) => {
    const o = opts || {};
    const res = await dialog.showSaveDialog(mainWindow, {
      title: 'Export links',
      defaultPath: o.defaultName || 'linkmax-export.json',
      filters: o.filters || [{ name: 'JSON', extensions: ['json'] }]
    });
    if (res.canceled || !res.filePath) return { ok: false };
    try {
      await fsp.writeFile(res.filePath, o.content || '', 'utf8');
      return { ok: true, path: res.filePath };
    } catch (err) {
      return { ok: false, error: 'Could not write file: ' + err.message };
    }
  });

  ipcMain.handle('favicon:fetch', (_e, url) => {
    if (typeof url !== 'string') return Promise.resolve(null);
    if (faviconInflight.has(url)) return faviconInflight.get(url);
    const p = fetchFavicon(url).finally(() => faviconInflight.delete(url));
    faviconInflight.set(url, p);
    return p;
  });

  ipcMain.handle('theme:overlay', (_e, theme) => {
    try {
      if (mainWindow) {
        mainWindow.setTitleBarOverlay(
          theme === 'dark'
            ? { height: 44, color: '#12161C', symbolColor: '#B6C1CC' }
            : { height: 44, color: '#F4F6F8', symbolColor: '#475467' }
        );
      }
      return true;
    } catch (_) {
      return false;
    }
  });

  ipcMain.handle('hotkey:get', () => activeHotkeyDisplay);
}

function readThemeSync() {
  try {
    const raw = fs.readFileSync(dataFile(), 'utf8');
    const data = JSON.parse(raw);
    return data && data.settings && data.settings.theme === 'dark' ? 'dark' : 'light';
  } catch (_) {
    return 'light';
  }
}

function createWindow() {
  const theme = readThemeSync();
  mainWindow = new BrowserWindow({
    width: 1200,
    height: 800,
    minWidth: 960,
    minHeight: 620,
    show: false,
    backgroundColor: theme === 'dark' ? '#12161C' : '#F4F6F8',
    titleBarStyle: 'hidden',
    titleBarOverlay:
      theme === 'dark'
        ? { height: 44, color: '#12161C', symbolColor: '#B6C1CC' }
        : { height: 44, color: '#F4F6F8', symbolColor: '#475467' },
    icon: path.join(__dirname, 'build', 'icon.ico'),
    webPreferences: {
      preload: path.join(__dirname, 'preload.js'),
      contextIsolation: true,
      nodeIntegration: false,
      spellcheck: false
    }
  });

  mainWindow.loadFile(path.join(__dirname, 'renderer', 'index.html'));
  mainWindow.once('ready-to-show', () => {
    if (!TEST_MODE) mainWindow.show();
  });

  mainWindow.on('close', (e) => {
    if (!isQuitting && tray && !TEST_MODE) {
      e.preventDefault();
      mainWindow.hide();
      if (!trayHintShown && tray) {
        trayHintShown = true;
        try {
          tray.displayBalloon({
            title: 'LinkMAX is still running',
            content:
              'Click the tray icon to reopen.' +
              (activeHotkeyDisplay ? ' Press ' + activeHotkeyDisplay + ' to save any copied URL.' : '')
          });
        } catch (_) {}
      }
    }
  });

  if (process.env.SMOKE_TEST) {
    mainWindow.webContents.on('console-message', (event, level, message) => {
      const msg = typeof message === 'string' ? message : (event && event.message) || '';
      console.log('[renderer]', msg);
    });
    mainWindow.webContents.on('render-process-gone', (_e, details) => {
      console.error('RENDERER_GONE', details && details.reason);
      app.exit(1);
    });
    setTimeout(() => {
      console.log('SMOKE_OK');
      app.quit();
    }, 3000);
  }

  mainWindow.on('closed', () => {
    mainWindow = null;
  });
}

app.on('second-instance', () => {
  showMainWindow();
});

app.whenReady().then(() => {
  app.setAppUserModelId('com.linkmax.app');
  Menu.setApplicationMenu(null);
  registerIpc();
  createWindow();

  if (!process.env.SMOKE_TEST) {
    setupTray();
    pickHotkey();
  }

  if (process.env.LINKMAX_REAL_TEST === '1') {
    setTimeout(async () => {
      await quickCapture(process.env.LINKMAX_TEST_URL);
      setTimeout(() => app.quit(), 600);
    }, 1500);
  }

  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) createWindow();
  });
});

app.on('before-quit', () => {
  isQuitting = true;
  try {
    globalShortcut.unregisterAll();
  } catch (_) {}
  try {
    if (tray) {
      tray.destroy();
      tray = null;
    }
  } catch (_) {}
  backupData();
});

app.on('window-all-closed', () => {
  app.quit();
});

process.on('unhandledRejection', (err) => {
  console.error('Unhandled rejection:', err);
});
