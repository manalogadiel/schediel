import { captureShareLink } from './link.js';
import { readSettings } from './settings.js';
import { validateResolvedShare } from './validate.js';
import { renderPreview } from './render.js';

const MESSAGES = {
  loading: 'Loading preview…',
  preview: 'Read-only preview ready.',
  unavailable: 'This link is unavailable. Reopen the original link or ask the sender for a new one.',
  expired: 'This link has expired. Ask the sender for a new link.',
  revoked: 'This link has been revoked. Ask the sender for a new link.',
  unsupported: 'This preview uses an unsupported version. Try the current Schediel app or ask the sender for a new link.',
  'rate-limited': 'Too many requests. Wait before trying again.',
  error: 'The preview could not be loaded. Check your connection and try again.',
};

export async function startPreview({ window, config, locale = window.navigator.language || 'en-US', timeZone = new window.Intl.DateTimeFormat().resolvedOptions().timeZone, navigate = url => window.location.assign(url) }) {
  // Capture and scrub synchronously, before configuration checks or fetch.
  const link = captureShareLink(window);
  const document = window.document;
  const main = document.querySelector('main');
  const status = document.querySelector('#status');
  const retry = document.querySelector('#retry');
  const preview = document.querySelector('#preview');
  const action = document.querySelector('#app-action');
  const items = document.querySelector('#items');
  const openApp = document.querySelector('#open-app');
  const appHelp = document.querySelector('#app-help');
  // Hidden by default; only a validated, distinct owned origin enables handoff.
  openApp.hidden = true;
  function state(name, retryable = false, message = MESSAGES[name]) {
    main.dataset.state = name;
    main.setAttribute('aria-busy', String(name === 'loading'));
    status.textContent = message;
    preview.hidden = name !== 'preview';
    action.hidden = name !== 'preview';
    retry.hidden = !retryable;
    retry.disabled = name === 'loading';
  }
  if (!link) { state('unavailable'); return; }
  let settings;
  try {
    settings = readSettings(config);
    if (settings.shareHost !== window.location.origin) throw new Error('Unexpected share origin');
  } catch {
    state('error', false, 'This preview is not configured. Reopen the original link in Schediel.');
    return;
  }
  let busy = false;
  async function resolve() {
    if (busy) return;
    busy = true;
    items.replaceChildren();
    state('loading');
    try {
      const headers = { 'Content-Type': 'application/json' };
      if (settings.publishableKey) headers.apikey = settings.publishableKey;
      const response = await window.fetch(`${settings.apiBase}/share-resolve`, {
        method: 'POST', headers,
        body: JSON.stringify({ ...link, supportedSchemaVersions: ['1.0'] }),
        credentials: 'omit', cache: 'no-store', referrerPolicy: 'no-referrer', redirect: 'error',
      });
      if (!response.ok) {
        const error = await response.json().catch(() => ({}));
        if (response.status === 410) state(error?.code === 'link_expired' ? 'expired' : error?.code === 'link_revoked' ? 'revoked' : 'unavailable');
        else if (response.status === 404 || response.status === 400) state('unavailable');
        else if (response.status === 422) state('unsupported');
        else if (response.status === 429) {
          const seconds = error?.retryAfterSeconds;
          const message = Number.isInteger(seconds) && seconds >= 0 && seconds <= 86400 ? `Too many requests. Try again after ${seconds} seconds.` : MESSAGES['rate-limited'];
          state('rate-limited', true, message);
        } else state('error', true);
        return;
      }
      const result = await response.json();
      const validation = validateResolvedShare(result, link.shareId);
      if (!validation.valid) {
        const unsupported = validation.errors.some(error => error.code === 'unsupported_version');
        state(unsupported ? 'unsupported' : 'error', !unsupported);
        return;
      }
      renderPreview(document, result, { locale, timeZone });
      state('preview');
    } catch {
      // Do not log errors, response bodies or the bearer URL.
      items.replaceChildren();
      state('error', true);
    } finally {
      busy = false;
    }
  }
  if (settings.appLinkOrigin) {
    openApp.hidden = false;
    openApp.addEventListener('click', () => {
      if (main.dataset.state === 'preview') {
        // Never restore the bearer to the preview URL: that is a same-document
        // hash navigation, not an OS app handoff. Build the destination only here.
        navigate(`${settings.appLinkOrigin}/s/${link.shareId}#token=${link.token}`);
      }
    });
  } else {
    appHelp.textContent = 'To review and add schedules, reopen the original link on a device with Schediel installed. Nothing is added here.';
  }
  retry.addEventListener('click', async () => {
    await resolve();
    status.setAttribute('tabindex', '-1');
    status.focus();
  });
  await resolve();
}
