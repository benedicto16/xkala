import SwiftUI
import SwiftData
import UIKit

struct WorkoutDetailView: View {
    @Environment(\.modelContext) private var context
    @Bindable var workout: WorkoutDay

    @State private var selectedEntry: WorkoutEntry?

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
    }

    private var navigationTitle: String {
        let trimmed = workout.name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty
            ? workout.date.formatted(date: .abbreviated, time: .shortened)
            : trimmed
    }

    private func deleteEntry(_ entry: WorkoutEntry) {
        // Quitar de la relación primero (para que no quede la UI desincronizada)
        if let idx = workout.entries.firstIndex(where: { $0.id == entry.id }) {
            workout.entries.remove(at: idx)
        }
        context.delete(entry)
        try? context.save()
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
                Text(entry.exercise.name)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text("\(entry.exercise.category) · Intensidad \(entry.intensity) · Series \(entry.sets.count)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.secondary.opacity(0.7))
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
