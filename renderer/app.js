/* ============ LinkMAX renderer ============ */
'use strict';

/* ---------- Icons (static SVG, safe to inline) ---------- */

const I = {
  link: '<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M10 13a5 5 0 0 0 7.54.54l3-3a5 5 0 0 0-7.07-7.07l-1.72 1.71"/><path d="M14 11a5 5 0 0 0-7.54-.54l-3 3a5 5 0 0 0 7.07 7.07l1.71-1.71"/></svg>',
  linkLg: '<svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M10 13a5 5 0 0 0 7.54.54l3-3a5 5 0 0 0-7.07-7.07l-1.72 1.71"/><path d="M14 11a5 5 0 0 0-7.54-.54l-3 3a5 5 0 0 0 7.07 7.07l1.71-1.71"/></svg>',
  folder: '<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round"><path d="M22 19a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h5l2 3h9a2 2 0 0 1 2 2z"/></svg>',
  inbox: '<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round"><polyline points="22 12 16 12 14 15 10 15 8 12 2 12"/><path d="M5.45 5.11 2 12v6a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2v-6l-3.45-6.89A2 2 0 0 0 16.76 4H7.24a2 2 0 0 0-1.79 1.11z"/></svg>',
  slash: '<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.9" stroke-linecap="round"><circle cx="12" cy="12" r="9"/><path d="M5.8 5.8 18.2 18.2"/></svg>',
  plus: '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round"><path d="M12 5v14M5 12h14"/></svg>',
  plusSm: '<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round"><path d="M12 5v14M5 12h14"/></svg>',
  search: '<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><circle cx="11" cy="11" r="7"/><path d="m20 20-3.5-3.5"/></svg>',
  grid: '<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><rect x="3" y="3" width="7.5" height="7.5" rx="1.5"/><rect x="13.5" y="3" width="7.5" height="7.5" rx="1.5"/><rect x="3" y="13.5" width="7.5" height="7.5" rx="1.5"/><rect x="13.5" y="13.5" width="7.5" height="7.5" rx="1.5"/></svg>',
  list: '<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M8 6h13M8 12h13M8 18h13"/><path d="M3.5 6h.01M3.5 12h.01M3.5 18h.01"/></svg>',
  edit: '<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M17 3a2.8 2.8 0 1 1 4 4L7.5 20.5 2 22l1.5-5.5Z"/></svg>',
  trash: '<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 6h18"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6"/><path d="M8 6V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/></svg>',
  copy: '<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="9" y="9" width="13" height="13" rx="2"/><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"/></svg>',
  external: '<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6"/><path d="M15 3h6v6"/><path d="M10 14 21 3"/></svg>',
  open: '<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6"/><path d="M15 3h6v6"/><path d="M10 14 21 3"/></svg>',
  import_: '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><path d="m7 10 5 5 5-5"/><path d="M12 15V3"/></svg>',
  export_: '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><path d="m17 8-5-5-5 5"/><path d="M12 3v12"/></svg>',
  json: '<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><path d="M14 2v6h6"/><path d="M10 12a1.5 1.5 0 1 0-1.4 2.1A1.5 1.5 0 1 1 10 17"/></svg>',
  html: '<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><path d="M14 2v6h6"/><path d="m9 13-2 2.5L9 18"/><path d="m15 13 2 2.5L15 18"/></svg>',
  globe: '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="9"/><path d="M3 12h18"/><path d="M12 3a15 15 0 0 1 0 18 15 15 0 0 1 0-18z"/></svg>',
  moon: '<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"/></svg>',
  sun: '<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="4.5"/><path d="M12 2v2.5M12 19.5V22M4.9 4.9l1.8 1.8M17.3 17.3l1.8 1.8M2 12h2.5M19.5 12H22M4.9 19.1l1.8-1.8M17.3 6.7l1.8-1.8"/></svg>',
  pin: '<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 17v5"/><path d="M9 10.76a2 2 0 0 1-1.11 1.79l-1.78.9A2 2 0 0 0 5 15.24V16a1 1 0 0 0 1 1h12a1 1 0 0 0 1-1v-.76a2 2 0 0 0-1.11-1.79l-1.78-.9A2 2 0 0 1 15 10.76V6h1a2 2 0 0 0 0-4H8a2 2 0 0 0 0 4h1z"/></svg>',
  pinFilled: '<svg width="13" height="13" viewBox="0 0 24 24" fill="currentColor" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 17v5"/><path d="M9 10.76a2 2 0 0 1-1.11 1.79l-1.78.9A2 2 0 0 0 5 15.24V16a1 1 0 0 0 1 1h12a1 1 0 0 0 1-1v-.76a2 2 0 0 0-1.11-1.79l-1.78-.9A2 2 0 0 1 15 10.76V6h1a2 2 0 0 0 0-4H8a2 2 0 0 0 0 4h1z"/></svg>'
};

const PALETTE = ['#2563EB', '#7C3AED', '#DB2777', '#EA580C', '#16A34A', '#0891B2', '#CA8A04', '#E11D48', '#0D9488', '#6366F1'];

/* Sidebar brand mark — mini version of the app icon (no sparkles at this size). */
const BRAND_ICON = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256" width="24" height="24"><rect width="256" height="256" rx="62" fill="#8B5CF6"/><g transform="translate(128 132) rotate(-45)"><rect x="-70" y="-40" width="140" height="80" rx="40" fill="none" stroke="#FFFFFF" stroke-width="18"/></g><circle cx="112" cy="127" r="6" fill="#3730A3"/><circle cx="144" cy="127" r="6" fill="#3730A3"/><path d="M118 140 Q128 149 138 140" stroke="#3730A3" stroke-width="5" fill="none" stroke-linecap="round"/><ellipse cx="110" cy="137" rx="6.5" ry="4.5" fill="#FFB3C7"/><ellipse cx="146" cy="137" rx="6.5" ry="4.5" fill="#FFB3C7"/></svg>';

