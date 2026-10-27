import WidgetKit
import SwiftUI
import UIKit

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

    static let shortWeekdayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "it_IT")
        f.dateFormat = "EEE"
        return f
    }()

    static let monthFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "it_IT")
        f.dateFormat = "MMMM"
        return f
    }()

    static let fullDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "it_IT")
        f.dateFormat = "EEEE d MMMM"
        return f
    }()

    static func dayLabel(for date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) {
            return "Oggi"
        } else if cal.isDateInTomorrow(date) {
            return "Domani"
        } else {
            return shortWeekdayFormatter.string(from: date).capitalized
        }
    }
}

// MARK: - Timeline Entry

struct ReminderEntry: TimelineEntry {
    let date: Date
    let reminders: [WidgetReminderItem]

    /// Impegni di oggi non ancora terminati (mantenuti visibili fino a 30 minuti dopo l'inizio)
    var todayActive: [WidgetReminderItem] {
        let cal = Calendar.current
        let threshold = date.addingTimeInterval(-30 * 60)
        return reminders.filter { cal.isDateInToday($0.date) && $0.date >= threshold }
            .sorted { $0.date < $1.date }
    }

    /// Tutti gli impegni futuri ordinati
    var allUpcoming: [WidgetReminderItem] {
        let threshold = date.addingTimeInterval(-30 * 60)
        return reminders.filter { $0.date >= threshold }
            .sorted { $0.date < $1.date }
    }

    /// Prossimo impegno futuro
    var nextItem: WidgetReminderItem? {
        todayActive.first ?? allUpcoming.first
    }
}

// MARK: - Provider

struct ReminderProvider: TimelineProvider {
    func placeholder(in context: Context) -> ReminderEntry {
        let now = Date()
        let cal = Calendar.current
        let event1 = cal.date(bySettingHour: 10, minute: 30, second: 0, of: now) ?? now
        let event2 = cal.date(bySettingHour: 17, minute: 0, second: 0, of: now) ?? now

        return ReminderEntry(
            date: now,
            reminders: [
                WidgetReminderItem(id: "1", title: "Dentista", timeString: "10:30", isCompleted: false, date: event1),
                WidgetReminderItem(id: "2", title: "Comprare il pane", timeString: "17:00", isCompleted: false, date: event2)
            ]
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (ReminderEntry) -> Void) {
        if context.isPreview {
            completion(placeholder(in: context))
        } else {
            let entry = ReminderEntry(date: Date(), reminders: loadCurrentItems())
            if entry.reminders.isEmpty {
                completion(placeholder(in: context))
            } else {
                completion(entry)
            }
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ReminderEntry>) -> Void) {
        let now = Date()
        let cal = Calendar.current
        let allItems = loadCurrentItems()

        var entries: [ReminderEntry] = []
        entries.append(ReminderEntry(date: now, reminders: allItems))

        // Aggiungi entry per ogni transizione di orario di oggi (+30 minuti dall'inizio)
        let todayItems = allItems.filter { cal.isDateInToday($0.date) }
        for item in todayItems {
            let transitionTime = item.date.addingTimeInterval(30 * 60)
            if transitionTime > now {
                entries.append(ReminderEntry(date: transitionTime, reminders: allItems))
            }
        }

        // Aggiungi entry per la mezzanotte (scatto giorno successivo)
        if let midnight = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: now)) {
            entries.append(ReminderEntry(date: midnight, reminders: allItems))
        }

        let nextUpdate = now.addingTimeInterval(20 * 60)
        let timeline = Timeline(entries: entries, policy: .after(nextUpdate))
        completion(timeline)
    }

    private func loadCurrentItems() -> [WidgetReminderItem] {
        var items: [WidgetReminderItem] = []

        if let groupDefaults = UserDefaults(suiteName: "group.com.saturnmoon.simply"),
           let data = groupDefaults.data(forKey: "simply_widget_reminders"),
           let decoded = try? JSONDecoder().decode([WidgetReminderItem].self, from: data) {
            items = decoded
        } else if let data = UserDefaults.standard.data(forKey: "simply_widget_reminders"),
                  let decoded = try? JSONDecoder().decode([WidgetReminderItem].self, from: data) {
            items = decoded
        }

        return items.filter { !$0.isCompleted }
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
        .applyWidgetBackground(for: family)
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
        VStack(alignment: .leading, spacing: 0) {
            // Data in alto
            Text(weekday)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.blue)

            Text(dayNumber)
                .font(.system(size: 26, weight: .heavy, design: .rounded))
                .foregroundStyle(.primary)
                .padding(.bottom, 6)

            Spacer()

            if let item = entry.nextItem {
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.timeString)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.blue)

                    Text(item.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(.green)

                    Text("Nessun impegno")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .widgetURL(URL(string: "simply://calendar"))
    }
}

