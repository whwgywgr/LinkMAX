# LinkMAX

Clean and simple link manager for **Windows 10/11**. Save your favorite links, organize them into categories, and open them in your browser with one click.

![LinkMAX](build/icon-256.png)

## Features

- **Manage links** — add, edit, and delete links. Each link has a favicon, name, and URL. Favicons are fetched automatically and cached locally.
- **Open in browser** — click any link to open it in your default browser.
- **Quick Capture (Ctrl+Shift+L)** — copy any URL anywhere, press the global hotkey, and LinkMAX saves it instantly (auto-named, duplicate-safe) — even while the app is closed. A notification confirms each capture.
- **System tray** — closing the window keeps LinkMAX running in the tray; click the tray icon to reopen, or use the tray menu (Open / Quick Capture / Quit).
- **Categories & drag & drop** — group links into categories with colored dots; drag any link onto a category in the sidebar to move it. Links without a category go to *Uncategorized*.
- **Pin / Favorite** — pin links to keep them at the top, in any sort order.
- **Sort** — Name A→Z / Z→A / Newest first / Oldest first.
- **Duplicate warning** — adding a URL that is already saved shows which category it lives in.
- **Grid or List view** — switch layouts anytime; your choice is remembered.
- **Dark mode** — toggle between light and dark themes with the moon/sun button in the toolbar; the choice is saved and the Windows title bar follows the theme.
- **Search** — instantly filter links by name or URL (`Ctrl+F`).
- **Auto-backup** — every time the app closes, the data file is copied to `%APPDATA%/LinkMAX/backups` (last 5 kept).
- **Local storage** — data is saved automatically to a JSON file on your PC (`%APPDATA%/LinkMAX/linkmax-data.json`).
- **Import / Export**
  - Export as **JSON** (full backup with categories) or **HTML bookmarks** (importable into Chrome, Edge, Firefox...).
  - Import from **JSON** or from any browser's exported **bookmarks HTML** file (folders become categories). Choose *Merge* or *Replace all* on import.
- **Extras** — right-click a link for Open / Copy URL / Pin / Edit / Delete.

## Design

Clean, minimal UI with solid colors only (no gradients): white sidebar, soft gray canvas, blue accent, Segoe UI typography, native Windows 11 window controls.

## Installer (EXE)

The ready-made installer is at:

```
dist/LinkMAX Setup 1.1.1.exe
```

Run it, choose the install folder (desktop & Start Menu shortcuts are created automatically), and LinkMAX is installed. Uninstall anytime from Windows *Settings → Apps*.

## Development

Requirements: [Node.js](https://nodejs.org) 18+ and npm.

```bash
npm install        # install dependencies
npm start          # run the app in dev mode
npm run icon       # regenerate build/icon.ico + PNGs from the inline SVG
npm run dist       # build the Windows NSIS installer into dist/
```

## Project structure

```
LinkMAX/
├── main.js              # Electron main process (window, IPC, data file, favicon cache)
├── preload.js           # secure bridge between main and renderer
├── renderer/
│   ├── index.html       # UI layout
│   ├── styles.css       # clean solid-color design
│   └── app.js           # app logic (links, categories, views, import/export)
├── scripts/make-icon.js # generates the app icon
├── build/               # icon.ico / icon.png used by the app and the installer
└── dist/                # build output (LinkMAX Setup 1.1.1.exe)
```

## Notes

- All data stays on your PC. Nothing is sent anywhere; favicons are downloaded from Google's/DuckDuckGo's public favicon services and cached locally.
- The first launch seeds a few example links so the app doesn't feel empty — just delete them if you don't want them.
- Closing the window minimizes LinkMAX to the system tray; use the tray menu → *Quit LinkMAX* to exit fully.
- If `Ctrl+Shift+L` is already taken by another app, LinkMAX automatically falls back to `Ctrl+Alt+L`, then `Ctrl+Shift+K`. The active hotkey is shown in the tray tooltip and as a tip inside the Add Link dialog.
- Quick Capture attempts are logged to `%APPDATA%/LinkMAX/linkmax-log.txt` for easy troubleshooting.
