import SwiftUI
import WidgetKit

/// Home- and lock-screen widget: one tap opens JodSlip and starts searching
/// the photo library for slips (`jodslip://scan-library`, handled by
/// LaunchActionPlugin in the app).
@main
struct ScanSlipWidgetBundle: WidgetBundle {
  var body: some Widget {
    ScanSlipWidget()
  }
}

struct ScanSlipWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "ScanSlipWidget", provider: StaticProvider()) { _ in
      ScanSlipWidgetView()
    }
    .configurationDisplayName(Strings.title)
    .description(Strings.description)
    .supportedFamilies([.systemSmall, .accessoryCircular, .accessoryRectangular])
  }
}

/// The widget never changes, so one entry with no refresh is enough.
struct StaticProvider: TimelineProvider {
  struct Entry: TimelineEntry {
    let date: Date
  }

  func placeholder(in context: Context) -> Entry { Entry(date: .now) }

  func getSnapshot(in context: Context, completion: @escaping (Entry) -> Void) {
    completion(Entry(date: .now))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
    completion(Timeline(entries: [Entry(date: .now)], policy: .never))
  }
}

struct ScanSlipWidgetView: View {
  @Environment(\.widgetFamily) private var family

  private static let scanURL = URL(string: "jodslip://scan-library")!
  private static let green = Color(red: 0x1B / 255, green: 0x8A / 255, blue: 0x5A / 255)
  private static let icon = "doc.text.magnifyingglass"

  var body: some View {
    content
      .widgetURL(Self.scanURL)
      .containerBackground(for: .widget) {
        if family == .systemSmall {
          LinearGradient(
            colors: [Self.green, Self.green.opacity(0.75)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        } else {
          Color.clear
        }
      }
  }

  @ViewBuilder
  private var content: some View {
    switch family {
    case .accessoryCircular:
      ZStack {
        AccessoryWidgetBackground()
        Image(systemName: Self.icon).font(.title2)
      }
      .widgetAccentable()
    case .accessoryRectangular:
      HStack(spacing: 8) {
        Image(systemName: Self.icon).font(.title2).widgetAccentable()
        VStack(alignment: .leading, spacing: 0) {
          Text(Strings.title).font(.headline)
          Text(Strings.subtitle).font(.caption)
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    default:
      VStack(alignment: .leading, spacing: 4) {
        Image(systemName: Self.icon)
          .font(.system(size: 34, weight: .semibold))
        Spacer(minLength: 0)
        Text(Strings.title)
          .font(.headline)
        Text(Strings.subtitle)
          .font(.caption)
          .opacity(0.85)
      }
      .foregroundStyle(.white)
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
  }
}

/// Thai unless the device prefers another language (the app falls back to
/// English the same way).
enum Strings {
  private static let thai = Locale.preferredLanguages.first?.hasPrefix("th") ?? true

  static let title = thai ? "ค้นหาสลิป" : "Find slips"
  static let subtitle = thai ? "จากรูปทั้งหมด" : "in all photos"
  static let description = thai
    ? "แตะเพื่อให้จดสลิปไล่ดูรูปในเครื่องแล้วเลือกเฉพาะสลิปมาให้"
    : "Tap to let JodSlip look through your photos and pick out the slips."
}