/* ---------- DOM helpers ---------- */

const $ = (sel, root) => (root || document).querySelector(sel);

function el(tag, attrs, ...children) {
  const node = document.createElement(tag);
  if (attrs) {
    for (const [k, v] of Object.entries(attrs)) {
      if (k === 'class') node.className = v;
      else if (k === 'text') node.textContent = v;
      else if (k === 'html') node.innerHTML = v;
      else if (k.startsWith('on')) node.addEventListener(k.slice(2), v);
      else if (v !== null && v !== undefined && v !== false) node.setAttribute(k, v === true ? '' : v);
    }
  }
  for (const child of children) {
    if (child === null || child === undefined) continue;
    node.append(child.nodeType ? child : document.createTextNode(String(child)));
  }
  return node;
}

function svgWrap(markup, size) {
  const span = document.createElement('span');
  span.innerHTML = markup;
  return span;
}

function hashColor(str) {
  let h = 7;
  for (let i = 0; i < str.length; i++) h = ((h * 31) + str.charCodeAt(i)) >>> 0;
  return PALETTE[h % PALETTE.length];
}

/* ---------- Bridge (Electron IPC or browser fallback for testing) ---------- */

function createBrowserBridge() {
  const KEY = 'linkmax-data';
  return {
    isElectron: false,
    async load() {
      try { return JSON.parse(localStorage.getItem(KEY)); } catch (_) { return null; }
    },
    async save(data) {
      try { localStorage.setItem(KEY, JSON.stringify(data)); } catch (_) {}
      return true;
    },
    async openLink(url) { window.open(url, '_blank', 'noopener'); return true; },
    async pickImport() {
      return new Promise((resolve) => {
        const input = document.createElement('input');
        input.type = 'file';
        input.accept = '.json,.html,.htm';
        input.onchange = async () => {
          const f = input.files && input.files[0];
          if (!f) { resolve({ ok: false }); return; }
          try {
            resolve({ ok: true, name: f.name, content: await f.text() });
          } catch (err) {
            resolve({ ok: false, error: err.message });
          }
        };
        input.click();
      });
    },
    async pickExport(opts) {
      const blob = new Blob([opts.content || ''], { type: 'text/plain' });
      const a = document.createElement('a');
      a.href = URL.createObjectURL(blob);
      a.download = opts.defaultName || 'linkmax-export.json';
      a.click();
      setTimeout(() => URL.revokeObjectURL(a.href), 2000);
      return { ok: true, path: a.download };
    },
    async fetchFavicon() { return null; },
    async getHotkey() { return null; }
  };
}

const bridge = window.linkmax || createBrowserBridge();

/* ---------- State ---------- */

let state = { version: 1, settings: { view: 'grid', theme: 'light', sortMode: 'name' }, categories: [], links: [] };
let ui = {
  currentCategory: 'all', // 'all' | 'none' | category id
  search: '',
  view: 'grid',
  theme: 'light',
  sortMode: 'name'
};

/* Apply saved theme before first paint to avoid a light flash. */
(function earlyTheme() {
  try {
    const saved = localStorage.getItem('linkmax-theme');
    if (saved === 'dark' || saved === 'light') {
      document.documentElement.dataset.theme = saved;
      ui.theme = saved;
    }
  } catch (_) {}
})();

function applyTheme(theme) {
  ui.theme = theme === 'dark' ? 'dark' : 'light';
  document.documentElement.dataset.theme = ui.theme;
  const btn = $('#themeToggle');
  if (btn) {
    btn.innerHTML = ui.theme === 'dark' ? I.sun : I.moon;
    btn.title = ui.theme === 'dark' ? 'Switch to light mode' : 'Switch to dark mode';
  }
  try {
    localStorage.setItem('linkmax-theme', ui.theme);
  } catch (_) {}
  if (bridge.isElectron && typeof bridge.setThemeOverlay === 'function') {
    bridge.setThemeOverlay(ui.theme);
  }
}

let editingLink = null;
let editingCategory = null;
let pendingImport = null;
let confirmHandler = null;

function uid(prefix) {
  return prefix + '_' + Date.now().toString(36) + Math.random().toString(36).slice(2, 8);
}

function persist() {
  state.settings.view = ui.view;
  state.settings.theme = ui.theme;
  state.settings.sortMode = ui.sortMode;
  bridge.save(state);
}

function adoptState(loaded) {
  state = {
    version: 1,
    settings: {
      view: loaded.settings && loaded.settings.view === 'list' ? 'list' : 'grid',
      theme: loaded.settings && loaded.settings.theme === 'dark' ? 'dark' : 'light',
      sortMode:
        loaded.settings && ['name', 'nameDesc', 'newest', 'oldest'].includes(loaded.settings.sortMode)
          ? loaded.settings.sortMode
          : 'name'
    },
    categories: Array.isArray(loaded.categories)
      ? loaded.categories.filter((c) => c && c.id && c.name)
      : [],
    links: Array.isArray(loaded.links)
      ? loaded.links
          .filter((l) => l && l.id && l.url)
          .map((l) => ({ ...l, pinned: l.pinned === true }))
      : []
  };
}

function nextColor() {
  return PALETTE[state.categories.length % PALETTE.length];
}

function findCategory(id) {
  return state.categories.find((c) => c.id === id) || null;
}

function categoryOf(link) {
  return link.categoryId ? findCategory(link.categoryId) : null;
}

/* ---------- URL helpers ---------- */

function normalizeUrl(u) {
  const s = (u || '').trim();
  if (!s) return '';
  if (/^[a-z][a-z0-9+.-]*:/i.test(s)) return s;
  return 'https://' + s;
}

function hostOf(u) {
  try {
    return new URL(normalizeUrl(u)).hostname.replace(/^www\./, '');
  } catch (_) {
    return '';
  }
}

