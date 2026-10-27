import WidgetKit
import SwiftUI

// MARK: - Modello Promemoria Widget

public struct WidgetReminderItem: Codable, Identifiable {
    public let id: String
    public let title: String
    public let timeString: String
    public let isCompleted: Bool
    public let date: Date

    public init(id: String, title: String, timeString: String, isCompleted: Bool, date: Date) {
        self.id = id
        self.title = title
        self.timeString = timeString
        self.isCompleted = isCompleted
        self.date = date
    }
}

// MARK: - Formattatori Date

enum DateHelper {
    static let weekdayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "it_IT")
        f.dateFormat = "EEEE"
        return f
    }()

    static let shortDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "it_IT")
        f.dateFormat = "E d MMM"
        return f
    }()

    static let fullDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "it_IT")
        f.dateFormat = "EEEE d MMMM"
        return f
    }()

    static func relativeDayString(for date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) {
            return "Oggi"
        } else if cal.isDateInTomorrow(date) {
            return "Domani"
        } else {
            return shortDateFormatter.string(from: date).capitalized
        }
    }
}

// MARK: - Timeline Entry

struct ReminderEntry: TimelineEntry {
    let date: Date
    let reminders: [WidgetReminderItem]

    var todayReminders: [WidgetReminderItem] {
        let cal = Calendar.current
        return reminders.filter { cal.isDateInToday($0.date) }
            .sorted { $0.date < $1.date }
    }

    var upcomingReminders: [WidgetReminderItem] {
        let cal = Calendar.current
        return reminders.filter { !cal.isDateInToday($0.date) && $0.date >= Date() }
            .sorted { $0.date < $1.date }
    }

    var nextUpcoming: WidgetReminderItem? {
        todayReminders.first(where: { $0.date >= Date() }) ?? todayReminders.first ?? upcomingReminders.first
    }
}

// MARK: - Provider

struct ReminderProvider: TimelineProvider {
    func placeholder(in context: Context) -> ReminderEntry {
        let now = Date()
        let cal = Calendar.current
        let event1Time = cal.date(bySettingHour: 10, minute: 30, second: 0, of: now) ?? now
        let event2Time = cal.date(bySettingHour: 17, minute: 0, second: 0, of: now) ?? now

        return ReminderEntry(
            date: now,
            reminders: [
                WidgetReminderItem(id: "1", title: "Dentista", timeString: "10:30", isCompleted: false, date: event1Time),
                WidgetReminderItem(id: "2", title: "Comprare il pane", timeString: "17:00", isCompleted: false, date: event2Time)
            ]
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (ReminderEntry) -> Void) {
        if context.isPreview {
            completion(placeholder(in: context))
        } else {
            let entry = loadCurrentEntry()
            if entry.reminders.isEmpty {
                completion(placeholder(in: context))
            } else {
                completion(entry)
            }
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ReminderEntry>) -> Void) {
        let entry = loadCurrentEntry()
        let now = Date()
        let cal = Calendar.current

        // Ricarica programmata: alla mezzanotte (cambio giorno) oppure ogni 15 minuti
        let midnight = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: now)) ?? now.addingTimeInterval(3600)
        let refreshDate = min(midnight, now.addingTimeInterval(15 * 60))

        let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
        completion(timeline)
    }

    private func loadCurrentEntry() -> ReminderEntry {
        var items: [WidgetReminderItem] = []

        if let groupDefaults = UserDefaults(suiteName: "group.com.saturnmoon.simply"),
           let data = groupDefaults.data(forKey: "simply_widget_reminders"),
           let decoded = try? JSONDecoder().decode([WidgetReminderItem].self, from: data) {
            items = decoded
        } else if let data = UserDefaults.standard.data(forKey: "simply_widget_reminders"),
                  let decoded = try? JSONDecoder().decode([WidgetReminderItem].self, from: data) {
            items = decoded
        }

        let filtered = items.filter { !$0.isCompleted }
        return ReminderEntry(date: Date(), reminders: filtered)
    }
}

// MARK: - Root Entry View

struct SimplyWidgetEntryView: View {
    var entry: ReminderProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                SmallReminderWidgetView(entry: entry)
            case .systemMedium:
                MediumReminderWidgetView(entry: entry)
            case .systemLarge, .systemExtraLarge:
                LargeReminderWidgetView(entry: entry)
            case .accessoryRectangular:
                AccessoryRectangularWidgetView(entry: entry)
            case .accessoryInline:
                AccessoryInlineWidgetView(entry: entry)
            default:
                MediumReminderWidgetView(entry: entry)
            }
        }
        .widgetBackground(Color(uiColor: .systemBackground))
    }
}

