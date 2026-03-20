import Foundation

/// Formateos pequeños y reutilizables para la UI.
enum DurationFormatting {
    /// Formatea una duración (segundos) a texto legible en español, sin segundos.
    ///
    /// Ejemplos:
    /// - 45 min
    /// - 1 hora y 5 min
    /// - 2 horas y 10 min
    static func formatSpanish(duration: TimeInterval) -> String {
        let safeSeconds = max(0, duration)
        let totalMinutes = Int(safeSeconds) / 60

        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        if hours <= 0 {
            return "\(minutes) min"
        }

        let hourText = hours == 1 ? "hora" : "horas"

        if minutes == 0 {
            return "\(hours) \(hourText)"
        }

        return "\(hours) \(hourText) y \(minutes) min"
    }
}

