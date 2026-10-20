// Contract 1.0. Keep this whitelist aligned with the shared schema and fixtures.
const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/;
const DETAIL_LIMITS = { location: 240, professor: 160, subtitle: 240, notes: 4000 };
const pointer = key => String(key).replaceAll('~', '~0').replaceAll('/', '~1');
class ContractError extends Error {
  constructor(code, path) { super(code); this.code = code; this.path = path; }
}
const fail = (code, path) => { throw new ContractError(code, path); };
function object(value, keys, path) {
  if (!value || typeof value !== 'object' || Array.isArray(value)) fail('invalid_type', path);
  for (const key of keys) if (!Object.hasOwn(value, key)) fail('missing_field', `${path}/${key}`);
  for (const key of Object.keys(value)) if (!keys.includes(key)) fail('unknown_field', `${path}/${pointer(key)}`);
}
function text(value, max, path, nullable = false) {
  if (nullable && value === null) return;
  if (typeof value !== 'string') fail('invalid_type', path);
  if (!value || value.trim() !== value || /^\p{White_Space}|\p{White_Space}$/u.test(value)) fail('invalid_text', path);
  if ([...value].length > max) fail('too_long', path);
}
function array(value, max, path, min = 0) {
  if (!Array.isArray(value)) fail('invalid_type', path);
  if (value.length < min) fail('invalid_value', path);
  if (value.length > max) fail('too_many', path);
}
function integer(value, min, max, path) {
  if (!Number.isInteger(value)) fail('invalid_type', path);
  if (value < min || value > max) fail('invalid_value', path);
}
function details(value, path) {
  object(value, Object.keys(DETAIL_LIMITS), path);
  for (const [key, max] of Object.entries(DETAIL_LIMITS)) text(value[key], max, `${path}/${key}`, true);
}
function date(value, path) {
  if (typeof value !== 'string' || !/^(19|20|21)[0-9]{2}-[0-9]{2}-[0-9]{2}$/.test(value)) fail('invalid_date', path);
  const instant = Date.parse(`${value}T00:00:00Z`);
  if (!Number.isFinite(instant) || new Date(instant).toISOString().slice(0, 10) !== value) fail('invalid_date', path);
  return instant;
}
function clock(value, path) {
  if (typeof value !== 'string' || !/^([01][0-9]|2[0-3]):[0-5][0-9]$/.test(value)) fail('invalid_time', path);
}
function time(value, path, recurring = false) {
  if (!value || typeof value !== 'object') fail('invalid_type', path);
  if (value.kind === 'dateOnly') {
    object(value, ['kind', 'startDate', 'endDateExclusive'], path);
    const start = date(value.startDate, `${path}/startDate`);
    const end = date(value.endDateExclusive, `${path}/endDateExclusive`);
    const days = (end - start) / 86400000;
    if (days < 1 || days > 366 || (recurring && days !== 1)) fail('invalid_range', `${path}/endDateExclusive`);
    return;
  }
  if (value.kind !== 'timed') fail('invalid_value', `${path}/kind`);
  object(value, ['kind', 'startDate', 'startTime', 'timeZone', 'endTime', 'endDayOffset', 'seedTimeResolution', 'endTimeResolution'], path);
  date(value.startDate, `${path}/startDate`);
  clock(value.startTime, `${path}/startTime`);
  if (typeof value.timeZone !== 'string' || value.timeZone.length > 64 || !/^[A-Za-z][A-Za-z0-9_+./-]*$/.test(value.timeZone)) fail('invalid_time_zone', `${path}/timeZone`);
  try { new Intl.DateTimeFormat('en', { timeZone: value.timeZone }); }
  catch { fail('invalid_time_zone', `${path}/timeZone`); }
  if (![null, 0, 1].includes(value.endDayOffset) || (value.endTime === null) !== (value.endDayOffset === null)) fail('invalid_value', `${path}/endDayOffset`);
  if (value.endTime !== null) {
    clock(value.endTime, `${path}/endTime`);
    if (value.endDayOffset === 0 && value.endTime <= value.startTime) fail('invalid_range', `${path}/endTime`);
  }
  for (const key of ['seedTimeResolution', 'endTimeResolution']) {
    if (![null, 'earlier', 'later'].includes(value[key])) fail('invalid_value', `${path}/${key}`);
  }
}
function recurrence(value, seed, path) {
  if (value === null) return;
  object(value, ['frequency', 'interval', 'weekdays', 'untilDateInclusive'], path);
  if (!['daily', 'weekly'].includes(value.frequency)) fail('invalid_value', `${path}/frequency`);
  if (value.interval !== 1) fail('invalid_value', `${path}/interval`);
  const days = value.weekdays;
  if (!Array.isArray(days) || days.length > 7 || days.some(day => !Number.isInteger(day) || day < 1 || day > 7) || new Set(days).size !== days.length || (value.frequency === 'weekly' ? days.length === 0 : days.length !== 0)) fail('invalid_recurrence', `${path}/weekdays`);
  if (value.untilDateInclusive !== null) {
    date(value.untilDateInclusive, `${path}/untilDateInclusive`);
    if (value.untilDateInclusive < seed) fail('invalid_range', `${path}/untilDateInclusive`);
  }
}
function approvedDetails(value, policy, path) {
  details(value, path);
  for (const key of Object.keys(DETAIL_LIMITS)) {
    if (!policy[key] && value[key] !== null) fail('policy_violation', `${path}/${key}`);
  }
}
function exceptions(item, policy, path) {
  array(item.exceptions, 500, path);
  const seen = new Set();
  for (const [index, entry] of item.exceptions.entries()) {
    const at = `${path}/${index}`;
    object(entry, ['originalOccurrenceKey', 'action', 'replacement'], at);
    if (item.recurrence === null) fail('invalid_exception', at);
    const keyPath = `${at}/originalOccurrenceKey`;
    const instant = date(entry.originalOccurrenceKey, keyPath);
    const weekday = new Date(instant).getUTCDay() || 7;
    const rule = item.recurrence;
    if (entry.originalOccurrenceKey < item.time.startDate || (rule.untilDateInclusive !== null && entry.originalOccurrenceKey > rule.untilDateInclusive) || (rule.frequency === 'weekly' && !rule.weekdays.includes(weekday))) fail('invalid_exception', keyPath);
    if (seen.has(entry.originalOccurrenceKey)) fail('duplicate', keyPath);
    seen.add(entry.originalOccurrenceKey);
    if (!['cancel', 'override'].includes(entry.action)) fail('invalid_value', `${at}/action`);
    if (entry.action === 'cancel') {
      if (entry.replacement !== null) fail('invalid_exception', `${at}/replacement`);
    } else {
      if (entry.replacement === null) fail('invalid_exception', `${at}/replacement`);
      object(entry.replacement, ['title', 'time', 'details'], `${at}/replacement`);
      text(entry.replacement.title, 120, `${at}/replacement/title`);
      time(entry.replacement.time, `${at}/replacement/time`);
      if (entry.replacement.time.kind !== item.time.kind) fail('invalid_exception', `${at}/replacement/time`);
      approvedDetails(entry.replacement.details, policy, `${at}/replacement/details`);
    }
  }
}
export function validatePayload(payload) {
  try {
    object(payload, ['schemaVersion', 'items', 'sharedFieldPolicy'], '');
    if (payload.schemaVersion !== '1.0') fail('unsupported_version', '/schemaVersion');
    array(payload.items, 250, '/items', 1);
    object(payload.sharedFieldPolicy, Object.keys(DETAIL_LIMITS), '/sharedFieldPolicy');
    for (const [key, value] of Object.entries(payload.sharedFieldPolicy)) {
      if (typeof value !== 'boolean') fail('invalid_type', `/sharedFieldPolicy/${key}`);
    }
    const seenIds = new Set();
    for (const [index, item] of payload.items.entries()) {
      const path = `/items/${index}`;
      object(item, ['sourceItemId', 'revision', 'title', 'categoryLabel', 'time', 'recurrence', 'details', 'exceptions'], path);
      if (typeof item.sourceItemId !== 'string') fail('invalid_type', `${path}/sourceItemId`);
      if (!UUID.test(item.sourceItemId)) fail('invalid_value', `${path}/sourceItemId`);
      if (seenIds.has(item.sourceItemId)) fail('duplicate', `${path}/sourceItemId`);
      seenIds.add(item.sourceItemId);
      integer(item.revision, 1, 2147483647, `${path}/revision`);
      text(item.title, 120, `${path}/title`);
      text(item.categoryLabel, 60, `${path}/categoryLabel`, true);
      approvedDetails(item.details, payload.sharedFieldPolicy, `${path}/details`);
      time(item.time, `${path}/time`, item.recurrence !== null);
      recurrence(item.recurrence, item.time.startDate, `${path}/recurrence`);
      exceptions(item, payload.sharedFieldPolicy, `${path}/exceptions`);
    }
    if (payload.items.reduce((total, item) => total + item.exceptions.length, 0) > 500) fail('too_many', '/items');
    if (new TextEncoder().encode(JSON.stringify(payload)).length > 524288) fail('payload_too_large', '');
    return { valid: true, errors: [] };
  } catch (error) {
    if (!(error instanceof ContractError)) throw error;
    return { valid: false, errors: [{ code: error.code, path: error.path }] };
  }
}