function deriveName(u) {
  const host = hostOf(u);
  if (!host) return '';
  const parts = host.split('.');
  const base = parts.length > 2 && parts[0] === 'www' ? parts.slice(1).join('.') : host;
  const core = base.split('.')[0];
  return core.charAt(0).toUpperCase() + core.slice(1);
}

function displayUrl(u) {
  try {
    const url = new URL(normalizeUrl(u));
    return (url.hostname.replace(/^www\./, '') + (url.pathname === '/' ? '' : url.pathname)).replace(/\/$/, '');
  } catch (_) {
    return u;
  }
}

function fileUrl(p) {
  let norm = String(p).replace(/\\/g, '/');
  if (!norm.startsWith('/')) norm = '/' + norm;
  return 'file://' + norm;
}

function googleFavicon(u) {
  const host = hostOf(u);
  return 'https://www.google.com/s2/favicons?sz=64&domain=' + encodeURIComponent(host);
}

function faviconSrc(link) {
  return link.favicon ? fileUrl(link.favicon) : googleFavicon(link.url);
}

/* ---------- Favicon fetching queue ---------- */

const faviconQueue = [];
let activeFetches = 0;

function queueFavicon(link) {
  if (link.favicon) return;
  faviconQueue.push(link);
  pumpFaviconQueue();
}

async function pumpFaviconQueue() {
  if (!bridge.isElectron) return;
  while (faviconQueue.length && activeFetches < 6) {
    const link = faviconQueue.shift();
    if (link.favicon) { continue; }
    activeFetches++;
    try {
      const p = await bridge.fetchFavicon(link.url);
      if (p && !link.favicon) {
        link.favicon = p;
        persist();
        renderLinks();
      }
    } catch (_) {
    } finally {
      activeFetches--;
    }
  }
}

/* ---------- Toast ---------- */

function toast(msg) {
  const holder = $('#toasts');
  while (holder.children.length >= 3) holder.firstChild.remove();
  const t = el('div', { class: 'toast', text: msg });
  holder.appendChild(t);
  setTimeout(() => {
    t.classList.add('out');
    setTimeout(() => t.remove(), 220);
  }, 2400);
}

/* ---------- Modal helpers ---------- */

function openModal(id) {
  const m = document.getElementById(id);
  m.hidden = false;
  const first = m.querySelector('input:not([type=radio]), select');
  if (first) setTimeout(() => first.focus(), 30);
}

function closeModal(id) {
  document.getElementById(id).hidden = true;
}

function closeAllModals() {
  document.querySelectorAll('.modal-backdrop').forEach((m) => (m.hidden = true));
  hideMenus();
}

function closeTopModal() {
  const open = [...document.querySelectorAll('.modal-backdrop')].filter((m) => !m.hidden);
  if (open.length) {
    open[open.length - 1].hidden = true;
    return true;
  }
  return false;
}

function askConfirm(title, message, confirmLabel, onConfirm) {
  $('#confirmTitle').textContent = title;
  $('#confirmMessage').textContent = message;
  $('#confirmBtn').textContent = confirmLabel;
  confirmHandler = onConfirm;
  openModal('modalConfirm');
}

/* ---------- Menus ---------- */

function hideMenus() {
  $('#exportMenu').hidden = true;
  $('#ctxMenu').hidden = true;
}

function positionMenu(menu, x, y) {
  menu.hidden = false;
  const r = menu.getBoundingClientRect();
  let px = x;
  let py = y;
  if (px + r.width > window.innerWidth - 8) px = window.innerWidth - r.width - 8;
  if (py + r.height > window.innerHeight - 8) py = y - r.height - (menu.id === 'ctxMenu' ? 4 : 0);
  if (py < 8) py = 8;
  menu.style.left = px + 'px';
  menu.style.top = py + 'px';
}

/* ---------- Rendering ---------- */

function renderAll() {
  renderSidebar();
  renderLinks();
}

function renderSidebar() {
  const linkCount = state.links.length;
  $('#navAllCount').textContent = linkCount;

  const list = $('#categoryList');
  list.replaceChildren();

  for (const cat of state.categories) {
    const count = state.links.filter((l) => l.categoryId === cat.id).length;
    const item = el(
      'button',
      {
        class: 'nav-item' + (ui.currentCategory === cat.id ? ' active' : ''),
        'data-cat': cat.id,
        onclick: () => selectCategory(cat.id)
      },
      el('span', { class: 'cat-dot' }),
      el('span', { class: 'grow', text: cat.name, title: cat.name }),
      el('span', { class: 'nav-count', text: String(count) }),
      el('button', {
        class: 'cat-edit',
        title: 'Edit category',
        html: I.edit,
        onclick: (e) => {
          e.stopPropagation();
          openCategoryModal(cat);
        }
      })
    );
    item.querySelector('.cat-dot').style.background = cat.color;
    attachDropTarget(item, cat.id);
    list.appendChild(item);
  }

  const hasUncategorized = state.links.some((l) => !l.categoryId || !findCategory(l.categoryId));
  $('#navNoneWrap').hidden = !hasUncategorized;
  if (hasUncategorized) {
    $('#navNoneCount').textContent = String(
      state.links.filter((l) => !l.categoryId || !findCategory(l.categoryId)).length
    );
  }

  document.querySelectorAll('.nav-item[data-cat="all"]').forEach((b) => {
    b.classList.toggle('active', ui.currentCategory === 'all');
  });
  document.querySelectorAll('.nav-item[data-cat="none"]').forEach((b) => {
    b.classList.toggle('active', ui.currentCategory === 'none');
  });
}

function selectCategory(id) {
  ui.currentCategory = id;
  ui.search = '';
  $('#searchInput').value = '';
  renderAll();
}

function currentCategoryName() {
  if (ui.currentCategory === 'all') return 'All Links';
  if (ui.currentCategory === 'none') return 'Uncategorized';
  const cat = findCategory(ui.currentCategory);
  return cat ? cat.name : 'All Links';
}

