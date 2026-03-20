import Foundation
import SwiftData

enum BaseExercisesSeeder {

    @MainActor
    static func ensureBaseExercisesExist(context: ModelContext) async {
        ensureExercise(named: "Bloque", defaultCategory: "Boulder", context: context)
        ensureExercise(named: "Travesía", defaultCategory: "Travesía", context: context)
    }

    @MainActor
    private static func ensureExercise(
        named name: String,
        defaultCategory: String,
        context: ModelContext
    ) {
        let descriptor = FetchDescriptor<Exercise>(
            predicate: #Predicate { ex in
                ex.name == name
            }
        )

        if let existing = try? context.fetch(descriptor).first {
            existing.mode = "reps"
            existing.loadAllowed = false
            existing.isArchived = false
            return
        }

        let exercise = Exercise(
            name: name,
            category: defaultCategory,
            mode: "reps",
            loadAllowed: false,
            notes: "",
            isArchived: false
        )
        context.insert(exercise)
        try? context.save()
    }
}