function timestamp(value, path) {
  if (typeof value !== 'string' || !/^\d{4}-\d{2}-\d{2}T([01]\d|2[0-3]):[0-5]\d:[0-5]\d(?:\.\d+)?(?:Z|[+-]([01]\d|2[0-3]):[0-5]\d)$/.test(value)) fail('invalid_date', path);
  date(value.slice(0, 10), path);
  const instant = Date.parse(value);
  if (!Number.isFinite(instant)) fail('invalid_date', path);
  return instant;
}
export function validateResolvedShare(result, expectedId) {
  try {
    object(result, ['shareId', 'schemaVersion', 'snapshotVersion', 'createdAt', 'expiresAt', 'itemCount', 'payload'], '');
    if (typeof result.shareId !== 'string' || !UUID.test(result.shareId) || expectedId != null && result.shareId !== expectedId) fail('invalid_value', '/shareId');
    if (result.schemaVersion !== '1.0') fail('unsupported_version', '/schemaVersion');
    integer(result.snapshotVersion, 1, Number.MAX_SAFE_INTEGER, '/snapshotVersion');
    const created = timestamp(result.createdAt, '/createdAt');
    const expires = timestamp(result.expiresAt, '/expiresAt');
    if (expires <= created) fail('invalid_range', '/expiresAt');
    const payloadResult = validatePayload(result.payload);
    if (!payloadResult.valid) return { valid: false, errors: payloadResult.errors.map(error => ({ ...error, path: `/payload${error.path}` })) };
    integer(result.itemCount, 1, 250, '/itemCount');
    if (result.itemCount !== result.payload.items.length) fail('invalid_value', '/itemCount');
    return { valid: true, errors: [] };
  } catch (error) {
    if (!(error instanceof ContractError)) throw error;
    return { valid: false, errors: [{ code: error.code, path: error.path }] };
  }
}