function visibleLinks() {
  const q = ui.search.trim().toLowerCase();
  let links = state.links.slice();

  if (q) {
    links = links.filter(
      (l) =>
        (l.name || '').toLowerCase().includes(q) ||
        (l.url || '').toLowerCase().includes(q) ||
        hostOf(l.url).includes(q)
    );
  } else if (ui.currentCategory === 'none') {
    links = links.filter((l) => !l.categoryId || !findCategory(l.categoryId));
  } else if (ui.currentCategory !== 'all') {
    links = links.filter((l) => l.categoryId === ui.currentCategory);
  }

  const byName = (a, b) => (a.name || '').localeCompare(b.name || '', undefined, { sensitivity: 'base' });
  links.sort((a, b) => {
    if (!!b.pinned !== !!a.pinned) return b.pinned ? 1 : -1;
    switch (ui.sortMode) {
      case 'nameDesc':
        return byName(b, a);
      case 'newest':
        return (b.createdAt || 0) - (a.createdAt || 0);
      case 'oldest':
        return (a.createdAt || 0) - (b.createdAt || 0);
      default:
        return byName(a, b);
    }
  });
  return links;
}

function faviconEl(link, size) {
  const img = el('img', {
    class: 'favicon',
    src: faviconSrc(link),
    alt: '',
    draggable: 'false',
    loading: 'lazy'
  });
  img.onerror = () => {
    const host = hostOf(link.url) || link.name || '?';
    const letter = (link.name || host || '?').trim().charAt(0).toUpperCase() || '?';
    const av = el('div', { class: 'avatar', text: letter, title: host });
    av.style.background = hashColor(host || link.name || 'x');
    img.replaceWith(av);
  };
  return img;
}

function togglePin(link) {
  link.pinned = !link.pinned;
  persist();
  renderLinks();
  toast(link.pinned ? 'Pinned to top' : 'Removed from pinned');
}

function moveLinkToCategory(linkId, categoryId) {
  const link = state.links.find((l) => l.id === linkId);
  if (!link) return;
  if ((link.categoryId || null) === (categoryId || null)) return;
  link.categoryId = categoryId;
  persist();
  renderAll();
  const cat = categoryId ? findCategory(categoryId) : null;
  toast(cat ? 'Moved to ' + cat.name : 'Moved to Uncategorized');
}

function attachDropTarget(btn, categoryId) {
  btn.addEventListener('dragover', (e) => {
    if (!document.body.classList.contains('dragging-link')) return;
    e.preventDefault();
    e.dataTransfer.dropEffect = 'move';
    btn.classList.add('drop-target');
  });
  btn.addEventListener('dragleave', () => btn.classList.remove('drop-target'));
  btn.addEventListener('drop', (e) => {
    e.preventDefault();
    btn.classList.remove('drop-target');
    const id = e.dataTransfer.getData('text/linkmax-link');
    if (id) moveLinkToCategory(id, categoryId);
  });
}

function handleDragStart(e, link) {
  e.dataTransfer.setData('text/linkmax-link', link.id);
  e.dataTransfer.effectAllowed = 'move';
  document.body.classList.add('dragging-link');
  e.currentTarget.classList.add('dragging');
}

function handleDragEnd(e) {
  document.body.classList.remove('dragging-link');
  e.currentTarget.classList.remove('dragging');
  document.querySelectorAll('.nav-item.drop-target').forEach((n) => n.classList.remove('drop-target'));
}

function actionButtons(link) {
  return el(
    'div',
    { class: 'card-actions' },
    el('button', {
      class: 'icon-btn' + (link.pinned ? ' pin-active' : ''),
      title: link.pinned ? 'Unpin' : 'Pin to top',
      html: link.pinned ? I.pinFilled : I.pin,
      onclick: (e) => {
        e.stopPropagation();
        togglePin(link);
      }
    }),
    el('button', {
      class: 'icon-btn',
      title: 'Edit',
      html: I.edit,
      onclick: (e) => {
        e.stopPropagation();
        openLinkModal(link);
      }
    }),
    el('button', {
      class: 'icon-btn danger',
      title: 'Delete',
      html: I.trash,
      onclick: (e) => {
        e.stopPropagation();
        confirmDeleteLink(link);
      }
    })
  );
}

function renderLinks() {
  const links = visibleLinks();
  const title = $('#listTitle');
  const chip = $('#listCount');
  const container = $('#linkContainer');

  if (ui.search.trim()) {
    title.textContent = 'Search results';
  } else {
    title.textContent = currentCategoryName();
  }
  chip.textContent = links.length + (links.length === 1 ? ' link' : ' links');

  document.querySelectorAll('.seg-btn').forEach((b) => {
    b.classList.toggle('active', b.dataset.view === ui.view);
  });

  container.replaceChildren();

  if (!links.length) {
    container.appendChild(emptyState());
    return;
  }

  if (ui.view === 'grid') {
    const grid = el('div', { class: 'link-grid' });
    for (const link of links) grid.appendChild(gridCard(link));
    container.appendChild(grid);
  } else {
    const listEl = el('div', { class: 'link-list' });
    for (const link of links) listEl.appendChild(listRow(link));
    container.appendChild(listEl);
  }
}

function emptyState() {
  const q = ui.search.trim();
  let heading;
  let sub;
  if (q) {
    heading = 'No results';
    sub = 'No links match "' + q + '". Try a different search.';
  } else if (ui.currentCategory === 'none') {
    heading = 'Nothing uncategorized';
    sub = 'Every link has a category. Nice and tidy.';
  } else if (state.links.length === 0) {
    heading = 'No links yet';
    sub = 'Save your first link so you can open it anytime.';
  } else {
    heading = 'No links here';
    sub = 'Add a link to this category or pick another one.';
  }
  const wrap = el(
    'div',
    { class: 'empty' },
    el('div', { class: 'empty-icon', html: I.linkLg }),
    el('h2', { text: heading }),
    el('p', { text: sub })
  );
  if (!q && state.links.length === 0) {
    wrap.appendChild(
      el(
        'button',
        { class: 'btn btn-primary', html: I.plusSm, onclick: () => openLinkModal(null) },
        ' Add Link'
      )
    );
  }
  return wrap;
}

