// No runtime discovery: a configured HTTPS API and owned share origin only.
export function readSettings(value) {
  if (!value || typeof value.apiBase !== 'string' || typeof value.shareHost !== 'string') throw new Error('Configuration required');
  const api = new URL(value.apiBase);
  const share = new URL(value.shareHost);
  for (const url of [api, share]) {
    if (url.protocol !== 'https:' || url.username || url.password || url.search || url.hash) throw new Error('An HTTPS URL without credentials, query or fragment is required');
  }
  if (share.pathname !== '/') throw new Error('The share host must be an HTTPS origin');
  const publishableKey = value.publishableKey ?? '';
  if (typeof publishableKey !== 'string' || (publishableKey !== '' && !/^sb_publishable_[A-Za-z0-9_-]+$/.test(publishableKey))) throw new Error('Only a publishable key is allowed');
  const appLinkOrigin = value.appLinkOrigin;
  if (appLinkOrigin !== undefined && appLinkOrigin !== '') {
    const app = new URL(appLinkOrigin);
    if (typeof appLinkOrigin !== 'string' || app.protocol !== 'https:' ||
        app.port !== '' ||
        (appLinkOrigin !== app.origin && appLinkOrigin !== `${app.origin}/`) ||
        app.origin === share.origin || app.hostname === share.hostname) {
      throw new Error('The app link must be a distinct HTTPS origin');
    }
  }
  return { apiBase: api.href.replace(/\/+$/, ''), shareHost: share.origin, publishableKey,
    ...(appLinkOrigin ? { appLinkOrigin: new URL(appLinkOrigin).origin } : {}) };
}
