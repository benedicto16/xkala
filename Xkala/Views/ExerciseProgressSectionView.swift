import SwiftUI

struct ExerciseProgressSectionView: View {
    let stats: ExerciseProgressStats
    let mode: ExerciseMode

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if stats.sessionCount == 0 {
                Text("Aún sin progreso registrado")
                    .foregroundStyle(.secondary)
            } else {
                MetricRow(title: "Sesiones", value: "\(stats.sessionCount)")

                MetricRow(
                    title: "Última vez",
                    value: stats.lastPerformedAt.map { $0.formatted(date: .abbreviated, time: .shortened) } ?? "-"
                )

                MetricRow(
                    title: "Mejor set",
                    value: formattedValue(stats.bestSetValue)
                )

                MetricRow(
                    title: "Mejor sesión",
                    value: formattedValue(stats.bestSessionTotal)
                )

                MetricRow(
                    title: "Última sesión",
                    value: formattedValue(stats.lastSessionTotal)
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .xkalaCard()
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
    }

    private func formattedValue(_ value: Int?) -> String {
        guard let value else { return "-" }
        switch mode {
        case .reps:
            return "\(value) reps"
        case .seconds:
            return formatMMSS(value)
        }
    }

    private func formatMMSS(_ totalSeconds: Int) -> String {
        let s = max(0, totalSeconds)
        let m = s / 60
        let r = s % 60
        return "\(m):" + String(format: "%02d", r)
    }
}

private struct MetricRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.trailing)
        }
    }
}

