import Foundation

/// Calcula métricas de progreso derivadas a partir del historial (sin persistir agregados).
final class ExerciseStatisticsService {
    init() {}

    func calculateProgress(for exercise: Exercise, in workouts: [WorkoutDay]) -> ExerciseProgressStats {
        let mode = exercise.modeEnum
        let exerciseName = exercise.name
        let exerciseCategory = exercise.category

        var stats = ExerciseProgressStats.empty
        var bestSessionTotal: Int? = nil
        var bestSetValue: Int? = nil

        var lastPerformedAt: Date? = nil
        var lastSessionTotal: Int? = nil

        // Recorremos todas las sesiones y calculamos el total por sesión.
        for workout in workouts {
            var sessionTotal = 0
            var hasAnyValidSetValue = false

            for entry in workout.entries {
                // Según tu regla: solo consideramos entradas completadas.
                guard entry.isDone else { continue }
                // Filtro del ejercicio:
                // - Preferimos identidad por referencia (misma instancia SwiftData).
                // - Con fallback por clave lógica (name + category) para evitar falsos negativos.
                let isSameExercise =
                    (entry.exercise === exercise)
                    || (entry.exercise.name == exerciseName && entry.exercise.category == exerciseCategory)
                guard isSameExercise else { continue }

                for set in entry.sets {
                    switch mode {
                    case .reps:
                        guard let reps = set.reps else { continue }
                        guard Self.isValidRepsValue(reps) else { continue }
                        hasAnyValidSetValue = true
                        sessionTotal += reps
                        bestSetValue = Self.maxOptional(bestSetValue, reps)

                    case .seconds:
                        guard let seconds = set.seconds else { continue }
                        guard Self.isValidSecondsValue(seconds) else { continue }
                        hasAnyValidSetValue = true
                        sessionTotal += seconds
                        bestSetValue = Self.maxOptional(bestSetValue, seconds)
                    }
                }
            }

            // Si no hay sets válidos en esta sesión, no cuenta como sesión para el progreso.
            guard hasAnyValidSetValue else { continue }

            stats.sessionCount += 1

            // Best session: max del total por sesión.
            bestSessionTotal = Self.maxOptional(bestSessionTotal, sessionTotal)

            // Last session: sesión con la fecha más reciente.
            if let lastDate = lastPerformedAt {
                if workout.date > lastDate {
                    lastPerformedAt = workout.date
                    lastSessionTotal = sessionTotal
                }
            } else {
                lastPerformedAt = workout.date
                lastSessionTotal = sessionTotal
            }
        }

        stats.lastPerformedAt = lastPerformedAt
        stats.bestSetValue = bestSetValue
        stats.bestSessionTotal = bestSessionTotal
        stats.lastSessionTotal = lastSessionTotal
        return stats
    }

    // MARK: - Defensive validation

    private static func isValidRepsValue(_ reps: Int) -> Bool {
        // La UI permite 0, pero descartamos valores negativos o absurdamente altos por corrupción de datos.
        // Para "progreso" considero que 0 reps no aporta (y puede representar un valor placeholder).
        (1...2000).contains(reps)
    }

    private static func isValidSecondsValue(_ seconds: Int) -> Bool {
        // La UI limita a 0...3600, pero aceptamos un margen razonable por si existen datos históricos sucios.
        // Para "progreso" considero que 0 segundos no aporta (y puede representar un valor placeholder).
        (1...86400).contains(seconds) // <= 24h
    }

    private static func maxOptional(_ a: Int?, _ b: Int) -> Int? {
        guard let a else { return b }
        return (b > a) ? b : a
    }
}