function gridCard(link) {
  const cat = categoryOf(link);
  const card = el(
    'div',
    {
      class: 'card' + (link.pinned ? ' pinned' : ''),
      tabindex: '0',
      role: 'link',
      draggable: 'true',
      onclick: () => openLink(link),
      onkeydown: (e) => {
        if (e.key === 'Enter') openLink(link);
      },
      oncontextmenu: (e) => {
        e.preventDefault();
        showLinkContextMenu(e, link);
      },
      ondragstart: (e) => handleDragStart(e, link),
      ondragend: (e) => handleDragEnd(e)
    },
    faviconEl(link),
    el('div', { class: 'card-name', text: link.name || hostOf(link.url), title: link.name }),
    el('div', { class: 'card-url', text: displayUrl(link.url), title: displayUrl(link.url) })
  );
  card.appendChild(actionButtons(link));
  if (cat && ui.search.trim()) {
    card.appendChild(categoryChip(cat));
  }
  return card;
}

function listRow(link) {
  const cat = categoryOf(link);
  const row = el(
    'div',
    {
      class: 'row' + (link.pinned ? ' pinned' : ''),
      tabindex: '0',
      role: 'link',
      draggable: 'true',
      onclick: () => openLink(link),
      onkeydown: (e) => {
        if (e.key === 'Enter') openLink(link);
      },
      oncontextmenu: (e) => {
        e.preventDefault();
        showLinkContextMenu(e, link);
      },
      ondragstart: (e) => handleDragStart(e, link),
      ondragend: (e) => handleDragEnd(e)
    },
    faviconEl(link),
    el('div', { class: 'row-name', text: link.name || hostOf(link.url), title: link.name }),
    el('div', { class: 'row-url', text: displayUrl(link.url), title: displayUrl(link.url) })
  );
  if (cat) {
    const chipEl = el('div', { class: 'row-cat' }, el('span', { class: 'cat-dot' }), cat.name);
    chipEl.querySelector('.cat-dot').style.background = cat.color;
    row.appendChild(chipEl);
  }
  row.appendChild(actionButtons(link));
  return row;
}

function categoryChip(cat) {
  const chipEl = el(
    'div',
    { class: 'row-cat', style: 'margin-top:10px' },
    el('span', { class: 'cat-dot' }),
    cat.name
  );
  chipEl.querySelector('.cat-dot').style.background = cat.color;
  return chipEl;
}

function openLink(link) {
  const url = normalizeUrl(link.url);
  bridge.openLink(url).then((ok) => {
    if (!ok) toast('Could not open this link');
  });
}

/* ---------- Link modal ---------- */

function fillCategorySelect(select, selectedId) {
  select.replaceChildren();
  select.appendChild(el('option', { value: '', text: 'Uncategorized' }));
  for (const cat of state.categories) {
    select.appendChild(el('option', { value: cat.id, text: cat.name }));
  }
  select.value = selectedId || '';
}

function findDuplicate(url, excludeId) {
  const key = normalizeUrl(url).toLowerCase().replace(/\/+$/, '');
  if (!hostOf(url)) return null;
  return state.links.find(
    (l) => l.id !== excludeId && normalizeUrl(l.url).toLowerCase().replace(/\/+$/, '') === key
  ) || null;
}

function checkDuplicateUrl() {
  const warn = $('#linkDupWarn');
  const url = $('#linkUrl').value;
  const dup = url.trim() ? findDuplicate(url, editingLink && editingLink.id) : null;
  if (dup) {
    const cat = categoryOf(dup);
    warn.textContent =
      'Already saved' + (cat ? ' in ' + cat.name : '') + ' — "' + (dup.name || hostOf(url)) + '". Saving again will create a copy.';
    warn.hidden = false;
  } else {
    warn.hidden = true;
  }
}

function openLinkModal(link) {
  editingLink = link || null;
  $('#linkModalTitle').textContent = link ? 'Edit Link' : 'Add Link';
  $('#linkModalSub').textContent = link
    ? 'Update the details of this link.'
    : 'Save a link so you can open it anytime.';
  $('#linkSaveBtn').textContent = link ? 'Save Changes' : 'Add Link';
  $('#linkUrl').value = link ? link.url : '';
  $('#linkName').value = link ? link.name : '';
  $('#linkUrl').classList.remove('invalid');
  fillCategorySelect($('#linkCategory'), link ? link.categoryId : null);
  checkDuplicateUrl();
  openModal('modalLink');
}

function confirmDeleteLink(link) {
  askConfirm('Delete link?', '"' + (link.name || hostOf(link.url)) + '" will be removed permanently.', 'Delete', () => {
    state.links = state.links.filter((l) => l.id !== link.id);
    persist();
    renderAll();
    closeModal('modalConfirm');
    toast('Link deleted');
  });
}

function handleLinkSubmit(e) {
  e.preventDefault();
  const urlInput = $('#linkUrl');
  const url = normalizeUrl(urlInput.value);
  if (!url || !hostOf(url)) {
    urlInput.classList.add('invalid');
    urlInput.focus();
    return;
  }
  urlInput.classList.remove('invalid');

  let name = $('#linkName').value.trim();
  if (!name) name = deriveName(url) || hostOf(url) || 'Untitled';

  const categoryId = $('#linkCategory').value || null;

  if (editingLink) {
    const urlChanged = editingLink.url !== url;
    editingLink.name = name;
    editingLink.url = url;
    editingLink.categoryId = categoryId;
    if (urlChanged) {
      editingLink.favicon = '';
      queueFavicon(editingLink);
    }
    toast('Link updated');
  } else {
    const link = { id: uid('lnk'), name, url, categoryId, favicon: '', createdAt: Date.now(), pinned: false };
    state.links.push(link);
    queueFavicon(link);
    toast('Link added');
  }

  $('#linkDupWarn').hidden = true;
  persist();
  closeModal('modalLink');
  renderAll();
}