// MARK: - 2. Widget Medio (.systemMedium)

struct MediumReminderWidgetView: View {
    let entry: ReminderProvider.Entry

    private var weekday: String {
        DateHelper.weekdayFormatter.string(from: entry.date).capitalized
    }

    private var dayNumber: String {
        let f = DateFormatter()
        f.dateFormat = "d"
        return f.string(from: entry.date)
    }

    private var monthName: String {
        DateHelper.monthFormatter.string(from: entry.date).uppercased()
    }

    var body: some View {
        HStack(spacing: 16) {
            // Colonna Sinistra: Data pulita
            VStack(alignment: .leading, spacing: 2) {
                Text(monthName)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.blue)

                Text(dayNumber)
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                    .foregroundStyle(.primary)

                Text(weekday)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)

                Spacer()
            }
            .frame(width: 76, alignment: .leading)

            // Divisore
            Rectangle()
                .fill(Color.primary.opacity(0.08))
                .frame(width: 1)
                .padding(.vertical, 4)

            // Colonna Destra: Impegni
            VStack(alignment: .leading, spacing: 8) {
                if !entry.todayActive.isEmpty {
                    ForEach(entry.todayActive.prefix(3)) { item in
                        HStack(spacing: 8) {
                            Text(item.timeString)
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundStyle(.blue)
                                .frame(width: 44, alignment: .leading)

                            Text(item.title)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.primary)
                                .lineLimit(1)

                            Spacer()
                        }
                    }
                    Spacer()
                } else if let next = entry.allUpcoming.first {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Nessun impegno oggi")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.secondary)

                        HStack(spacing: 6) {
                            Text(DateHelper.dayLabel(for: next.date))
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.blue)

                            Text(next.timeString)
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundStyle(.secondary)

                            Text(next.title)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                        }
                    }
                    Spacer()
                } else {
                    VStack(alignment: .leading, spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(.green)

                        Text("Nessun impegno in programma")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .widgetURL(URL(string: "simply://calendar"))
    }
}

// MARK: - 3. Widget Grande (.systemLarge - formato da 4 piccoli)

struct LargeReminderWidgetView: View {
    let entry: ReminderProvider.Entry

    private var fullDate: String {
        DateHelper.fullDateFormatter.string(from: entry.date).capitalized
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header data pulito
            Text(fullDate)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.blue)

            Rectangle()
                .fill(Color.primary.opacity(0.08))
                .frame(height: 1)

            // Lista lineare impegni
            if entry.allUpcoming.isEmpty {
                Spacer()
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.green)
                    Text("Nessun impegno in programma")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                Spacer()
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(entry.allUpcoming.prefix(6)) { item in
                        HStack(spacing: 10) {
                            Text(DateHelper.dayLabel(for: item.date))
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Calendar.current.isDateInToday(item.date) ? Color.blue : Color.secondary)
                                .frame(width: 52, alignment: .leading)

                            Text(item.timeString)
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundStyle(.blue)
                                .frame(width: 44, alignment: .leading)

                            Text(item.title)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.primary)
                                .lineLimit(1)

                            Spacer()
                        }
                    }
                }
                Spacer()
            }
        }
        .padding(16)
        .widgetURL(URL(string: "simply://calendar"))
    }
}

// MARK: - 4. Widget Schermata di Blocco (.accessoryRectangular & .accessoryInline)

struct AccessoryRectangularWidgetView: View {
    let entry: ReminderProvider.Entry

    var body: some View {
        if let current = entry.nextItem {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(DateHelper.dayLabel(for: current.date))
                        .font(.system(size: 10, weight: .bold))
                    Text(current.timeString)
                        .font(.system(size: 10, weight: .medium))
                }
                Text(current.title)
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)
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
        if let current = entry.nextItem {
            Text("\(current.timeString) \(current.title)")
        } else {
            Text("Nessun impegno")
        }
    }
}

// MARK: - Helper Background Dinamico (Chiaro e Scuro)

extension View {
    @ViewBuilder
    func applyWidgetBackground(for family: WidgetFamily) -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            switch family {
            case .accessoryRectangular, .accessoryInline:
                self.containerBackground(.clear, for: .widget)
            default:
                self.containerBackground(Color(uiColor: .systemBackground), for: .widget)
            }
        } else {
            self.background(Color(uiColor: .systemBackground))
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

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ReminderProvider()) { entry in
            SimplyWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Simply Promemoria")
        .description("Visualizza gli impegni di oggi e i prossimi promemoria.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .systemLarge,
            .systemExtraLarge,
            .accessoryRectangular,
            .accessoryInline
        ])
        .contentMarginsDisabled()
    }
}