// MARK: - 1. Widget Piccolo (.systemSmall)

struct SmallReminderWidgetView: View {
    let entry: ReminderProvider.Entry

    private var weekday: String {
        DateHelper.weekdayFormatter.string(from: entry.date).uppercased()
    }

    private var dayNumber: String {
        let f = DateFormatter()
        f.dateFormat = "d"
        return f.string(from: entry.date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header: giorno e numero data
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(weekday)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.blue)
                        .lineLimit(1)
                    Text(dayNumber)
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundStyle(.primary)
                }
                Spacer()

                if !entry.todayReminders.isEmpty {
                    Text("\(entry.todayReminders.count)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 20, height: 20)
                        .background(Color.blue)
                        .clipShape(Circle())
                }
            }

            Spacer()

            if let current = entry.todayReminders.first {
                VStack(alignment: .leading, spacing: 3) {
                    Text(current.timeString)
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                        .foregroundStyle(.blue)

                    Text(current.title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)

                    if entry.todayReminders.count > 1 {
                        Text("+\(entry.todayReminders.count - 1) altri oggi")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
            } else if let next = entry.upcomingReminders.first {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Nessun impegno oggi")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)

                    Text(DateHelper.relativeDayString(for: next.date))
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.blue)

                    Text(next.title)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text(next.timeString)
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            } else {
                VStack(alignment: .leading, spacing: 3) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.green)
                    Text("Nessun impegno")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.primary)
                    Text("Tutto libero per oggi")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(14)
        .widgetURL(URL(string: "simply://calendar"))
    }
}

// MARK: - 2. Widget Medio (.systemMedium)

struct MediumReminderWidgetView: View {
    let entry: ReminderProvider.Entry

    private var fullDateString: String {
        DateHelper.fullDateFormatter.string(from: entry.date).capitalized
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header pulito con data completa di oggi
            HStack {
                Text(fullDateString)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.blue)

                Spacer()

                if !entry.todayReminders.isEmpty {
                    Text("\(entry.todayReminders.count) OGGI")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.secondary)
                }
            }

            Divider()
                .overlay(Color.primary.opacity(0.08))

            if !entry.todayReminders.isEmpty {
                VStack(alignment: .leading, spacing: 5) {
                    ForEach(entry.todayReminders.prefix(3)) { item in
                        HStack(spacing: 8) {
                            Text(item.timeString)
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundStyle(.blue)
                                .frame(width: 42, alignment: .leading)

                            Text(item.title)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.primary)
                                .lineLimit(1)

                            Spacer()

                            Circle()
                                .stroke(Color.primary.opacity(0.2), lineWidth: 1.5)
                                .frame(width: 13, height: 13)
                        }
                    }
                }
                Spacer()
            } else if let next = entry.upcomingReminders.first {
                Spacer()
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(.green)
                        Text("Nessun impegno oggi")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.primary)
                    }

                    HStack(spacing: 6) {
                        Text("Prossimo:")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                        Text("\(DateHelper.relativeDayString(for: next.date)) alle \(next.timeString) - \(next.title)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.blue)
                            .lineLimit(1)
                    }
                    .padding(.top, 2)
                }
                Spacer()
            } else {
                Spacer()
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(.green)
                    Text("Nessun impegno in programma!")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                Spacer()
            }
        }
        .padding(14)
        .widgetURL(URL(string: "simply://calendar"))
    }
}

// MARK: - 3. Widget Grande (.systemLarge - formato da 4 piccoli)

struct LargeReminderWidgetView: View {
    let entry: ReminderProvider.Entry

    private var weekday: String {
        DateHelper.weekdayFormatter.string(from: entry.date).uppercased()
    }

    private var dayNumber: String {
        let f = DateFormatter()
        f.dateFormat = "d"
        return f.string(from: entry.date)
    }

