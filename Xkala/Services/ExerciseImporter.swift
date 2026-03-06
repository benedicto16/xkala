import Foundation
import SwiftData

enum ExerciseImporter {

    // Normaliza para que " Dominadas  " y "Dominadas" se consideren lo mismo
    private static func normalize(_ s: String) -> String {
        s.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
    }

    private static func normalizeMode(_ raw: String) -> String {
        let m = normalize(raw).lowercased()
        return (m == "seconds") ? "seconds" : "reps" // fallback seguro
    }

    private static func normalizeBoolSiNo(_ raw: String) -> Bool {
        let v = normalize(raw).lowercased()
        return v == "si" || v == "sí" || v == "true" || v == "1"
    }

    /// UPSERT por clave lógica: (name + category)
    static func upsertFromCatalogRows(_ rows: [[String]], context: ModelContext) throws {
        // CSV: Nombre, Categoría, Métrica principal, Permite carga?, Notas opcionales
        for row in rows {
            guard row.count >= 4 else { continue }

            let name = normalize(row[0])
            let category = normalize(row[1])
            let mode = normalizeMode(row[2])
            let loadAllowed = normalizeBoolSiNo(row[3])
            let notes = row.count >= 5 ? normalize(row[4]) : ""

            try upsertExercise(
                name: name,
                category: category,
                mode: mode,
                loadAllowed: loadAllowed,
                notes: notes,
                context: context
            )
        }
    }

    static func upsertExercise(
        name: String,
        category: String,
        mode: String,
        loadAllowed: Bool,
        notes: String,
        context: ModelContext
    ) throws {

        let descriptor = FetchDescriptor<Exercise>(
            predicate: #Predicate { ex in
                ex.name == name && ex.category == category
            }
        )

        if let existing = try context.fetch(descriptor).first {
            // UPDATE (idempotente)
            existing.mode = mode
            existing.loadAllowed = loadAllowed
            existing.notes = notes

            // Si vuelve en catálogo, lo reactivamos
            if existing.isArchived { existing.isArchived = false }

        } else {
            // INSERT
            let exercise = Exercise(
                name: name,
                category: category,
                mode: mode,
                loadAllowed: loadAllowed,
                notes: notes
            )
            context.insert(exercise)
        }
    }
}
