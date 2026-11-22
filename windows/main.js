// Darkroom for Windows: an Electron shell around darkroom.html.
// It mirrors the macOS app: the page is served through the darkroom:// scheme, which also serves
// photos the user opens (only those files), and the page talks to this process through the same
// window.webkit.messageHandlers.darkroom bridge the Mac app provides.
const { app, BrowserWindow, ipcMain, dialog, protocol, net, shell, Menu } = require('electron');
const path = require('path');
const fs = require('fs');
const crypto = require('crypto');
const { pathToFileURL } = require('url');

const SCHEME = 'darkroom';
const APP_DIR = path.join(__dirname, 'app');
const PHOTO_EXT = ['jpg', 'jpeg', 'png', 'webp', 'cr2', 'cube', 'darkroom'];
const REPO = 'https://github.com/hmimiaymane-scarface/darkroom-film-looks';

protocol.registerSchemesAsPrivileged([
  { scheme: SCHEME, privileges: { standard: true, secure: true, supportFetchAPI: true, stream: true } },
]);

if (process.env.DARKROOM_SELFTEST) app.setPath('userData', path.join(require('os').tmpdir(), 'darkroom-selftest'));
if (!app.requestSingleInstanceLock()) { app.quit(); }

const allowed = new Map();
let win = null;
let pageReady = false;
let pending = [];

const dataDir = () => app.getPath('userData');
const dataFile = (name) => path.join(dataDir(), name);
const readText = (name) => { try { return fs.readFileSync(dataFile(name), 'utf8'); } catch { return null; } };
const writeText = (name, text) => { fs.mkdirSync(dataDir(), { recursive: true }); fs.writeFileSync(dataFile(name), text, 'utf8'); };
const prefs = () => { try { return JSON.parse(readText('prefs.json')) || {}; } catch { return {}; } };

function register(file) {
  const id = crypto.randomUUID();
  allowed.set(id, file);
  return `${SCHEME}://app/f/${id}/${encodeURIComponent(path.basename(file))}`;
}

function filesFromArgs(argv) {
  return argv.filter((a) => !a.startsWith('-') && PHOTO_EXT.includes(path.extname(a).slice(1).toLowerCase()))
    .filter((a) => { try { return fs.statSync(a).isFile(); } catch { return false; } });
}

function send(files) {
  if (!files.length) return;
  if (!pageReady || !win) { pending.push(...files); return; }
  const items = files.map((f) => ({ url: register(f), name: path.basename(f), modified: Math.round(fs.statSync(f).mtimeMs) }));
  win.webContents.executeJavaScript(`addRemote(${JSON.stringify(items)})`).catch(() => {});
}

async function addPhotos() {
  const r = await dialog.showOpenDialog(win, {
    title: 'Choose photos or LUTs',
    properties: ['openFile', 'multiSelections'],
    filters: [{ name: 'Photos and LUTs', extensions: PHOTO_EXT }],
  });
  if (!r.canceled) send(r.filePaths);
}

const js = (code) => () => win && win.webContents.executeJavaScript(code).catch(() => {});

function buildMenu() {
  // Shortcuts are handled by the page itself; the menu only shows them (registerAccelerator: false).
  const shown = (accel) => ({ accelerator: accel, registerAccelerator: false });
  Menu.setApplicationMenu(Menu.buildFromTemplate([
    { label: 'File', submenu: [
      { label: 'Add Photos or LUTs…', click: addPhotos, ...shown('Ctrl+O') },
      { label: 'Export…', click: js('openExport()'), ...shown('Ctrl+E') },
      { type: 'separator' },
      { role: 'quit', label: 'Exit' },
    ] },
    { label: 'Edit', submenu: [
      { label: 'Undo', click: js('undo()'), ...shown('Ctrl+Z') },
      { label: 'Redo', click: js('redo()'), ...shown('Ctrl+Shift+Z') },
    ] },
    { label: 'View', submenu: [{ role: 'togglefullscreen' }, { role: 'resetZoom' }, { role: 'zoomIn' }, { role: 'zoomOut' }] },
    { label: 'Help', submenu: [
      { label: 'Keyboard Shortcuts', click: js("document.getElementById('helpDlg').showModal()") },
      { label: 'Darkroom on GitHub', click: () => shell.openExternal(REPO) },
    ] },
  ]));
}

