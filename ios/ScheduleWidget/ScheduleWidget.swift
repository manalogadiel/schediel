// Schediel home screen widget (WidgetKit). UNTESTED: written on Windows
// without Xcode; build and verify on a Mac before relying on it. Mirrors
// android/app/src/main/kotlin/com/manalogadiel/schediel/widget and the
// widget-snapshot-v1 reader rules (contracts/schemas/widget-snapshot-v1.schema.json).

import SwiftUI
import WidgetKit

private let appGroup = "group.com.manalogadiel.schediel"
private let snapshotKey = "schediel_widget_snapshot"

// MARK: - Reader (x-readerRules R01-R07, R10)

enum ReadState { case entries, empty, stale, unsupported }

enum ReadMessage: String {
    case openApp = "Open Schediel"
    case openAppToUpdate = "Open Schediel to update"
    case noSchedules = "No schedules yet"
    case noneInFilter = "No schedules in this filter"
    case noUpcoming = "No upcoming schedules"
}

struct WidgetSettings {
    let layout: String
    let surface: String
    let textTone: String
    let nextEmphasis: Bool
}

struct SnapshotEntry: Identifiable {
    let id: String
    let title: String
    let start: Date?
    let end: Date?
    /// Local start date as yyyy-MM-dd.
    let startDate: String
    let zoneLabel: String?
    let details: String?
    let deepLink: String
}

struct ReadResult {
    var state: ReadState
    var message: ReadMessage?
    var settings: WidgetSettings?
    var ongoing: [SnapshotEntry] = []
    var next: SnapshotEntry?
    var upcoming: [SnapshotEntry] = []
    var allDay: [SnapshotEntry] = []
    var needsReview: [SnapshotEntry] = []
    var nextRefresh: Date?

    static let openApp = ReadResult(state: .unsupported, message: .openApp)
}

enum SnapshotReader {
    private static func isoDate(_ date: Date, _ calendar: Calendar) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }

    private static func instant(_ text: String) -> Date? {
        let fractional = ISO8601DateFormatter()
        fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return fractional.date(from: text) ?? ISO8601DateFormatter().date(from: text)
    }

    private static func epoch(_ value: Any?) -> Date? {
        guard let number = value as? NSNumber else { return nil }
        return Date(timeIntervalSince1970: number.doubleValue / 1000)
    }

    static func read(_ raw: String?, widgetKey: String, now: Date, calendar: Calendar) -> ReadResult {
        guard let raw, let data = raw.data(using: .utf8),
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              root["schemaVersion"] as? String == "1.0",
              let coverageText = root["coverageEnd"] as? String,
              let coverageEnd = instant(coverageText),
              let widgets = root["widgets"] as? [String: Any],
              let projection = (widgets[widgetKey] ?? widgets["default"]) as? [String: Any],
              let config = projection["configuration"] as? [String: Any],
              let layout = config["layout"] as? String,
              let surface = config["surface"] as? String,
              let textTone = config["textTone"] as? String,
              let nextEmphasis = config["nextEmphasis"] as? Bool,
              let occurrences = projection["occurrences"] as? [[String: Any]]
        else { return .openApp }

        if now >= coverageEnd { return ReadResult(state: .stale, message: .openAppToUpdate) }
        let settings = WidgetSettings(layout: layout, surface: surface, textTone: textTone, nextEmphasis: nextEmphasis)
        let startOfToday = calendar.startOfDay(for: now)
        let midnight = calendar.date(byAdding: .day, value: 1, to: startOfToday) ?? coverageEnd
        var refresh = min(midnight, coverageEnd)

        switch projection["emptyReason"] as? String {
        case "noSchedules": return ReadResult(state: .empty, message: .noSchedules, settings: settings, nextRefresh: refresh)
        case "noneInFilter": return ReadResult(state: .empty, message: .noneInFilter, settings: settings, nextRefresh: refresh)
        default: break
        }

        let today = isoDate(now, calendar)
        var ongoing: [SnapshotEntry] = []
        var future: [SnapshotEntry] = []
        var allDay: [SnapshotEntry] = []
        var needsReview: [SnapshotEntry] = []
        for raw in occurrences {
            guard let id = raw["occurrenceId"] as? String,
                  let title = raw["title"] as? String,
                  let kind = raw["kind"] as? String,
                  let startDate = raw["startDate"] as? String,
                  let deepLink = raw["deepLink"] as? String,
                  deepLink.hasPrefix("schediel://occurrence/")
            else { return .openApp }
            let details = [raw["location"], raw["professor"], raw["subtitle"]]
                .compactMap { $0 as? String }
                .filter { !$0.isEmpty }
                .joined(separator: " · ")
            let entry = SnapshotEntry(
                id: id,
                title: title,
                start: epoch(raw["startEpochMs"]),
                end: epoch(raw["endEpochMs"]),
                startDate: startDate,
                zoneLabel: raw["zoneLabel"] as? String,
                details: details.isEmpty ? nil : details,
                deepLink: deepLink
            )
            if kind == "dateOnly" {
                guard let endExclusive = raw["endDateExclusive"] as? String else { return .openApp }
                if today >= startDate && today < endExclusive { allDay.append(entry) }
                continue
            }
            if raw["timeStatus"] as? String == "needsTimeReview" {
                if startDate >= today { needsReview.append(entry) }
                continue
            }
            guard let start = entry.start else { return .openApp }
            if let end = entry.end {
                if start <= now && now < end { ongoing.append(entry) } else if now < start { future.append(entry) }
                if end > now { refresh = min(refresh, end) }
            } else if now < start {
                future.append(entry)
            }
            if start > now { refresh = min(refresh, start) }
        }
        // Stable sort: ties keep snapshot order (R02).
        let sorted = future.enumerated()
            .sorted { ($0.element.start!, $0.offset) < ($1.element.start!, $1.offset) }
            .map(\.element)
        if ongoing.isEmpty && sorted.isEmpty && allDay.isEmpty && needsReview.isEmpty {
            return ReadResult(state: .empty, message: .noUpcoming, settings: settings, nextRefresh: refresh)
        }
        return ReadResult(
            state: .entries,
            settings: settings,
            ongoing: ongoing,
            next: sorted.first,
            upcoming: Array(sorted.dropFirst()),
            allDay: allDay,
            needsReview: needsReview,
            nextRefresh: refresh
        )
    }
}

