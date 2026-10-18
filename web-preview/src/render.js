const DETAIL_LABELS = { location: 'Location', professor: 'Professor', subtitle: 'Subtitle', notes: 'Notes' };
const WEEKDAYS = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

export function renderPreview(document, result, { locale, timeZone }) {
  function node(tag, text, className) {
    const element = document.createElement(tag);
    if (text !== undefined) element.textContent = text;
    if (className) element.className = className;
    return element;
  }
  // UTC here is only a stable calendar formatter, never a date-only event instant.
  const dateFormatter = new Intl.DateTimeFormat(locale, { dateStyle: 'medium', timeZone: 'UTC' });
  const calendarDate = value => dateFormatter.format(new Date(`${value}T00:00:00Z`));
  function previousDate(value) {
    const day = new Date(`${value}T00:00:00Z`);
    day.setUTCDate(day.getUTCDate() - 1);
    return day.toISOString().slice(0, 10);
  }
  function renderTime(parent, time, recurring = false) {
    const date = calendarDate(time.startDate);
    let label;
    if (time.kind === 'dateOnly') {
      const last = previousDate(time.endDateExclusive);
      label = `All day, ${date}${last === time.startDate ? '' : ` – ${calendarDate(last)}`}`;
      if (recurring) label += ' (series start)';
    } else {
      label = `${recurring ? 'From ' : ''}${date}, ${time.startTime}`;
      label += time.endTime === null ? ', no end time' : `–${time.endTime}${time.endDayOffset === 1 ? ' (next day)' : ''}`;
    }
    parent.append(node('p', label, 'schedule-time'));
    if (time.kind === 'timed') {
      if (time.timeZone !== timeZone) parent.append(node('p', `${time.timeZone} time`, 'source-zone'));
      const choices = [];
      if (time.seedTimeResolution !== null) choices.push(`Start time resolution: ${time.seedTimeResolution}.`);
      if (time.endTimeResolution !== null) choices.push(`End time resolution: ${time.endTimeResolution}.`);
      if (choices.length) parent.append(node('p', choices.join(' '), 'time-resolution'));
    }
  }
  function renderDetails(parent, details) {
    const list = node('dl', undefined, 'details');
    for (const [key, label] of Object.entries(DETAIL_LABELS)) {
      if (details[key] !== null) list.append(node('dt', label), node('dd', details[key]));
    }
    if (list.children.length) parent.append(list);
  }
  function renderRecurrence(parent, item) {
    if (!item.recurrence) return;
    const rule = item.recurrence;
    let label = rule.frequency === 'daily' ? 'Daily' : `Weekly on ${new Intl.ListFormat(locale, { type: 'conjunction' }).format([...rule.weekdays].sort((a, b) => a - b).map(day => WEEKDAYS[day - 1]))}`;
    label += rule.untilDateInclusive === null ? ', no end date.' : `, through ${calendarDate(rule.untilDateInclusive)} (inclusive).`;
    parent.append(node('p', label, 'recurrence'));
    if (!item.exceptions.length) return;
    const disclosure = node('details', undefined, 'exceptions');
    disclosure.append(node('summary', `${item.exceptions.length} ${item.exceptions.length === 1 ? 'exception' : 'exceptions'}`));
    const list = node('ul');
    for (const entry of item.exceptions) {
      const row = node('li', undefined, 'exception');
      row.append(node('p', `${calendarDate(entry.originalOccurrenceKey)}: ${entry.action === 'cancel' ? 'Cancelled occurrence' : 'Changed occurrence'}`));
      if (entry.replacement !== null) {
        row.append(node('h3', entry.replacement.title));
        renderTime(row, entry.replacement.time);
        renderDetails(row, entry.replacement.details);
      }
      list.append(row);
    }
    disclosure.append(list);
    parent.append(disclosure);
  }
  const count = result.payload.items.length;
  document.querySelector('#item-count').textContent = `${count} ${count === 1 ? 'schedule' : 'schedules'}`;
  const expiry = node('time', new Intl.DateTimeFormat(locale, { dateStyle: 'medium', timeStyle: 'short', timeZone }).format(new Date(result.expiresAt)));
  expiry.dateTime = result.expiresAt;
  document.querySelector('#expires').replaceChildren(document.createTextNode('Expires '), expiry, document.createTextNode(` (${timeZone})`));
  const list = document.querySelector('#items');
  for (const item of result.payload.items) {
    const row = node('li', undefined, 'schedule');
    row.append(node('p', item.categoryLabel ?? 'Uncategorized', 'category'), node('h2', item.title));
    renderTime(row, item.time, item.recurrence !== null);
    renderDetails(row, item.details);
    renderRecurrence(row, item);
    list.append(row);
  }
}
