export type FieldError = { code: string; path: string };
export const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/;
const isObject = (v: unknown): v is Record<string, any> => v !== null && typeof v === 'object' && !Array.isArray(v);
const pointer = (s: string) => s.replaceAll('~', '~0').replaceAll('/', '~1');
function keys(errors: FieldError[], v: Record<string, any>, path: string, allowed: string[]) {
  for (const key of Object.keys(v)) if (!allowed.includes(key)) errors.push({ code: 'unknown_field', path: `${path}/${pointer(key)}` });
  for (const key of allowed) if (!Object.hasOwn(v, key)) errors.push({ code: 'missing_field', path: `${path}/${key}` });
}
export function validatePayload(raw: unknown): FieldError[] {
  if (!isObject(raw)) return [{ code: 'invalid_type', path: '' }];
  const errors: FieldError[] = [];
  keys(errors, raw, '', ['schemaVersion', 'items', 'sharedFieldPolicy']);
  if (Object.hasOwn(raw, 'schemaVersion')) {
    if (typeof raw.schemaVersion !== 'string') errors.push({ code: 'invalid_type', path: '/schemaVersion' });
    else if (raw.schemaVersion !== '1.0') return [...errors, { code: 'unsupported_version', path: '/schemaVersion' }];
  }
  if (Object.hasOwn(raw, 'sharedFieldPolicy')) {
    if (!isObject(raw.sharedFieldPolicy)) errors.push({ code: 'invalid_type', path: '/sharedFieldPolicy' });
    else {
      keys(errors, raw.sharedFieldPolicy, '/sharedFieldPolicy', ['location', 'professor', 'subtitle', 'notes']);
      for (const key of ['location', 'professor', 'subtitle', 'notes']) if (Object.hasOwn(raw.sharedFieldPolicy, key) && typeof raw.sharedFieldPolicy[key] !== 'boolean') errors.push({ code: 'invalid_type', path: `/sharedFieldPolicy/${key}` });
    }
  }
  if (!Object.hasOwn(raw, 'items')) return errors;
  if (!Array.isArray(raw.items)) return [...errors, { code: 'invalid_type', path: '/items' }];
  if (raw.items.length === 0) errors.push({ code: 'invalid_value', path: '/items' });
  if (raw.items.length > 250) return [...errors, { code: 'too_many', path: '/items' }];
  const ids = new Set<string>();
  let exceptionCount = 0;
  raw.items.forEach((item: unknown, i: number) => {
    const p = `/items/${i}`;
    if (!isObject(item)) { errors.push({ code: 'invalid_type', path: p }); return; }
    keys(errors, item, p, ['sourceItemId', 'revision', 'title', 'categoryLabel', 'time', 'recurrence', 'details', 'exceptions']);
    if (Object.hasOwn(item, 'sourceItemId')) {
      if (typeof item.sourceItemId !== 'string') errors.push({ code: 'invalid_type', path: `${p}/sourceItemId` });
      else if (!UUID.test(item.sourceItemId)) errors.push({ code: 'invalid_value', path: `${p}/sourceItemId` });
      else if (ids.has(item.sourceItemId)) errors.push({ code: 'duplicate', path: `${p}/sourceItemId` });
      else ids.add(item.sourceItemId);
    }
    if (Object.hasOwn(item, 'revision')) {
      if (!Number.isInteger(item.revision)) errors.push({ code: 'invalid_type', path: `${p}/revision` });
      else if (item.revision < 1 || item.revision > 2147483647) errors.push({ code: 'invalid_value', path: `${p}/revision` });
    }
    if (Object.hasOwn(item, 'title')) text(errors, item.title, `${p}/title`, 120, false);
    if (Object.hasOwn(item, 'categoryLabel')) text(errors, item.categoryLabel, `${p}/categoryLabel`, 60, true);
    if (Object.hasOwn(item, 'details')) details(errors, item.details, `${p}/details`);
    if (Object.hasOwn(item, 'time')) time(errors, item.time, `${p}/time`, item.recurrence != null);
    if (Object.hasOwn(item, 'recurrence') && item.recurrence !== null) recurrence(errors, item.recurrence, item.time, `${p}/recurrence`);
    if (Object.hasOwn(item, 'exceptions')) {
      if (Array.isArray(item.exceptions)) exceptionCount += item.exceptions.length;
      exceptions(errors, item, p);
    }
    policy(errors, item.details, raw.sharedFieldPolicy, `${p}/details`);
    if (Array.isArray(item.exceptions)) item.exceptions.slice(0, 500).forEach((e: any, j: number) => {
      if (isObject(e) && isObject(e.replacement)) policy(errors, e.replacement.details, raw.sharedFieldPolicy, `${p}/exceptions/${j}/replacement/details`);
    });
  });
  if (exceptionCount > 500) errors.push({ code: 'too_many', path: '/items' });
  if (!errors.length && new TextEncoder().encode(JSON.stringify(raw)).byteLength > 524288) errors.push({ code: 'payload_too_large', path: '' });
  return errors;
}
function recurrence(errors: FieldError[], v: unknown, t: unknown, path: string) {
  if (!isObject(v)) { errors.push({ code: 'invalid_type', path }); return; }
  keys(errors, v, path, ['frequency', 'interval', 'weekdays', 'untilDateInclusive']);
  if (Object.hasOwn(v, 'frequency') && !['daily', 'weekly'].includes(v.frequency)) errors.push({ code: 'invalid_value', path: `${path}/frequency` });
  if (Object.hasOwn(v, 'interval')) {
    if (!Number.isInteger(v.interval)) errors.push({ code: 'invalid_type', path: `${path}/interval` });
    else if (v.interval !== 1) errors.push({ code: 'invalid_value', path: `${path}/interval` });
  }
  if (Object.hasOwn(v, 'weekdays')) {
    if (!Array.isArray(v.weekdays) || v.weekdays.some((d: unknown) => !Number.isInteger(d))) errors.push({ code: 'invalid_type', path: `${path}/weekdays` });
    else if (v.weekdays.length > 7 || new Set(v.weekdays).size !== v.weekdays.length || v.weekdays.some((d: number) => d < 1 || d > 7) || v.frequency === 'weekly' && !v.weekdays.length || v.frequency === 'daily' && v.weekdays.length) errors.push({ code: 'invalid_recurrence', path: `${path}/weekdays` });
  }
  if (Object.hasOwn(v, 'untilDateInclusive')) date(errors, v.untilDateInclusive, `${path}/untilDateInclusive`, true);
  if (isObject(t) && validDate(t.startDate) && validDate(v.untilDateInclusive) && v.untilDateInclusive < t.startDate) errors.push({ code: 'invalid_range', path: `${path}/untilDateInclusive` });
}
function policy(errors: FieldError[], d: unknown, p: unknown, path: string) {
  if (!isObject(d) || !isObject(p)) return;
  for (const key of Object.keys(detailLimits)) if (p[key] === false && d[key] != null) errors.push({ code: 'policy_violation', path: `${path}/${key}` });
}
function exceptions(errors: FieldError[], item: Record<string, any>, path: string) {
  const list = item.exceptions;
  if (!Array.isArray(list)) { errors.push({ code: 'invalid_type', path: `${path}/exceptions` }); return; }
  if (list.length > 500) { errors.push({ code: 'too_many', path: `${path}/exceptions` }); return; }
  const seen = new Set<string>();
  list.forEach((e: unknown, i: number) => {
    const p = `${path}/exceptions/${i}`;
    if (!isObject(e)) { errors.push({ code: 'invalid_type', path: p }); return; }
    keys(errors, e, p, ['originalOccurrenceKey', 'action', 'replacement']);
    if (Object.hasOwn(e, 'originalOccurrenceKey')) date(errors, e.originalOccurrenceKey, `${p}/originalOccurrenceKey`);
    if (Object.hasOwn(e, 'action') && !['cancel', 'override'].includes(e.action)) errors.push({ code: 'invalid_value', path: `${p}/action` });
    const r = item.recurrence;
    if (r === null) errors.push({ code: 'invalid_exception', path: p });
    else if (validDate(e.originalOccurrenceKey) && isObject(r) && isObject(item.time) && validDate(item.time.startDate)) {
      const key = e.originalOccurrenceKey;
      if (seen.has(key)) errors.push({ code: 'duplicate', path: `${p}/originalOccurrenceKey` });
      else {
        seen.add(key);
        const weekday = new Date(`${key}T00:00:00Z`).getUTCDay() || 7;
        if (key < item.time.startDate || validDate(r.untilDateInclusive) && key > r.untilDateInclusive || r.frequency === 'weekly' && Array.isArray(r.weekdays) && !r.weekdays.includes(weekday)) errors.push({ code: 'invalid_exception', path: `${p}/originalOccurrenceKey` });
      }
    }
    const replacement = e.replacement;
    if (e.action === 'cancel' && replacement != null || e.action === 'override' && replacement === null) errors.push({ code: 'invalid_exception', path: `${p}/replacement` });
    if (replacement === null || !Object.hasOwn(e, 'replacement')) return;
    const rp = `${p}/replacement`;
    if (!isObject(replacement)) { errors.push({ code: 'invalid_type', path: rp }); return; }
    keys(errors, replacement, rp, ['title', 'time', 'details']);
    if (Object.hasOwn(replacement, 'title')) text(errors, replacement.title, `${rp}/title`, 120, false);
    if (Object.hasOwn(replacement, 'details')) details(errors, replacement.details, `${rp}/details`);
    if (Object.hasOwn(replacement, 'time')) time(errors, replacement.time, `${rp}/time`, false);
    if (isObject(replacement.time) && isObject(item.time) && replacement.time.kind !== item.time.kind) errors.push({ code: 'invalid_exception', path: `${rp}/time` });
  });
}
const detailLimits = { location: 240, professor: 160, subtitle: 240, notes: 4000 };
function text(errors: FieldError[], v: unknown, path: string, max: number, nullable: boolean) {
  if (v === null && nullable) return;
  if (typeof v !== 'string') errors.push({ code: 'invalid_type', path });
  else if (!v || v.trim() !== v || /^\p{White_Space}|\p{White_Space}$/u.test(v)) errors.push({ code: 'invalid_text', path });
  else if ([...v].length > max) errors.push({ code: 'too_long', path });
}
function details(errors: FieldError[], v: unknown, path: string) {
  if (!isObject(v)) { errors.push({ code: 'invalid_type', path }); return; }
  keys(errors, v, path, Object.keys(detailLimits));
  for (const [key, max] of Object.entries(detailLimits)) if (Object.hasOwn(v, key)) text(errors, v[key], `${path}/${key}`, max, true);
}
export function validDate(v: unknown): v is string {
  if (typeof v !== 'string' || !/^(19|20|21)\d{2}-\d{2}-\d{2}$/.test(v)) return false;
  const d = new Date(`${v}T00:00:00Z`);
  return Number.isFinite(d.getTime()) && d.toISOString().slice(0, 10) === v;
}
function date(errors: FieldError[], v: unknown, path: string, nullable = false) {
  if (v === null && nullable) return;
  if (typeof v !== 'string') errors.push({ code: 'invalid_type', path });
  else if (!validDate(v)) errors.push({ code: 'invalid_date', path });
}
function clock(errors: FieldError[], v: unknown, path: string, nullable = false) {
  if (v === null && nullable) return;
  if (typeof v !== 'string') errors.push({ code: 'invalid_type', path });
  else if (!/^([01]\d|2[0-3]):[0-5]\d$/.test(v)) errors.push({ code: 'invalid_time', path });
}
const zoneCache = new Map<string, boolean>();
function validZone(v: string) {
  if (v.length > 64 || !/^[A-Za-z][A-Za-z0-9_+./-]*$/.test(v)) return false;
  if (zoneCache.has(v)) return zoneCache.get(v)!;
  let ok = true;
  try { new Intl.DateTimeFormat('en-US', { timeZone: v }).format(0); } catch { ok = false; }
  if (zoneCache.size < 256) zoneCache.set(v, ok);
  return ok;
}
function time(errors: FieldError[], v: unknown, path: string, recurring: boolean) {
  if (!isObject(v)) { errors.push({ code: 'invalid_type', path }); return; }
  if (!Object.hasOwn(v, 'kind')) { errors.push({ code: 'missing_field', path: `${path}/kind` }); return; }
  if (v.kind === 'dateOnly') {
    keys(errors, v, path, ['kind', 'startDate', 'endDateExclusive']);
    for (const k of ['startDate', 'endDateExclusive']) if (Object.hasOwn(v, k)) date(errors, v[k], `${path}/${k}`);
    if (validDate(v.startDate) && validDate(v.endDateExclusive)) {
      const span = (Date.parse(v.endDateExclusive) - Date.parse(v.startDate)) / 86400000;
      if (span < 1 || span > 366 || recurring && span !== 1) errors.push({ code: 'invalid_range', path: `${path}/endDateExclusive` });
    }
    return;
  }
  if (v.kind !== 'timed') { errors.push({ code: 'invalid_value', path: `${path}/kind` }); return; }
  keys(errors, v, path, ['kind', 'startDate', 'startTime', 'timeZone', 'endTime', 'endDayOffset', 'seedTimeResolution', 'endTimeResolution']);
  if (Object.hasOwn(v, 'startDate')) date(errors, v.startDate, `${path}/startDate`);
  if (Object.hasOwn(v, 'startTime')) clock(errors, v.startTime, `${path}/startTime`);
  if (Object.hasOwn(v, 'endTime')) clock(errors, v.endTime, `${path}/endTime`, true);
  if (Object.hasOwn(v, 'timeZone')) {
    if (typeof v.timeZone !== 'string') errors.push({ code: 'invalid_type', path: `${path}/timeZone` });
    else if (!validZone(v.timeZone)) errors.push({ code: 'invalid_time_zone', path: `${path}/timeZone` });
  }
  if (Object.hasOwn(v, 'endDayOffset') && v.endDayOffset !== null && ![0, 1].includes(v.endDayOffset)) errors.push({ code: 'invalid_value', path: `${path}/endDayOffset` });
  if (Object.hasOwn(v, 'endTime') && Object.hasOwn(v, 'endDayOffset') && (v.endTime === null) !== (v.endDayOffset === null)) errors.push({ code: 'invalid_value', path: `${path}/endDayOffset` });
  if (v.endDayOffset === 0 && typeof v.startTime === 'string' && typeof v.endTime === 'string' && v.endTime <= v.startTime) errors.push({ code: 'invalid_range', path: `${path}/endTime` });
  for (const k of ['seedTimeResolution', 'endTimeResolution']) if (Object.hasOwn(v, k) && ![null, 'earlier', 'later'].includes(v[k])) errors.push({ code: 'invalid_value', path: `${path}/${k}` });
}
