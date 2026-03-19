# Xkala

Xkala es una app iOS desarrollada en SwiftUI + SwiftData para escaladores.

## Visión de producto
Xkala es una app para escaladores orientada al seguimiento del progreso, no solo al registro de entrenamientos.

Debe permitir:
- Registrar sesiones y ejercicios
- Analizar evolución por ejercicio
- Mostrar estadísticas y gráficas
- Guardar y consultar resultados de tests
- Importar y exportar datos
- Mantener histórico fiable sin perder relaciones ni duplicar ejercicios

## Modelo actual

WorkoutDay
- date: Date
- notes: String
- entries: [WorkoutEntry]

WorkoutEntry
- exercise: Exercise
- intensity: Int
- isDone: Bool
- entryNotes: String
- sets: [SetRecord]

Exercise
- name: String
- category: String
- mode: reps | seconds
- loadAllowed: Bool
- notes: String
- isArchived: Bool

SetRecord
- reps: Int?
- seconds: Int?
- loadKg: Double?

## Reglas de dominio
- Exercise.mode solo puede ser "reps" o "seconds"
- Si mode == "reps", usar reps
- Si mode == "seconds", usar seconds
- loadKg solo si loadAllowed == true

## Reglas de arquitectura
- No reinventar la estructura si no es necesario
- Respetar el modelo persistente actual
- Detectar riesgos típicos de SwiftData: duplicados, relaciones, borrados
- No romper relaciones WorkoutDay -> WorkoutEntry -> SetRecord
- Evitar duplicados de Exercise
- Usar isArchived en vez de borrar ejercicios con histórico

## Criterios de evolución
- Priorizar progreso frente a cumplimiento de plan
- Añadir estadísticas sin persistir agregados inicialmente
- Separar tests del entrenamiento cuando sea necesario
- Mantener coherencia con decisiones UX existentes