/* ---------- Category modal ---------- */

function openCategoryModal(cat) {
  editingCategory = cat || null;
  $('#categoryModalTitle').textContent = cat ? 'Edit Category' : 'New Category';
  $('#categorySaveBtn').textContent = cat ? 'Save Changes' : 'Create';
  $('#categoryName').value = cat ? cat.name : '';
  $('#deleteCategoryBtn').hidden = !cat;
  $('#categoryName').classList.remove('invalid');
  openModal('modalCategory');
}

function handleCategorySubmit(e) {
  e.preventDefault();
  const input = $('#categoryName');
  const name = input.value.trim();
  if (!name) {
    input.classList.add('invalid');
    input.focus();
    return;
  }

  const duplicate = state.categories.some(
    (c) => c.name.toLowerCase() === name.toLowerCase() && (!editingCategory || c.id !== editingCategory.id)
  );
  if (duplicate) {
    input.classList.add('invalid');
    toast('A category with this name already exists');
    return;
  }

  if (editingCategory) {
    editingCategory.name = name;
    toast('Category updated');
  } else {
    const cat = { id: uid('cat'), name, color: nextColor(), createdAt: Date.now() };
    state.categories.push(cat);
    ui.currentCategory = cat.id;
    toast('Category created');
  }

  persist();
  closeModal('modalCategory');
  renderAll();
}

function handleCategoryDelete() {
  const cat = editingCategory;
  if (!cat) return;
  const count = state.links.filter((l) => l.categoryId === cat.id).length;
  const msg =
    count > 0
      ? 'Links in "' + cat.name + '" (' + count + ') will move to Uncategorized. The category will be deleted.'
      : 'The category "' + cat.name + '" will be deleted.';
  closeModal('modalCategory');
  askConfirm('Delete category?', msg, 'Delete', () => {
    state.links.forEach((l) => {
      if (l.categoryId === cat.id) l.categoryId = null;
    });
    state.categories = state.categories.filter((c) => c.id !== cat.id);
    if (ui.currentCategory === cat.id) ui.currentCategory = 'all';
    persist();
    renderAll();
    closeModal('modalConfirm');
    toast('Category deleted');
  });
}

/* ---------- Import ---------- */

function parseImportFile(name, content) {
  const trimmed = content.trim();
  const looksHtml = /\.html?$/i.test(name || '') || /^</.test(trimmed);

  if (!looksHtml) {
    try {
      return parseImportJson(JSON.parse(trimmed));
    } catch (_) {}
  }
  const result = parseBookmarksHtml(content);
  if (result) return result;
  throw new Error('Unrecognized file format');
}

function parseImportJson(obj) {
  let cats = [];
  let links = [];

  const pickLink = (x) => {
    if (!x || typeof x !== 'object') return null;
    const url = normalizeUrl(String(x.url || x.href || ''));
    if (!url || !hostOf(url)) return null;
    const name = String(x.name || x.title || '').trim();
    const catName = x.categoryName || (x.category && (x.category.name || x.category)) || null;
    return {
      name,
      url,
      categoryName: typeof catName === 'string' && catName.trim() ? catName.trim() : null
    };
  };

  if (Array.isArray(obj)) {
    links = obj.map(pickLink).filter(Boolean);
  } else if (obj && typeof obj === 'object') {
    if (Array.isArray(obj.categories)) {
      cats = obj.categories
        .map((c) => (typeof c === 'string' ? { name: c.trim() } : c && typeof c.name === 'string' ? { name: c.name.trim() } : null))
        .filter((c) => c && c.name);
    }
    if (Array.isArray(obj.links)) {
      links = obj.links.map(pickLink).filter(Boolean);
    } else if (Array.isArray(obj.bookmarks)) {
      links = obj.bookmarks.map(pickLink).filter(Boolean);
    }
  }

  if (!links.length) throw new Error('No links found in JSON');
  return { categories: cats, links };
}

const BAR_NAMES = /^(bookmarks?[\s-]*(bar|menu|toolbar)|favorites?[\s-]*bar|other bookmarks)$/i;

function parseBookmarksHtml(html) {
  const doc = new DOMParser().parseFromString(html, 'text/html');
  const rootDl = doc.querySelector('dl');
  if (!rootDl || !doc.querySelector('a[href]')) return null;

  const categories = [];
  const links = [];
  const seenCats = new Set();

  function ensureCategory(name) {
    const key = name.toLowerCase();
    if (!seenCats.has(key)) {
      seenCats.add(key);
      categories.push({ name });
    }
    return name;
  }

  function walk(dlv, ctxCategory) {
    for (const node of dlv.children) {
      if (node.tagName !== 'DT') continue;
      const h3 = node.querySelector(':scope > h3');
      if (h3) {
        const name = h3.textContent.trim();
        let cat = ctxCategory;
        if (cat === null && !BAR_NAMES.test(name) && name) {
          cat = ensureCategory(name);
        }
        const sub = node.querySelector(':scope > dl');
        if (sub) walk(sub, cat);
        continue;
      }
      const a = node.querySelector(':scope > a');
      if (a) {
        const url = (a.getAttribute('href') || '').trim();
        if (/^(https?|ftp):/i.test(url)) {
          links.push({
            name: (a.textContent || '').trim(),
            url,
            categoryName: ctxCategory
          });
        }
      }
    }
  }

  walk(rootDl, null);

  if (!links.length) return null;
  return { categories, links };
}

