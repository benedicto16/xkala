import SwiftUI
import SwiftData
import Combine
import UIKit

struct WorkoutDetailView: View {
    @Environment(\.modelContext) private var context
    @Bindable var workout: WorkoutDay

    @State private var selectedEntry: WorkoutEntry?
    @State private var now: Date = Date()

    private let durationTick = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        List {
            Section("Sesión") {
                VStack(spacing: 12) {
                    TextField("Nombre del entreno", text: $workout.name)

                    DatePicker(
                        "Fecha",
                        selection: $workout.date,
                        displayedComponents: [.date, .hourAndMinute]
                    )

                    timerControlsCard
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .xkalaCard()
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }

            Section("Sensaciones") {
                TextField("Cómo te has encontrado…", text: $workout.notes, axis: .vertical)
                    .lineLimit(3...8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .xkalaCard()
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }

            Section("Ejercicios") {
                if workout.entries.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 28))
                            .foregroundStyle(.secondary)

                        Text("Aún no hay ejercicios")
                            .font(.headline)

                        Text("Pulsa “Añadir” para empezar.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .xkalaCard()
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                } else {
                    ForEach(workout.entries) { entry in
                        Button {
                            selectedEntry = entry
                        } label: {
                            EntryCardContent(entry: entry)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .xkalaCard()
                        }
                        .buttonStyle(XkalaPressableRowStyle())
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                deleteEntry(entry)
                            } label: {
                                Label("Borrar", systemImage: "trash")
                            }
                        }
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .listStyle(.plain)
        .navigationTitle(navigationTitle)
        .navigationDestination(item: $selectedEntry) { entry in
            ExerciseDetailView(entry: entry)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    AddExerciseView(workout: workout)
                } label: {
                    XkalaActionButton(
                        title: "Añadir",
                        systemImage: "plus"
                    )
                }
            }
        }
        .onReceive(durationTick) { _ in
            // Solo refrescamos si está en curso.
            guard workout.startedAt != nil, workout.endedAt == nil else { return }
            now = Date()
        }
    }

    private var navigationTitle: String {
        let trimmed = workout.name.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { return trimmed }
        return workout.categoriesBasedName ?? workout.date.formatted(date: .abbreviated, time: .shortened)
    }

    private func deleteEntry(_ entry: WorkoutEntry) {
        // Quitar de la relación primero (para que no quede la UI desincronizada)
        if let idx = workout.entries.firstIndex(where: { $0.id == entry.id }) {
            workout.entries.remove(at: idx)
        }
        context.delete(entry)
        try? context.save()
    }

    // MARK: - Timer controls

    private var timerControlsCard: some View {
        VStack(spacing: 10) {
            if workout.startedAt == nil {
                Button {
                    let started = Date()
                    workout.startedAt = started
                    workout.endedAt = nil
                    now = started
                    try? context.save()
                } label: {
                    XkalaActionButton(
                        title: "Iniciar entrenamiento",
                        systemImage: "play.fill"
                    )
                }
                .buttonStyle(.plain)
            } else if workout.endedAt == nil {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Duración en curso")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if let durationText {
                        Text(durationText)
                            .font(.headline)
                            .foregroundStyle(.primary)
                    }
                }

                Button {
                    workout.endedAt = Date()
                    now = Date()
                    try? context.save()
                } label: {
                    XkalaActionButton(
                        title: "Finalizar entrenamiento",
                        systemImage: "stop.fill"
                    )
                }
                .buttonStyle(.plain)
            } else {
                if let durationText {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Duración")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(durationText)
                            .font(.headline)
                            .foregroundStyle(.primary)
                    }
                }
            }
        }
    }

    private var durationText: String? {
        guard let startedAt = workout.startedAt else { return nil }

        let seconds: TimeInterval
        if let endedAt = workout.endedAt {
            seconds = endedAt.timeIntervalSince(startedAt)
        } else {
            seconds = now.timeIntervalSince(startedAt)
        }

        return DurationFormatting.formatSpanish(duration: seconds)
    }
}

// MARK: - Row content (sin gestures, no rompe swipe)

private struct EntryCardContent: View {
    let entry: WorkoutEntry

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: entry.isDone ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(entry.isDone ? XkalaTheme.mint : .secondary)
                .font(.system(size: 22))

            VStack(alignment: .leading, spacing: 4) {
                if entry.isBlock {
                    HStack(spacing: 10) {
                        gradeDot
                        Text(blockTitle)
                            .font(.headline)
                            .foregroundStyle(.primary)
                    }
                } else if entry.isTraverse {
                    HStack(spacing: 6) {
                        Text("Travesía")
                            .font(.headline)
                        Text(traverseIdentifier)
                            .font(.system(.headline, design: .monospaced))
                    }
                    .foregroundStyle(.primary)
                } else {
                    Text(entry.exercise.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                }

                if entry.isBlock || entry.isTraverse {
                    Text("\(attemptsText) · \(statusText)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Text("\(entry.exercise.category) · Intensidad \(entry.intensity) · Series \(entry.sets.count)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.secondary.opacity(0.7))
        }
    }

    private var attemptsText: String {
        let attempts = entry.sets.first?.reps ?? 0
        return "\(attempts) intentos"
    }

    private var statusText: String {
        entry.isDone ? "Completado" : "Pendiente"
    }

    private var blockTitle: String {
        // climbIdentifier admite número o texto libre: lo mostramos literalmente.
        let id = (entry.climbIdentifier ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let shown = id.isEmpty ? "—" : id
        return "Bloque \(shown)"
    }

    private var traverseIdentifier: String {
        let id = (entry.climbIdentifier ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let shown = id.isEmpty ? "—" : id.uppercased()
        return shown
    }

    private var gradeDot: some View {
        let color = gradeColor(entry.climbGradeColor)
        return Circle()
            .fill(color)
            .frame(width: 14, height: 14)
            .overlay {
                Circle()
                    .stroke(Color.primary.opacity(0.22), lineWidth: 1)
            }
    }

    private func gradeColor(_ grade: String?) -> Color {
        let normalized = grade?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        switch normalized {
        case "green":
            return .green
        case "yellow":
            return .yellow
        case "orange":
            return .orange
        case "purple":
            return .purple
        default:
            return .secondary
        }
    }
}

// MARK: - ButtonStyle (pop + haptic sin romper swipe)

private struct XkalaPressableRowStyle: ButtonStyle {
    private let haptic = UIImpactFeedbackGenerator(style: .light)

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.985 : 1.0)
            .opacity(configuration.isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.18, dampingFraction: 0.75), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, pressed in
                if pressed { haptic.impactOccurred() }
            }
            .onAppear { haptic.prepare() }
    }
}
