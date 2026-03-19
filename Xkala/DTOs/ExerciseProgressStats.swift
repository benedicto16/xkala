import Foundation

/// DTO desacoplado de SwiftData para exponer métricas de progreso derivadas.
struct ExerciseProgressStats: Equatable {
    /// Número de sesiones (1 `WorkoutDay`) donde hubo al menos un set válido y `entry.isDone == true`.
    var sessionCount: Int

    /// Fecha/hora de la última sesión donde hubo datos válidos.
    var lastPerformedAt: Date?

    /// Mejor valor individual de set (max) según `exercise.mode`.
    var bestSetValue: Int?

    /// Mejor total por sesión (max de sumatorio por `WorkoutDay`) según `exercise.mode`.
    var bestSessionTotal: Int?

    /// Total por la última sesión donde hubo datos válidos.
    var lastSessionTotal: Int?

    static let empty = ExerciseProgressStats(
        sessionCount: 0,
        lastPerformedAt: nil,
        bestSetValue: nil,
        bestSessionTotal: nil,
        lastSessionTotal: nil
    )
}

