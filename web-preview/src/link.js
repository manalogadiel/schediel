// Capture once. The secret never needs to survive a page reload.
export function captureShareLink({ location, history }) {
  const match = /^\/s\/([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})$/.exec(location.pathname);
  const fragment = /^#token=([A-Za-z0-9_-]{43})$/.exec(location.hash);
  const permitted = !location.search && location.protocol === 'https:';
  // Do this before any asynchronous work, even for malformed links.
  try {
    history.replaceState(null, '', location.pathname);
  } catch {
    return null; // Do not resolve if history cannot be scrubbed.
  }
  if (!match || !fragment || !permitted) return null;
  const token = fragment[1];
  const decoded = atob(token.replaceAll('-', '+').replaceAll('_', '/') + '=');
  const canonical = btoa(decoded).replaceAll('+', '-').replaceAll('/', '_').replace(/=+$/, '');
  if (decoded.length !== 32 || canonical !== token) return null;
  return { shareId: match[1], token };
}
