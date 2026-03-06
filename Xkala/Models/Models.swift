import Foundation
import SwiftData

// MARK: - WorkoutDay

@Model
final class WorkoutDay {

    /// Fecha y hora de la sesión.
    /// Permite múltiples sesiones el mismo día.
    var date: Date

    /// Nombre editable para diferenciar entrenamientos.
    /// Default vacío para evitar problemas de migración.
    var name: String = ""

    /// Notas generales del día.
    var notes: String

    /// Entries asociados a la sesión.
    @Relationship(deleteRule: .cascade)
    var entries: [WorkoutEntry]

    init(
        date: Date = Date(),
        name: String = "",
        notes: String = "",
        entries: [WorkoutEntry] = []
    ) {
        self.date = date
        self.name = name
        self.notes = notes
        self.entries = entries
    }

    /// Clave de día (inicio del día) útil para agrupar en estadísticas futuras.
    var dayKey: Date {
        Calendar.current.startOfDay(for: date)
    }
}


// MARK: - Exercise

@Model
final class Exercise {

    var name: String
    var category: String

    /// Solo puede ser "reps" o "seconds"
    var mode: String

    /// Si false, loadKg debe permanecer nil en los SetRecord
    var loadAllowed: Bool

    var notes: String
    var isArchived: Bool

    init(
        name: String,
        category: String,
        mode: String,
        loadAllowed: Bool,
        notes: String = "",
        isArchived: Bool = false
    ) {
        self.name = name
        self.category = category
        self.mode = mode
        self.loadAllowed = loadAllowed
        self.notes = notes
        self.isArchived = isArchived
    }
}


// MARK: - WorkoutEntry

@Model
final class WorkoutEntry {

    var exercise: Exercise
    var intensity: Int
    var isDone: Bool
    var entryNotes: String

    @Relationship(deleteRule: .cascade)
    var sets: [SetRecord]

    init(
        exercise: Exercise,
        intensity: Int = 1,
        isDone: Bool = false,
        entryNotes: String = "",
        sets: [SetRecord] = []
    ) {
        self.exercise = exercise
        self.intensity = intensity
        self.isDone = isDone
        self.entryNotes = entryNotes
        self.sets = sets
    }
}


// MARK: - SetRecord

@Model
final class SetRecord {

    /// Solo usar si exercise.mode == "reps"
    var reps: Int?

    /// Solo usar si exercise.mode == "seconds"
    /// Guardado en segundos totales (UI lo muestra mm:ss)
    var seconds: Int?

    /// Solo válido si exercise.loadAllowed == true
    var loadKg: Double?

    init(
        reps: Int? = nil,
        seconds: Int? = nil,
        loadKg: Double? = nil
    ) {
        self.reps = reps
        self.seconds = seconds
        self.loadKg = loadKg
    }
}

import Foundation

enum ExerciseMode: String, CaseIterable {
    case reps
    case seconds
}

extension Exercise {
    /// Acceso seguro a mode sin "strings mágicos".
    /// Si por cualquier razón mode contiene un valor inválido, hacemos fallback a .reps.
    var modeEnum: ExerciseMode {
        get { ExerciseMode(rawValue: mode) ?? .reps }
        set { mode = newValue.rawValue }
    }
}

extension SetRecord {
    /// Crea un set consistente con el modo del ejercicio.
    static func make(for exercise: Exercise) -> SetRecord {
        switch exercise.modeEnum {
        case .reps:
            return SetRecord(reps: 0, seconds: nil, loadKg: nil)
        case .seconds:
            return SetRecord(reps: nil, seconds: 0, loadKg: nil)
        }
    }
}