function showImportModal(fileName, parsed) {
  pendingImport = parsed;
  const nCats = parsed.categories.length;
  const nLinks = parsed.links.length;
  $('#importSummary').textContent =
    'Found ' + nLinks + ' link' + (nLinks === 1 ? '' : 's') +
    (nCats ? ' and ' + nCats + ' categor' + (nCats === 1 ? 'y' : 'ies') : '') +
    ' in "' + fileName + '".';
  const radios = document.querySelectorAll('input[name="importMode"]');
  radios.forEach((r) => (r.checked = r.value === 'merge'));
  openModal('modalImport');
}

function handleImportConfirm() {
  if (!pendingImport) return;
  const mode = document.querySelector('input[name="importMode"]:checked').value;
  const parsed = pendingImport;
  pendingImport = null;

  if (mode === 'replace') {
    state.categories = [];
    state.links = [];
    ui.currentCategory = 'all';
  }

  const catByName = new Map(state.categories.map((c) => [c.name.toLowerCase(), c]));
  for (const c of parsed.categories) {
    const key = c.name.toLowerCase();
    if (!catByName.has(key)) {
      const cat = { id: uid('cat'), name: c.name, color: nextColor(), createdAt: Date.now() };
      state.categories.push(cat);
      catByName.set(key, cat);
    }
  }

  const existing = new Set(
    state.links.map((l) => normalizeUrl(l.url).toLowerCase().replace(/\/+$/, ''))
  );
  let added = 0;
  for (const l of parsed.links) {
    const url = normalizeUrl(l.url);
    const key = url.toLowerCase().replace(/\/+$/, '');
    if (!hostOf(url) || existing.has(key)) continue;
    existing.add(key);
    const link = {
      id: uid('lnk'),
      name: l.name || deriveName(url) || hostOf(url),
      url,
      categoryId: l.categoryName ? (catByName.get(l.categoryName.toLowerCase()) || {}).id || null : null,
      favicon: '',
      createdAt: Date.now()
    };
    state.links.push(link);
    queueFavicon(link);
    added++;
  }

  persist();
  closeModal('modalImport');
  renderAll();
  toast('Imported ' + added + ' link' + (added === 1 ? '' : 's'));
}

async function startImport() {
  hideMenus();
  const res = await bridge.pickImport();
  if (!res || !res.ok) {
    if (res && res.error) toast(res.error);
    return;
  }
  try {
    const parsed = parseImportFile(res.name, res.content);
    showImportModal(res.name, parsed);
  } catch (err) {
    toast('Could not import this file. Use a JSON or bookmarks HTML file.');
  }
}

/* ---------- Export ---------- */