    private var monthYear: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "it_IT")
        f.dateFormat = "MMMM yyyy"
        return f.string(from: entry.date).capitalized
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header Grande con calendario e conteggio
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(weekday)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.blue)
                    HStack(spacing: 8) {
                        Text(dayNumber)
                            .font(.system(size: 28, weight: .heavy, design: .rounded))
                            .foregroundStyle(.primary)
                        Text(monthYear)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                if !entry.todayReminders.isEmpty {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(entry.todayReminders.count)")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(.blue)
                        Text("impegni oggi")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.primary.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }

            Divider()
                .overlay(Color.primary.opacity(0.08))

            // Sezione Impegni di Oggi
            VStack(alignment: .leading, spacing: 6) {
                Text("IMPEGNI DI OGGI")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.secondary)

                if entry.todayReminders.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 15))
                            .foregroundStyle(.green)
                        Text("Nessun impegno previsto per oggi")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                } else {
                    ForEach(entry.todayReminders.prefix(4)) { item in
                        HStack(spacing: 10) {
                            Text(item.timeString)
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundStyle(.blue)
                                .frame(width: 44, alignment: .leading)

                            Text(item.title)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.primary)
                                .lineLimit(1)

                            Spacer()

                            Circle()
                                .stroke(Color.primary.opacity(0.2), lineWidth: 1.5)
                                .frame(width: 14, height: 14)
                        }
                        .padding(.vertical, 3)
                    }
                }
            }

            // Sezione Prossimi Giorni
            if !entry.upcomingReminders.isEmpty {
                Divider()
                    .overlay(Color.primary.opacity(0.08))

                VStack(alignment: .leading, spacing: 6) {
                    Text("PROSSIMI GIORNI")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.secondary)

                    ForEach(entry.upcomingReminders.prefix(3)) { item in
                        HStack(spacing: 10) {
                            Text(DateHelper.relativeDayString(for: item.date))
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.blue)
                                .frame(width: 65, alignment: .leading)

                            Text(item.timeString)
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundStyle(.secondary)

                            Text(item.title)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.primary)
                                .lineLimit(1)

                            Spacer()
                        }
                        .padding(.vertical, 2)
                    }
                }
            }

            Spacer()
        }
        .padding(16)
        .widgetURL(URL(string: "simply://calendar"))
    }
}

// MARK: - 4. Widget Schermata di Blocco (.accessoryRectangular & .accessoryInline)

struct AccessoryRectangularWidgetView: View {
    let entry: ReminderProvider.Entry

    var body: some View {
        if let current = entry.nextUpcoming {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(DateHelper.relativeDayString(for: current.date))
                        .font(.system(size: 10, weight: .bold))
                    Text(current.timeString)
                        .font(.system(size: 10, weight: .medium))
                }
                Text(current.title)
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)

                if entry.todayReminders.count > 1 {
                    Text("+\(entry.todayReminders.count - 1) altri oggi")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                }
            }
        } else {
            VStack(alignment: .leading, spacing: 2) {
                Text("Simply")
                    .font(.system(size: 10, weight: .bold))
                Text("Nessun impegno")
                    .font(.system(size: 12, weight: .semibold))
            }
        }
    }
}

struct AccessoryInlineWidgetView: View {
    let entry: ReminderProvider.Entry

    var body: some View {
        if let current = entry.nextUpcoming {
            Text("\(current.timeString) \(current.title)")
        } else {
            Text("Nessun impegno")
        }
    }
}

// MARK: - Helper Background Dinamico (Chiaro e Scuro)

extension View {
    func widgetBackground(_ color: Color = Color(uiColor: .systemBackground)) -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            return AnyView(self.containerBackground(color, for: .widget))
        } else {
            return AnyView(self.background(color))
        }
    }
}

// MARK: - Main Widget Bundle & Configuration

@main
struct SimplyWidgetBundle: WidgetBundle {
    var body: some Widget {
        SimplyWidgets()
    }
}

struct SimplyWidgets: Widget {
    let kind: String = "SimplyWidgets"

    private var supportedFamiliesList: [WidgetFamily] {
        var families: [WidgetFamily] = [
            .systemSmall,
            .systemMedium,
            .systemLarge,
            .accessoryRectangular,
            .accessoryInline
        ]
        #if !os(watchOS)
        if #available(iOSApplicationExtension 17.0, *) {
            families.append(.systemExtraLarge)
        }
        #endif
        return families
    }

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ReminderProvider()) { entry in
            SimplyWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Simply Promemoria")
        .description("Visualizza gli impegni di oggi e i prossimi promemoria.")
        .supportedFamilies(supportedFamiliesList)
        .contentMarginsDisabled()
    }
}
