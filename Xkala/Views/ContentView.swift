import SwiftUI
import SwiftData
import UIKit

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \WorkoutDay.date, order: .reverse) private var workouts: [WorkoutDay]

    @State private var selectedWorkout: WorkoutDay?

    @State private var fabPressed = false
    private let fabHaptic = UIImpactFeedbackGenerator(style: .medium)

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                List {
                    Section {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Entrenos")
                                    .font(.headline)
                                Text("\(workouts.count) guardados")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .xkalaCard()
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    }

                    if workouts.isEmpty {
                        Section {
                            VStack(spacing: 10) {
                                Image(systemName: "figure.climbing")
                                    .font(.system(size: 34))
                                    .foregroundStyle(.secondary)

                                Text("Aún no hay entrenamientos")
                                    .font(.headline)

                                Text("Pulsa “Nuevo” para crear tu primera sesión.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .xkalaCard()
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        }
                    } else {
                        Section {
                            ForEach(workouts) { workout in
                                Button {
                                    selectedWorkout = workout
                                } label: {
                                    WorkoutCardContent(workout: workout)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .xkalaCard()
                                }
                                .buttonStyle(XkalaPressableRowStyle())
                                // ✅ Borrado fiable (swipe)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        deleteWorkout(workout)
                                    } label: {
                                        Label("Borrar", systemImage: "trash")
                                    }
                                }
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            }

                            // (Opcional) Mantén esto por si usas EditMode en el futuro
                            .onDelete(perform: deleteWorkouts)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .listStyle(.plain)
                .navigationTitle("Xkala")
                .navigationDestination(item: $selectedWorkout) { workout in
                    WorkoutDetailView(workout: workout)
                }
                .safeAreaInset(edge: .bottom) {
                    Color.clear.frame(height: 72)
                }

                // FAB flotante (haptic + pop)
                Button {
                    fabHaptic.impactOccurred()

                    withAnimation(.spring(response: 0.18, dampingFraction: 0.55)) {
                        fabPressed = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                            fabPressed = false
                        }
                    }

                    createNewWorkout()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Nuevo")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        Capsule(style: .continuous)
                            .fill(XkalaTheme.accent.opacity(0.95))
                    )
                    .foregroundStyle(Color.white)
                    .scaleEffect(fabPressed ? 0.95 : 1.0)
                    .shadow(color: Color.black.opacity(0.35), radius: 18, x: 0, y: 10)
                    .shadow(color: Color.black.opacity(0.20), radius: 6, x: 0, y: 2)
                }
                .buttonStyle(.plain)
                .padding(.trailing, 18)
                .padding(.bottom, 18)
                .accessibilityLabel("Nuevo entreno")
                .onAppear { fabHaptic.prepare() }
            }
        }
    }

    private func defaultWorkoutName(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.dateFormat = "HH:mm"
        return "Entreno \(formatter.string(from: date))"
    }

    private func createNewWorkout() {
        let now = Date()
        let w = WorkoutDay(date: now, name: defaultWorkoutName(for: now))
        context.insert(w)
        try? context.save()
    }

    private func deleteWorkout(_ workout: WorkoutDay) {
        if selectedWorkout?.id == workout.id {
            selectedWorkout = nil
        }
        context.delete(workout)
        try? context.save()
    }

    private func deleteWorkouts(_ indexSet: IndexSet) {
        for idx in indexSet {
            let w = workouts[idx]
            if selectedWorkout?.id == w.id {
                selectedWorkout = nil
            }
            context.delete(w)
        }
        try? context.save()
    }
}

// MARK: - Row content (sin gestures)

private struct WorkoutCardContent: View {
    let workout: WorkoutDay

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(workout.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 8) {
                    Image(systemName: "list.bullet.rectangle")
                        .foregroundStyle(.secondary)
                    Text("\(workout.entries.count) ejercicios")
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

    private var title: String {
        let trimmed = workout.name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty
            ? workout.date.formatted(date: .abbreviated, time: .shortened)
            : trimmed
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
