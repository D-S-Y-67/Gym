import SwiftUI
import SwiftData

// MARK: - Muscle region model

enum BodyOrientation: String, CaseIterable, Hashable {
    case front, back

    var label: String {
        switch self {
        case .front: return "Front"
        case .back:  return "Back"
        }
    }
}

/// One trackable region on the body. Maps to one or more `Exercise.bodyPart`
/// strings (case-insensitive). Coarse on purpose — matches the granularity
/// of the seed data ("Arms", "Legs", etc.).
enum MuscleRegion: String, CaseIterable, Identifiable {
    case chest, shoulders, arms, forearms, core, back, glutes, legs, calves

    var id: String { rawValue }
    var displayName: String { rawValue.capitalized }

    var bodyPartMatches: Set<String> {
        switch self {
        case .chest:     return ["chest"]
        case .shoulders: return ["shoulders"]
        case .arms:      return ["arms"]
        case .forearms:  return ["forearms"]
        case .core:      return ["core"]
        case .back:      return ["back"]
        case .glutes:    return ["glutes"]
        case .legs:      return ["legs"]
        case .calves:    return ["calves"]
        }
    }

    /// Which body view shows this region. Most appear on both;
    /// `chest`/`core` are front-only, `back`/`glutes` are back-only.
    var orientations: Set<BodyOrientation> {
        switch self {
        case .chest, .core:   return [.front]
        case .back, .glutes:  return [.back]
        default:              return [.front, .back]
        }
    }
}

// MARK: - Volume aggregation

/// Aggregates per-region volume from a list of finished workouts. Volume
/// = sum of `weight × reps` for completed sets.
struct MuscleVolumeMap {
    let perRegion: [MuscleRegion: Double]
    let total: Double
    let max: Double

    init(workouts: [Workout]) {
        var sums: [MuscleRegion: Double] = [:]
        for workout in workouts where workout.endedAt != nil {
            for exercise in workout.exercises {
                guard let bodyPart = exercise.exercise?.bodyPart.lowercased() else { continue }
                guard let region = MuscleRegion.allCases.first(where: { $0.bodyPartMatches.contains(bodyPart) }) else { continue }
                let regionVolume = exercise.sets
                    .filter { $0.isCompleted }
                    .reduce(0.0) { $0 + ($1.weight * Double($1.reps)) }
                sums[region, default: 0] += regionVolume
            }
        }
        self.perRegion = sums
        self.total = sums.values.reduce(0, +)
        self.max = sums.values.max() ?? 0
    }

    /// Empty map — used for the no-data preview.
    static let empty = MuscleVolumeMap(workouts: [])

    /// 0…1 normalized intensity. 0 if no data.
    func intensity(_ region: MuscleRegion) -> Double {
        guard max > 0 else { return 0 }
        return (perRegion[region] ?? 0) / max
    }

    func volume(_ region: MuscleRegion) -> Double {
        perRegion[region] ?? 0
    }

    var trainedRegions: [MuscleRegion] {
        MuscleRegion.allCases.filter { (perRegion[$0] ?? 0) > 0 }
    }
}

// MARK: - Body view

/// Workouts → "Body" sub-screen. Heat-mapped figure + sortable region table
/// + time-window picker. Pushed via `WorkoutsRoute.body` from the Workouts
/// home preview card.
struct BodyView: View {

    @Environment(\.modelContext) private var modelContext

    @State private var orientation: BodyOrientation = .front
    @State private var window: TimeWindow = .week

    enum TimeWindow: String, CaseIterable, Identifiable {
        case week, month
        var id: String { rawValue }
        var label: String { self == .week ? "7 days" : "30 days" }
        var days: Int { self == .week ? 7 : 30 }
    }