function createWindow() {
  win = new BrowserWindow({
    width: 1440, height: 900, minWidth: 980, minHeight: 620,
    title: 'Darkroom', backgroundColor: '#0e0e10', show: false,
    icon: path.join(__dirname, 'icon.png'),
    webPreferences: { preload: path.join(__dirname, 'preload.js'), contextIsolation: true, sandbox: true, spellcheck: false },
  });
  win.once('ready-to-show', () => { win.maximize(); win.show(); });
  win.webContents.on('will-navigate', (e, url) => { if (!url.startsWith(`${SCHEME}://`)) e.preventDefault(); });
  win.webContents.setWindowOpenHandler(({ url }) => { if (url.startsWith('https://')) shell.openExternal(url); return { action: 'deny' }; });
  win.webContents.on('render-process-gone', () => { pageReady = false; win.reload(); });
  win.on('closed', () => { win = null; });
  win.loadURL(`${SCHEME}://app/darkroom.html`);
}

ipcMain.handle('darkroom', async (_e, msg) => {
  switch (msg && msg.cmd) {
    case 'ready': {
      pageReady = true;
      const q = pending; pending = []; send(q);
      return true;
    }
    case 'loadState': return readText('state.json');
    case 'saveState': writeText('state.json', String(msg.data)); return true;
    case 'loadLuts': return readText('luts.json');
    case 'saveLuts': writeText('luts.json', String(msg.data)); return true;
    case 'pickFolder': {
      const r = await dialog.showOpenDialog(win, {
        title: msg.message || 'Choose where to save your edited photos',
        buttonLabel: 'Export Here',
        defaultPath: prefs().exportDir || app.getPath('pictures'),
        properties: ['openDirectory', 'createDirectory'],
      });
      if (r.canceled || !r.filePaths[0]) return null;
      writeText('prefs.json', JSON.stringify({ ...prefs(), exportDir: r.filePaths[0] }));
      return r.filePaths[0];
    }
    case 'save': {
      const dir = String(msg.dir);
      const name = path.basename(String(msg.name));
      const ext = path.extname(name) || '.jpg';
      const base = path.basename(name, ext);
      let target = path.join(dir, name);
      for (let i = 2; fs.existsSync(target); i++) target = path.join(dir, `${base}-${i}${ext}`);
      fs.writeFileSync(target, Buffer.from(String(msg.data), 'base64'));
      return path.basename(target);
    }
    case 'reveal': await shell.openPath(String(msg.dir)); return true;
    default: throw new Error('unknown command');
  }
});

app.on('second-instance', (_e, argv) => {
  if (win) { if (win.isMinimized()) win.restore(); win.focus(); }
  send(filesFromArgs(argv.slice(1)));
});

app.whenReady().then(() => {
  protocol.handle(SCHEME, (req) => {
    const parts = new URL(req.url).pathname.split('/').filter(Boolean).map(decodeURIComponent);
    let file = null;
    if (parts[0] === 'f' && parts[1]) file = allowed.get(parts[1]) || null;
    else {
      const name = parts.length ? parts.join('/') : 'darkroom.html';
      if (!name.includes('..')) file = path.join(APP_DIR, name);
    }
    if (!file || !fs.existsSync(file)) return new Response('Not found', { status: 404 });
    return net.fetch(pathToFileURL(file).toString());
  });
  buildMenu();
  createWindow();
  pending.push(...filesFromArgs(process.argv.slice(app.isPackaged ? 1 : 2)));
  if (process.env.DARKROOM_SELFTEST) require('./selftest')(win, register);
});

app.on('window-all-closed', () => app.quit());