// MARK: - Timeline

struct ScheduleEntry: TimelineEntry {
    let date: Date
    let result: ReadResult
}

struct ScheduleProvider: TimelineProvider {
    private func read(at date: Date) -> ReadResult {
        let raw = UserDefaults(suiteName: appGroup)?.string(forKey: snapshotKey)
        // iOS widgets use the "default" projection.
        return SnapshotReader.read(raw, widgetKey: "default", now: date, calendar: .current)
    }

    func placeholder(in context: Context) -> ScheduleEntry {
        ScheduleEntry(date: Date(), result: .openApp)
    }

    func getSnapshot(in context: Context, completion: @escaping (ScheduleEntry) -> Void) {
        let now = Date()
        completion(ScheduleEntry(date: now, result: read(at: now)))
    }

    /// Precomputes entries at each occurrence boundary, local midnight and
    /// coverage end (R10). WidgetKit budgets reloads; no exact time is promised.
    func getTimeline(in context: Context, completion: @escaping (Timeline<ScheduleEntry>) -> Void) {
        var date = Date()
        var entries: [ScheduleEntry] = []
        var last = read(at: date)
        entries.append(ScheduleEntry(date: date, result: last))
        while entries.count < 24, let next = last.nextRefresh, next > date {
            date = next
            last = read(at: date)
            entries.append(ScheduleEntry(date: date, result: last))
        }
        let policy: TimelineReloadPolicy = last.nextRefresh.map { .after($0) } ?? .never
        completion(Timeline(entries: entries, policy: policy))
    }
}

// MARK: - Views

private struct Palette {
    let primary: Color
    let secondary: Color
    let nextFill: Color
    let upcomingFill: Color
    let outline: Color

    // Mirrors lib/features/widgets/domain/widget_style.dart.
    init(surface: String, light: Bool) {
        primary = light ? .white : Color(red: 0.114, green: 0.114, blue: 0.122)
        secondary = light ? Color.white.opacity(0.78) : Color(red: 0.227, green: 0.227, blue: 0.235)
        outline = light ? Color.white.opacity(0.35) : Color.black.opacity(0.12)
        switch (surface, light) {
        case ("softTint", true):
            nextFill = Color(red: 0.227, green: 0.227, blue: 0.235).opacity(0.55)
            upcomingFill = Color(red: 0.11, green: 0.11, blue: 0.118).opacity(0.4)
        case ("softTint", false):
            nextFill = Color.white.opacity(0.85)
            upcomingFill = Color(red: 0.949, green: 0.949, blue: 0.969).opacity(0.65)
        case ("solid", true):
            nextFill = Color(red: 0.227, green: 0.227, blue: 0.235)
            upcomingFill = Color(red: 0.11, green: 0.11, blue: 0.118)
        case ("solid", false):
            nextFill = .white
            upcomingFill = Color(red: 0.898, green: 0.898, blue: 0.918)
        case (_, true):
            nextFill = Color.white.opacity(0.18)
            upcomingFill = Color.white.opacity(0.06)
        default:
            nextFill = Color.white.opacity(0.6)
            upcomingFill = Color.white.opacity(0.32)
        }
    }
}

private enum RowStatus { case now, next, upcoming, review }