function escHtml(s) {
  return String(s)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

function buildNetscapeHtml() {
  const lines = [
    '<!DOCTYPE NETSCAPE-Bookmark-file-1>',
    '<!-- This is an automatically generated file. It will be read and overwritten. DO NOT EDIT! -->',
    '<META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">',
    '<TITLE>Bookmarks</TITLE>',
    '<H1>Bookmarks</H1>',
    '<DL><p>'
  ];

  const exportGroup = (name, links) => {
    if (!links.length) return;
    lines.push('    <DT><H3>' + escHtml(name) + '</H3>');
    lines.push('    <DL><p>');
    for (const l of links) {
      lines.push('        <DT><A HREF="' + escHtml(normalizeUrl(l.url)) + '">' + escHtml(l.name || hostOf(l.url)) + '</A>');
    }
    lines.push('    </DL><p>');
  };

  for (const cat of state.categories) {
    exportGroup(cat.name, state.links.filter((l) => l.categoryId === cat.id));
  }
  exportGroup(
    'Uncategorized',
    state.links.filter((l) => !l.categoryId || !findCategory(l.categoryId))
  );

  lines.push('</DL><p>');
  return lines.join('\n');
}

function buildExportJson() {
  return JSON.stringify(
    {
      app: 'LinkMAX',
      version: 1,
      exportedAt: new Date().toISOString(),
      categories: state.categories.map((c) => ({ id: c.id, name: c.name, color: c.color })),
      links: state.links.map((l) => ({
        id: l.id,
        name: l.name,
        url: l.url,
        categoryId: l.categoryId,
        createdAt: l.createdAt
      }))
    },
    null,
    2
  );
}

function dateStamp() {
  const d = new Date();
  const p = (n) => String(n).padStart(2, '0');
  return d.getFullYear() + '-' + p(d.getMonth() + 1) + '-' + p(d.getDate());
}

async function doExport(kind) {
  hideMenus();
  if (!state.links.length) {
    toast('Nothing to export yet');
    return;
  }
  if (kind === 'json') {
    const res = await bridge.pickExport({
      defaultName: 'linkmax-backup-' + dateStamp() + '.json',
      filters: [{ name: 'JSON', extensions: ['json'] }],
      content: buildExportJson()
    });
    if (res && res.ok) toast('Exported JSON' + (res.path ? ' — ' + res.path : ''));
  } else {
    const res = await bridge.pickExport({
      defaultName: 'linkmax-bookmarks-' + dateStamp() + '.html',
      filters: [{ name: 'HTML Bookmarks', extensions: ['html'] }],
      content: buildNetscapeHtml()
    });
    if (res && res.ok) toast('Exported HTML bookmarks' + (res.path ? ' — ' + res.path : ''));
  }
}

/* ---------- Link context menu ---------- */

function showLinkContextMenu(e, link) {
  const menu = $('#ctxMenu');
  menu.replaceChildren(
    el('button', { class: 'ctx-item', html: I.open, onclick: () => { hideMenus(); openLink(link); } }, ' Open in Browser'),
    el('button', {
      class: 'ctx-item', html: I.copy,
      onclick: () => {
        hideMenus();
        navigator.clipboard.writeText(normalizeUrl(link.url)).then(
          () => toast('URL copied'),
          () => toast('Could not copy URL')
        );
      }
    }, ' Copy URL'),
    el('button', { class: 'ctx-item', html: link.pinned ? I.pinFilled : I.pin, onclick: () => { hideMenus(); togglePin(link); } },
      link.pinned ? ' Unpin' : ' Pin to top'),
    el('div', { class: 'ctx-sep' }),
    el('button', { class: 'ctx-item', html: I.edit, onclick: () => { hideMenus(); openLinkModal(link); } }, ' Edit'),
    el('button', { class: 'ctx-item danger', html: I.trash, onclick: () => { hideMenus(); confirmDeleteLink(link); } }, ' Delete')
  );
  positionMenu(menu, e.clientX, e.clientY);
}

/* ---------- Wire up events ---------- */

function wireEvents() {
  $('#navAll').addEventListener('click', () => selectCategory('all'));
  document.querySelectorAll('.nav-item[data-cat="none"]').forEach((b) => {
    b.addEventListener('click', () => selectCategory('none'));
  });
  $('#addCategoryBtn').addEventListener('click', () => openCategoryModal(null));
  $('#addLinkBtn').addEventListener('click', () => openLinkModal(null));

  $('#searchInput').addEventListener('input', (e) => {
    ui.search = e.target.value;
    renderLinks();
  });

  $('#sortSelect').addEventListener('change', (e) => {
    ui.sortMode = e.target.value;
    persist();
    renderLinks();
  });

  $('#viewToggle').addEventListener('click', (e) => {
    const btn = e.target.closest('[data-view]');
    if (!btn) return;
    ui.view = btn.dataset.view;
    persist();
    renderLinks();
  });

  $('#themeToggle').addEventListener('click', () => {
    applyTheme(ui.theme === 'dark' ? 'light' : 'dark');
    persist();
  });

  $('#importBtn').addEventListener('click', startImport);
  $('#exportBtn').addEventListener('click', (e) => {
    e.stopPropagation();
    const menu = $('#exportMenu');
    const showing = !menu.hidden;
    hideMenus();
    if (!showing) {
      const r = e.currentTarget.getBoundingClientRect();
      positionMenu(menu, r.right - 230, r.top - 8);
      menu.style.left = '';
      menu.style.right = '0px';
      menu.style.bottom = '40px';
      menu.style.top = '';
    }
  });
  $('#exportMenu').addEventListener('click', (e) => {
    const item = e.target.closest('[data-export]');
    if (item) doExport(item.dataset.export);
  });

  $('#linkForm').addEventListener('submit', handleLinkSubmit);
  $('#categoryForm').addEventListener('submit', handleCategorySubmit);
  $('#deleteCategoryBtn').addEventListener('click', handleCategoryDelete);
  $('#importConfirmBtn').addEventListener('click', handleImportConfirm);

  $('#confirmBtn').addEventListener('click', () => {
    if (confirmHandler) {
      const fn = confirmHandler;
      confirmHandler = null;
      fn();
    } else {
      closeModal('modalConfirm');
    }
  });

  document.querySelectorAll('.modal-backdrop').forEach((backdrop) => {
    backdrop.addEventListener('mousedown', (e) => {
      if (e.target === backdrop) backdrop.hidden = true;
    });
    backdrop.querySelectorAll('[data-close]').forEach((btn) => {
      btn.addEventListener('click', () => (backdrop.hidden = true));
    });
  });

  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
      if (!closeTopModal()) hideMenus();
    } else if ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() === 'f') {
      e.preventDefault();
      $('#searchInput').focus();
      $('#searchInput').select();
    }
  });

  document.addEventListener('mousedown', (e) => {
    if (!e.target.closest('.menu-pop') && !e.target.closest('#exportBtn')) hideMenus();
  });

  document.addEventListener('contextmenu', (e) => {
    if (e.target.closest('.card') || e.target.closest('.row')) return;
    e.preventDefault();
  });

  $('#linkUrl').addEventListener('input', (e) => {
    e.target.classList.remove('invalid');
    clearTimeout(checkDuplicateUrl._t);
    checkDuplicateUrl._t = setTimeout(checkDuplicateUrl, 200);
  });
  $('#categoryName').addEventListener('input', (e) => e.target.classList.remove('invalid'));

  attachDropTarget($('#navNoneWrap .nav-item'), null);
}

/* ---------- Inject static icons ---------- */

function injectStaticIcons() {
  $('#brandLogo').innerHTML = BRAND_ICON;
  $('#allIco').innerHTML = I.inbox;
  $('#noneIco').innerHTML = I.slash;
  $('#plusIco').innerHTML = I.plusSm;
  $('#searchIco').innerHTML = I.search;
  document.querySelectorAll('[data-ico]').forEach((n) => {
    const key = n.dataset.ico;
    if (I[key]) n.innerHTML = I[key];
  });
}

/* ---------- Init ---------- */

async function init() {
  injectStaticIcons();
  wireEvents();

  const loaded = await bridge.load();
  if (loaded && typeof loaded === 'object') {
    adoptState(loaded);
  }

  ui.view = state.settings.view || 'grid';
  ui.sortMode = state.settings.sortMode || 'name';
  $('#sortSelect').value = ui.sortMode;
  applyTheme(state.settings.theme || ui.theme);
  renderAll();

  for (const link of state.links) queueFavicon(link);

  if (typeof bridge.getHotkey === 'function') {
    bridge.getHotkey().then((acc) => {
      if (!acc) return;
      const hint = $('#quickCaptureHint');
      hint.hidden = false;
      hint.textContent = 'Tip: copy any URL, then press ' + acc + ' anywhere to save it here instantly.';
    });
  }

  // Quick capture (and anything else that edits the data file) refreshes the UI live.
  if (typeof bridge.onDataChanged === 'function') {
    bridge.onDataChanged(async () => {
      const fresh = await bridge.load();
      if (!fresh) return;
      adoptState(fresh);
      ui.sortMode = state.settings.sortMode || ui.sortMode;
      $('#sortSelect').value = ui.sortMode;
      renderAll();
      for (const link of state.links) queueFavicon(link);
    });
  }
}

init();
