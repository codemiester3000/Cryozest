//
//  WorkoutsCard.swift
//  Cryozest-2
//
//  Displays detailed workout information from Apple Watch
//

import SwiftUI
import CoreData

struct WorkoutsCard: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Binding var selectedDate: Date

    @State private var workouts: [TherapySessionEntity] = []

    var body: some View {
        if !workouts.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "figure.run")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.cyan)

                    Text("Workouts")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))

                    Spacer()

                    Text("\(workouts.count)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.cyan)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.cyan.opacity(0.15))
                        )
                }

                // List of workouts with details
                VStack(spacing: 8) {
                    ForEach(workouts, id: \.id) { workout in
                        WorkoutDetailRow(workout: workout)
                    }
                }
            }
            .padding(18)
            .feedWidgetStyle(style: .activity)
            .transition(.opacity.combined(with: .move(edge: .top)))
            .onAppear {
                loadWorkouts()
            }
            .onChange(of: selectedDate) { _ in
                loadWorkouts()
            }
        }
    }

    private func loadWorkouts() {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: selectedDate)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            workouts = []
            return
        }

        let fetchRequest: NSFetchRequest<TherapySessionEntity> = TherapySessionEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "date >= %@ AND date < %@ AND isAppleWatch == true",
            startOfDay as NSDate,
            endOfDay as NSDate
        )
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \TherapySessionEntity.date, ascending: true)]

        do {
            let results = try viewContext.fetch(fetchRequest)
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                workouts = results
            }
        } catch {
            print("Error fetching workouts: \(error)")
            workouts = []
        }
    }
}

struct WorkoutDetailRow: View {
    let workout: TherapySessionEntity

    private var therapyType: TherapyType {
        TherapyType(rawValue: workout.therapyType ?? "") ?? .custom1
    }

    private var durationText: String {
        let minutes = Int(workout.duration) / 60
        if minutes < 60 {
            return "\(minutes)m"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes == 0 {
                return "\(hours)h"
            } else {
                return "\(hours)h \(remainingMinutes)m"
            }
        }
    }

    private var timeOfDay: String {
        guard let date = workout.date else { return "" }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    var body: some View {
        HStack(spacing: 12) {
            // Workout icon
            ZStack {
                Circle()
                    .fill(therapyType.color.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: therapyType.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(therapyType.color)
            }

            // Workout details
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(therapyType.rawValue)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)

                    Image(systemName: "applewatch")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.green)
                }

                HStack(spacing: 12) {
                    // Time of day
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.white.opacity(0.4))

                        Text(timeOfDay)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }

                    // Duration
                    HStack(spacing: 4) {
                        Image(systemName: "timer")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.white.opacity(0.4))

                        Text(durationText)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }

                    // Heart rate (if available)
                    if workout.averageHeartRate > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(.red.opacity(0.7))

                            Text("\(Int(workout.averageHeartRate)) bpm")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                }
            }

            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(therapyType.color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}
