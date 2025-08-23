import WidgetKit
import SwiftUI

struct HighScoreEntry: TimelineEntry {
    let date: Date
    let highScore: Int
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> HighScoreEntry {
        HighScoreEntry(date: Date(), highScore: 0)
    }

    func getSnapshot(in context: Context, completion: @escaping (HighScoreEntry) -> Void) {
        let score = UserDefaults.standard.integer(forKey: "highScore")
        completion(HighScoreEntry(date: Date(), highScore: score))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HighScoreEntry>) -> Void) {
        let score = UserDefaults.standard.integer(forKey: "highScore")
        let entry = HighScoreEntry(date: Date(), highScore: score)
        // Refresh periodically; the app will also call reloadAllTimelines when score updates.
        let next = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date().addingTimeInterval(900)
        let timeline = Timeline(entries: [entry], policy: .after(next))
        completion(timeline)
    }
}

struct CrownLoopComplicationView: View {
    var entry: HighScoreEntry
    @Environment(\._widgetFamily) private var family

    var body: some View {
        switch family {
        case .accessoryCircular:
            ZStack {
                Circle().foregroundColor(.black)
                VStack {
                    Image(systemName: "crown.fill")
                        .foregroundColor(.yellow)
                        .font(.caption)
                    Text("\(entry.highScore)")
                        .font(.headline)
                        .foregroundColor(.white)
                }
            }

        case .accessoryRectangular:
            HStack(spacing: 6) {
                Image(systemName: "crown.fill")
                    .foregroundColor(.yellow)
                Text("High: \(entry.highScore)")
                    .foregroundColor(.white)
                    .font(.subheadline)
            }

        default:
            Text("High: \(entry.highScore)")
                .foregroundColor(.white)
        }
    }
}

@main
struct CrownLoopComplication: Widget {
    let kind: String = "CrownLoopComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            CrownLoopComplicationView(entry: entry)
        }
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline])
        .configurationDisplayName("Crown Loop High Score")
        .description("Shows your current high score for Crown Loop.")
        .configurationDisplayName("Crown Loop")
    }
}