private struct Row: Identifiable {
    let entry: SnapshotEntry
    let status: RowStatus
    let emphasized: Bool
    var id: String { entry.id }
}

struct ScheduleWidgetView: View {
    let entry: ScheduleEntry
    @Environment(\.widgetFamily) private var family
    @Environment(\.dynamicTypeSize) private var typeSize

    private var result: ReadResult { entry.result }

    private var maxRows: Int {
        let compact = result.settings?.layout == "compact"
        switch family {
        case .systemLarge: return compact ? 2 : 4
        default: return 2
        }
    }

    /// Large text hides details before entries (spec 5.3).
    private var showDetails: Bool {
        result.settings?.layout == "expanded" && family == .systemLarge && typeSize < .xxLarge
    }

    private var rows: [Row] {
        var rows: [Row] = result.ongoing.map { Row(entry: $0, status: .now, emphasized: false) }
        if let next = result.next {
            rows.append(Row(entry: next, status: .next, emphasized: result.settings?.nextEmphasis ?? true))
        }
        rows += result.upcoming.map { Row(entry: $0, status: .upcoming, emphasized: false) }
        rows += result.needsReview.prefix(1).map { Row(entry: $0, status: .review, emphasized: false) }
        let limit = typeSize >= .accessibility1 ? 1 : maxRows
        return Array(rows.prefix(limit))
    }

    var body: some View {
        let palette = Palette(surface: result.settings?.surface ?? "clear", light: (result.settings?.textTone ?? "light") == "light")
        VStack(alignment: .leading, spacing: 6) {
            if result.state == .entries {
                ForEach(result.allDay.prefix(family == .systemSmall ? 1 : 2)) { item in
                    Text("All day · \(item.title)")
                        .font(.caption)
                        .foregroundStyle(palette.secondary)
                        .lineLimit(1)
                }
                ForEach(rows) { row in
                    holder(row, palette)
                }
            } else {
                Text(result.message?.rawValue ?? ReadMessage.openApp.rawValue)
                    .font(.subheadline)
                    .foregroundStyle(palette.primary)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .widgetURL(URL(string: "schediel://today?homeWidget"))
        .containerBackground(for: .widget) { Color.clear }
    }

    @ViewBuilder
    private func holder(_ row: Row, _ palette: Palette) -> some View {
        let content = VStack(alignment: .leading, spacing: 1) {
            timeLine(row)
                .font(.caption.weight(.medium))
                .foregroundStyle(palette.secondary)
                .lineLimit(1)
            Text(row.entry.title)
                .font(.subheadline.weight(row.emphasized ? .bold : .semibold))
                .foregroundStyle(palette.primary)
                .lineLimit(1)
                .widgetAccentable()
            if showDetails, let details = row.entry.details {
                Text(details)
                    .font(.caption)
                    .foregroundStyle(palette.secondary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(row.emphasized ? palette.nextFill : palette.upcomingFill)
        )
        .overlay {
            if row.emphasized {
                RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(palette.outline, lineWidth: 1)
            }
        }
        .accessibilityElement(children: .combine)
        if family == .systemSmall {
            content
        } else if let url = URL(string: row.entry.deepLink + "?homeWidget") {
            Link(destination: url) { content }
        } else {
            content
        }
    }

    /// Status, explicit date when not today (R05), time or review text, zone label (R09).
    private func timeLine(_ row: Row) -> Text {
        var parts: [Text] = []
        switch row.status {
        case .now: parts.append(Text("Now"))
        case .next: parts.append(Text("Next"))
        default: break
        }
        let calendar = Calendar.current
        let start = row.entry.start
        let isToday = start.map { calendar.isDate($0, inSameDayAs: entry.date) } ?? false
        if let start, !isToday {
            parts.append(Text(start, format: .dateTime.weekday(.abbreviated).month(.abbreviated).day()))
        }
        if row.status == .review || start == nil {
            parts.append(Text("Time needs review"))
        } else if let start {
            var range = Text(start, format: .dateTime.hour().minute())
            if let end = row.entry.end {
                range = range + Text(" – ") + Text(end, format: .dateTime.hour().minute())
            }
            if let zone = row.entry.zoneLabel {
                range = range + Text(" (\(zone))")
            }
            parts.append(range)
        }
        return parts.dropFirst().reduce(parts.first ?? Text("")) { $0 + Text(" · ") + $1 }
    }
}

// MARK: - Widget

@main
struct ScheduleWidgetBundle: WidgetBundle {
    var body: some Widget {
        ScheduleWidget()
    }
}

struct ScheduleWidget: Widget {
    /// Must match iOSWidgetKind in lib/features/widgets/application/widget_snapshot_service.dart.
    let kind = "ScheduleWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ScheduleProvider()) { entry in
            ScheduleWidgetView(entry: entry)
        }
        .configurationDisplayName("Schedules")
        .description("Your next and upcoming schedules")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
