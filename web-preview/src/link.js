// Capture once. The secret never needs to survive a page reload.
export function captureShareLink({ location, history }) {
  const match = /^\/s\/([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})$/.exec(location.pathname);
  const compact = location.pathname === '/s/';
  const fragment = (compact ? /^#([A-Za-z0-9_-]{43})$/ : /^#token=([A-Za-z0-9_-]{43})$/).exec(location.hash);
  const permitted = !location.search && location.protocol === 'https:';
  // Do this before any asynchronous work, even for malformed links.
  try {
    history.replaceState(null, '', location.pathname);
  } catch {
    return null; // Do not resolve if history cannot be scrubbed.
  }
  if ((!compact && !match) || !fragment || !permitted) return null;
  const token = fragment[1];
  const decoded = atob(token.replaceAll('-', '+').replaceAll('_', '/') + '=');
  const canonical = btoa(decoded).replaceAll('+', '-').replaceAll('/', '_').replace(/=+$/, '');
  if (decoded.length !== 32 || canonical !== token) return null;
  return compact ? { token } : { shareId: match[1], token };
}

// Build only inside the explicit Open action. Android browsers can keep an
// HTTPS-to-HTTPS handoff inside the browser even for verified App Links.
// Package-scoped intents request the installed app and preserve the original
// URI fragment; the HTTPS preview remains the fallback if the app is absent.
export function appLaunchUrl(link, origin, userAgent) {
  const url = link.shareId ? `${origin}/s/${link.shareId}#token=${link.token}` : `${origin}/s/#${link.token}`;
  if (!/Android/i.test(userAgent)) return url;
  return `intent:${url.slice('https:'.length)}#Intent;scheme=https;package=com.manalogadiel.schediel;S.browser_fallback_url=${encodeURIComponent(url)};end`;
}
