import SwiftUI

/// One row on the Fuel Track.
struct FuelTrackStop: Identifiable {
    enum Kind { case start, stop, finish }

    let id: UUID
    let minute: Int
    let kind: Kind
    var tokens: [FuelTrackToken] = []
    var isUserModified = false

    /// Amber node when the stop contains carbohydrates, blue when it is fluid only.
    var hasCarbs: Bool { tokens.contains { $0.nutrient == .carbs } }
}

struct FuelTrackToken: Identifiable {
    let id: UUID
    let text: String
    let systemImage: String
    let nutrient: Theme.Nutrient
    /// Set for snack portions that can be swapped; `nil` for water.
    var portionID: UUID?
}

/// The signature timeline: the session drawn as a course with fuel stops.
struct FuelTrackView: View {
    let stops: [FuelTrackStop]
    var canSwap: Bool
    var onSwap: (_ stopID: UUID, _ portionID: UUID) -> Void

    @ScaledMetric(relativeTo: .title) private var timeColumn: CGFloat = 60

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(stops.enumerated()), id: \.element.id) { index, stop in
                row(stop, isFirst: index == 0, isLast: index == stops.count - 1)
            }
        }
        .padding(.vertical, 10)
        .padding(.trailing, 12)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.hero, style: .continuous)
                .fill(Theme.Colors.surface)
        )
    }

    private func row(_ stop: FuelTrackStop, isFirst: Bool, isLast: Bool) -> some View {
        HStack(alignment: .center, spacing: 0) {
            MetricText(
                FZFormat.clock(minutes: stop.minute),
                size: stop.kind == .stop ? 26 : 20,
                color: stop.kind == .stop ? Theme.Colors.ink : Theme.Colors.ink2,
                relativeTo: .title2
            )
            .frame(width: timeColumn, alignment: .trailing)

            node(stop, isFirst: isFirst, isLast: isLast)
                .frame(width: 30)

            content(stop)
                .padding(.leading, 8)
                .padding(.vertical, stop.kind == .stop ? 10 : 6)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(minHeight: stop.kind == .stop ? 60 : 40)
        .accessibilityElement(children: .contain)
    }

    private func node(_ stop: FuelTrackStop, isFirst: Bool, isLast: Bool) -> some View {
        ZStack {
            VStack(spacing: 0) {
                dashed.opacity(isFirst ? 0 : 1)
                dashed.opacity(isLast ? 0 : 1)
            }
            switch stop.kind {
            case .start:
                Circle()
                    .strokeBorder(Theme.Colors.ink, lineWidth: 3)
                    .background(Circle().fill(Theme.Colors.surface))
                    .frame(width: 14, height: 14)
            case .finish:
                RoundedRectangle(cornerRadius: 4).fill(Theme.Colors.ink).frame(width: 16, height: 16)
            case .stop:
                Circle()
                    .fill(stop.hasCarbs ? Theme.Colors.accentFill : Theme.Nutrient.fluids.color)
                    .frame(width: stop.hasCarbs ? 18 : 12, height: stop.hasCarbs ? 18 : 12)
                    .padding(3)
                    .background(Circle().fill(Theme.Colors.surface))
            }
        }
        .accessibilityHidden(true)
    }

    private var dashed: some View {
        Rectangle()
            .fill(Theme.Colors.ink.opacity(0.85))
            .frame(width: 3)
            .mask(
                VStack(spacing: 5) {
                    ForEach(0..<20, id: \.self) { _ in Rectangle().frame(height: 8) }
                }
                .frame(maxHeight: .infinity, alignment: .top)
                .clipped()
            )
    }

    @ViewBuilder
    private func content(_ stop: FuelTrackStop) -> some View {
        switch stop.kind {
        case .start:
            Text(localized: "track.start").fzLabelStyle()
        case .finish:
            Text(localized: "track.finish").fzLabelStyle()
        case .stop:
            FlowLayout(spacing: 6) {
                ForEach(stop.tokens) { token in
                    if let portionID = token.portionID {
                        Button {
                            onSwap(stop.id, portionID)
                        } label: {
                            HStack(spacing: 4) {
                                FZDataToken(text: token.text, systemImage: token.systemImage, nutrient: token.nutrient)
                                if canSwap {
                                    Image(systemName: "arrow.left.arrow.right")
                                        .font(.caption2.weight(.bold))
                                        .foregroundStyle(Theme.Colors.ink3)
                                }
                            }
                            .frame(minHeight: Theme.minTouch)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(Text(token.text))
                        .accessibilityHint(Text(localized: canSwap ? "a11y.swap.hint" : "a11y.swap.pro"))
                    } else {
                        FZDataToken(text: token.text, systemImage: token.systemImage, nutrient: token.nutrient)
                            .frame(minHeight: Theme.minTouch)
                    }
                }
                if stop.isUserModified {
                    Image(systemName: "pencil.circle.fill")
                        .foregroundStyle(Theme.Colors.accentText)
                        .frame(minHeight: Theme.minTouch)
                        .accessibilityLabel(Text(localized: "a11y.modified"))
                }
            }
        }
    }
}

/// Wraps children onto new lines (tokens, chips).
struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var widest: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0, x + size.width > maxWidth {
                y += rowHeight + spacing
                x = 0
                rowHeight = 0
            }
            x += size.width + spacing
            widest = max(widest, x - spacing)
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: min(widest, maxWidth), height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > bounds.minX, x + size.width > bounds.maxX {
                y += rowHeight + spacing
                x = bounds.minX
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

/// Shared number and time formatting.
enum FZFormat {
    /// "0:20", "1:30", "12:05".
    static func clock(minutes: Int) -> String {
        "\(minutes / 60):" + String(format: "%02d", minutes % 60)
    }

    static func integer(_ value: Double) -> String {
        "\(Int(value.rounded()))"
    }

    static func range(_ range: NutritionRange) -> String {
        let low = Int(range.min.rounded())
        let high = Int(range.max.rounded())
        return low == high ? "\(low)" : "\(low)–\(high)"
    }
}