    private var fetchedWorkouts: [Workout] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -window.days, to: .now) ?? .now
        let descriptor = FetchDescriptor<Workout>(
            predicate: #Predicate { $0.endedAt != nil && $0.startedAt >= cutoff },
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    private var volumeMap: MuscleVolumeMap {
        MuscleVolumeMap(workouts: fetchedWorkouts)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                heroBlock
                VStack(spacing: Theme.Spacing.lg) {
                    orientationPicker
                    HumanFigure(orientation: orientation, intensity: volumeMap.intensity(_:))
                        .frame(width: 220, height: 360)
                        .frame(maxWidth: .infinity)
                        .animation(.spring(duration: 0.35), value: orientation)
                    regionTable
                }
                .padding(.top, Theme.Spacing.lg)
                .padding(.bottom, Theme.Spacing.xl)
            }
        }
        .background(Theme.Palette.surfaceBackground)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
    }

    // MARK: - Hero

    private var heroBlock: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack {
                ForgeWordmark(size: 16)
                    .foregroundStyle(.white)
                Spacer()
                Text("BODY")
                    .font(.caption.weight(.heavy))
                    .tracking(2.4)
                    .foregroundStyle(.white.opacity(0.85))
            }

            HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.sm) {
                Theme.Typo.heroNumeral(formatVolume(volumeMap.total))
                    .foregroundStyle(.white)
                Text("lb")
                    .font(.title3.weight(.heavy))
                    .tracking(1.5)
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(.bottom, 12)
                Spacer()
            }

            Text("\(volumeMap.trainedRegions.count) regions trained · last \(window.days) days")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.78))

            Picker("Window", selection: $window) {
                ForEach(TimeWindow.allCases) { window in
                    Text(window.label).tag(window)
                }
            }
            .pickerStyle(.segmented)
            .colorScheme(.dark)
            .padding(.top, Theme.Spacing.xs)
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.top, Theme.Spacing.xxl + Theme.Spacing.md)
        .padding(.bottom, Theme.Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Palette.heroGradient(.accentColor))
        .clipShape(
            UnevenRoundedRectangle(
                bottomLeadingRadius: Theme.Radius.lg + 6,
                bottomTrailingRadius: Theme.Radius.lg + 6,
                style: .continuous
            )
        )
    }

    // MARK: - Orientation picker

    private var orientationPicker: some View {
        Picker("View", selection: $orientation) {
            ForEach(BodyOrientation.allCases, id: \.self) { orientation in
                Text(orientation.label).tag(orientation)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, Theme.Spacing.md)
    }

    // MARK: - Region table

    private var regionTable: some View {
        let visible = MuscleRegion.allCases
            .filter { $0.orientations.contains(orientation) }
            .sorted { volumeMap.volume($0) > volumeMap.volume($1) }

        return VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Theme.Typo.eyebrow("\(orientation.label) View")
                Spacer()
                Theme.Typo.eyebrow("Volume")
            }
            .padding(.horizontal, Theme.Spacing.md)

            GlassCard(padding: 0) {
                VStack(spacing: 0) {
                    ForEach(Array(visible.enumerated()), id: \.element.id) { index, region in
                        regionRow(region: region)
                        if index < visible.count - 1 {
                            Divider().padding(.leading, Theme.Spacing.md)
                        }
                    }
                }
                .padding(.vertical, Theme.Spacing.xs)
            }
            .padding(.horizontal, Theme.Spacing.md)
        }
    }

    private func regionRow(region: MuscleRegion) -> some View {
        let volume = volumeMap.volume(region)
        let intensity = volumeMap.intensity(region)
        return HStack(spacing: Theme.Spacing.md) {
            Circle()
                .fill(Color.accentColor.opacity(0.15 + 0.85 * intensity))
                .frame(width: 12, height: 12)
            Text(region.displayName)
                .font(.body)
                .foregroundStyle(.primary)
            Spacer()
            if volume > 0 {
                Text(formatVolume(volume))
                    .font(.body.monospacedDigit().weight(.semibold))
                    .foregroundStyle(.primary)
                Text("lb")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("—")
                    .font(.body.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm + 2)
        .frame(minHeight: 40)
    }

    private func formatVolume(_ value: Double) -> String {
        if value >= 1000 {
            return String(format: "%.1fk", value / 1000)
        }
        return String(format: "%.0f", value)
    }
}

// MARK: - Human figure

/// Stylized humanoid drawn as compositional capsules and rounded rects.
/// Two layers: a base silhouette in subtle gray, plus muscle "stickers"
/// overlaid and tinted by intensity. `accent.opacity(0.18 + 0.82 × intensity)`
/// so untrained reads as faint accent and heavily-trained reads as full accent.
struct HumanFigure: View {
    let orientation: BodyOrientation
    let intensity: (MuscleRegion) -> Double

    private let baseColor = Color.secondary.opacity(0.22)

    var body: some View {
        ZStack {
            base
            switch orientation {
            case .front:
                frontStickers.transition(.opacity.combined(with: .scale(scale: 0.96)))
            case .back:
                backStickers.transition(.opacity.combined(with: .scale(scale: 0.96)))
            }
        }
        .frame(width: 220, height: 360)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Body heat map, \(orientation.label) view")
    }

    // MARK: Base silhouette

    private var base: some View {
        ZStack {
            // Head
            Circle()
                .fill(baseColor)
                .frame(width: 44, height: 44)
                .offset(y: -150)

            // Neck
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(baseColor)
                .frame(width: 14, height: 12)
                .offset(y: -126)

            // Shoulders
            Capsule()
                .fill(baseColor)
                .frame(width: 130, height: 28)
                .offset(y: -106)

            // Torso
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(baseColor)
                .frame(width: 100, height: 120)
                .offset(y: -38)

            // Pelvis
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(baseColor)
                .frame(width: 90, height: 36)
                .offset(y: 38)

            // Upper arms (slightly outboard)
            Capsule()
                .fill(baseColor)
                .frame(width: 26, height: 80)
                .offset(x: -68, y: -68)
            Capsule()
                .fill(baseColor)
                .frame(width: 26, height: 80)
                .offset(x: 68, y: -68)

            // Lower arms
            Capsule()
                .fill(baseColor)
                .frame(width: 22, height: 70)
                .offset(x: -76, y: 8)
            Capsule()
                .fill(baseColor)
                .frame(width: 22, height: 70)
                .offset(x: 76, y: 8)

            // Thighs
            Capsule()
                .fill(baseColor)
                .frame(width: 38, height: 100)
                .offset(x: -22, y: 100)
            Capsule()
                .fill(baseColor)
                .frame(width: 38, height: 100)
                .offset(x: 22, y: 100)

            // Calves
            Capsule()
                .fill(baseColor)
                .frame(width: 30, height: 78)
                .offset(x: -22, y: 184)
            Capsule()
                .fill(baseColor)
                .frame(width: 30, height: 78)
                .offset(x: 22, y: 184)
        }
    }

    // MARK: Stickers

    private var frontStickers: some View {
        ZStack {
            // Chest (two pecs)
            sticker(.chest, w: 36, h: 28, offset: CGSize(width: -16, height: -78))
            sticker(.chest, w: 36, h: 28, offset: CGSize(width: 16, height: -78))

            // Front delts
            sticker(.shoulders, w: 26, h: 22, offset: CGSize(width: -50, height: -106))
            sticker(.shoulders, w: 26, h: 22, offset: CGSize(width: 50, height: -106))

            // Biceps
            sticker(.arms, w: 20, h: 50, offset: CGSize(width: -68, height: -68), shape: .capsule)
            sticker(.arms, w: 20, h: 50, offset: CGSize(width: 68, height: -68), shape: .capsule)

            // Forearms
            sticker(.forearms, w: 18, h: 50, offset: CGSize(width: -76, height: 8), shape: .capsule)
            sticker(.forearms, w: 18, h: 50, offset: CGSize(width: 76, height: 8), shape: .capsule)

            // Core (abs)
            sticker(.core, w: 56, h: 64, offset: CGSize(width: 0, height: -10), shape: .roundedRect(14))

            // Quads
            sticker(.legs, w: 30, h: 76, offset: CGSize(width: -22, height: 100), shape: .capsule)
            sticker(.legs, w: 30, h: 76, offset: CGSize(width: 22, height: 100), shape: .capsule)

            // Calves (front view shows shins — lighter share of legs)
            sticker(.calves, w: 22, h: 50, offset: CGSize(width: -22, height: 184), shape: .capsule)
            sticker(.calves, w: 22, h: 50, offset: CGSize(width: 22, height: 184), shape: .capsule)
        }
    }

    private var backStickers: some View {
        ZStack {
            // Upper back (lats + traps mass)
            sticker(.back, w: 84, h: 92, offset: CGSize(width: 0, height: -52), shape: .roundedRect(20))

            // Rear delts
            sticker(.shoulders, w: 26, h: 22, offset: CGSize(width: -50, height: -106))
            sticker(.shoulders, w: 26, h: 22, offset: CGSize(width: 50, height: -106))

            // Triceps
            sticker(.arms, w: 20, h: 50, offset: CGSize(width: -68, height: -68), shape: .capsule)
            sticker(.arms, w: 20, h: 50, offset: CGSize(width: 68, height: -68), shape: .capsule)

            // Forearms
            sticker(.forearms, w: 18, h: 50, offset: CGSize(width: -76, height: 8), shape: .capsule)
            sticker(.forearms, w: 18, h: 50, offset: CGSize(width: 76, height: 8), shape: .capsule)

            // Glutes
            sticker(.glutes, w: 36, h: 28, offset: CGSize(width: -18, height: 38))
            sticker(.glutes, w: 36, h: 28, offset: CGSize(width: 18, height: 38))

            // Hamstrings
            sticker(.legs, w: 30, h: 70, offset: CGSize(width: -22, height: 102), shape: .capsule)
            sticker(.legs, w: 30, h: 70, offset: CGSize(width: 22, height: 102), shape: .capsule)

            // Calves
            sticker(.calves, w: 24, h: 60, offset: CGSize(width: -22, height: 180), shape: .capsule)
            sticker(.calves, w: 24, h: 60, offset: CGSize(width: 22, height: 180), shape: .capsule)
        }
    }

    private enum StickerShape {
        case capsule
        case ellipse
        case roundedRect(CGFloat)
    }

    @ViewBuilder
    private func sticker(_ region: MuscleRegion, w: CGFloat, h: CGFloat, offset: CGSize, shape: StickerShape = .ellipse) -> some View {
        let intensityValue = intensity(region)
        let fill = Color.accentColor.opacity(0.18 + 0.82 * intensityValue)
        Group {
            switch shape {
            case .capsule:
                Capsule().fill(fill)
            case .ellipse:
                Ellipse().fill(fill)
            case .roundedRect(let radius):
                RoundedRectangle(cornerRadius: radius, style: .continuous).fill(fill)
            }
        }
        .frame(width: w, height: h)
        .offset(offset)
    }
}

// MARK: - Workouts-home preview card

/// Compact embed for `WorkoutsHomeView`. Mini front-view figure + this-week
/// summary. Tap pushes the full `BodyView`.
struct BodyPreviewCard: View {

    @Environment(\.modelContext) private var modelContext
    let onOpen: () -> Void

    private var weekVolumeMap: MuscleVolumeMap {
        let cutoff = Calendar.current.date(byAdding: .day, value: -7, to: .now) ?? .now
        let descriptor = FetchDescriptor<Workout>(
            predicate: #Predicate { $0.endedAt != nil && $0.startedAt >= cutoff },
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )
        let workouts = (try? modelContext.fetch(descriptor)) ?? []
        return MuscleVolumeMap(workouts: workouts)
    }

    var body: some View {
        Button {
            Haptics.tap()
            onOpen()
        } label: {
            GlassCard {
                HStack(spacing: Theme.Spacing.md) {
                    HumanFigure(orientation: .front, intensity: weekVolumeMap.intensity(_:))
                        .scaleEffect(0.36, anchor: .center)
                        .frame(width: 80, height: 130)

                    VStack(alignment: .leading, spacing: 6) {
                        Theme.Typo.eyebrow("This week")
                        Text(volumeText)
                            .font(.title2.bold())
                            .monospacedDigit()
                        Text(subtitleText)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Open body view")
    }

    private var volumeText: String {
        let total = weekVolumeMap.total
        if total == 0 { return "—" }
        if total >= 1000 {
            return String(format: "%.1fk lb", total / 1000)
        }
        return String(format: "%.0f lb", total)
    }

    private var subtitleText: String {
        let count = weekVolumeMap.trainedRegions.count
        if count == 0 {
            return "Log a workout to fill the map."
        }
        return "\(count) region\(count == 1 ? "" : "s") trained"
    }
}

#Preview("Body view") {
    NavigationStack { BodyView() }
}

#Preview("Figure - front") {
    HumanFigure(orientation: .front) { _ in 0.5 }
        .padding(40)
}

#Preview("Figure - back") {
    HumanFigure(orientation: .back) { _ in 0.5 }
        .padding(40)
}
