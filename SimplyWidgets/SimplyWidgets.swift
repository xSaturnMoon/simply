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

// MARK: - Timeline Entry

struct ReminderEntry: TimelineEntry {
    let date: Date
    let reminders: [WidgetReminderItem]
}

// MARK: - Provider

struct ReminderProvider: TimelineProvider {
    func placeholder(in context: Context) -> ReminderEntry {
        ReminderEntry(
            date: Date(),
            reminders: [
                WidgetReminderItem(id: "1", title: "Dentista", timeString: "10:30", isCompleted: false, date: Date()),
                WidgetReminderItem(id: "2", title: "Comprare il pane", timeString: "17:00", isCompleted: false, date: Date())
            ]
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (ReminderEntry) -> Void) {
        let entry = loadCurrentEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ReminderEntry>) -> Void) {
        let entry = loadCurrentEntry()
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date().addingTimeInterval(1800)
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
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

// MARK: - Widget Views

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
            default:
                MediumReminderWidgetView(entry: entry)
            }
        }
        .widgetBackground(Color.black)
    }
}

// Widget Piccolo
struct SmallReminderWidgetView: View {
    let entry: ReminderProvider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "calendar")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.blue)
                Text("Simply")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                Spacer()
                if !entry.reminders.isEmpty {
                    Text("\(entry.reminders.count)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue)
                        .clipShape(Capsule())
                }
            }

            Spacer()

            if let first = entry.reminders.first {
                VStack(alignment: .leading, spacing: 4) {
                    Text(first.timeString)
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundStyle(.blue)

                    Text(first.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(.green)
                        .padding(.bottom, 2)
                    Text("Tutto fatto")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                    Text("Nessun promemoria")
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.6))
                }
            }

            Spacer()
        }
        .padding(14)
        .widgetURL(URL(string: "simply://calendar"))
    }
}

// Widget Medio
struct MediumReminderWidgetView: View {
    let entry: ReminderProvider.Entry

    private var formattedDate: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "it_IT")
        f.dateFormat = "EEEE d MMMM"
        return f.string(from: Date()).capitalized
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Image(systemName: "calendar")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.blue)
                Text("Simply Promemoria")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)

                Spacer()

                Text(formattedDate)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
            }

            Divider()
                .overlay(Color.white.opacity(0.12))

            if entry.reminders.isEmpty {
                Spacer()
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.green)
                    Text("Nessun impegno in programma!")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.7))
                }
                .frame(maxWidth: .infinity, alignment: .center)
                Spacer()
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(entry.reminders.prefix(3)) { item in
                        HStack(spacing: 10) {
                            Text(item.timeString)
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundStyle(.blue)
                                .frame(width: 44, alignment: .leading)

                            Text(item.title)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.white)
                                .lineLimit(1)

                            Spacer()

                            Circle()
                                .stroke(Color.white.opacity(0.25), lineWidth: 1.5)
                                .frame(width: 14, height: 14)
                        }
                        .padding(.vertical, 2)
                    }
                }
                Spacer()
            }
        }
        .padding(14)
        .widgetURL(URL(string: "simply://calendar"))
    }
}

// MARK: - Compatibility Helper

extension View {
    func widgetBackground(_ color: Color = .black) -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            return AnyView(self.containerBackground(color, for: .widget))
        } else {
            return AnyView(self.background(color))
        }
    }
}

// MARK: - Main Widget

@main
struct SimplyWidgets: Widget {
    let kind: String = "SimplyWidgets"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ReminderProvider()) { entry in
            SimplyWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Simply Promemoria")
        .description("Visualizza rapidamente i tuoi prossimi appuntamenti e promemoria.")
        .supportedFamilies([.systemSmall, .systemMedium])
        .contentMarginsDisabled()
    }
}
