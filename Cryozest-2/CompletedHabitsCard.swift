//
//  CompletedHabitsCard.swift
//  Cryozest-2
//
//  Displays completed habits for the selected date
//

import SwiftUI
import CoreData

struct CompletedHabitsCard: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Binding var selectedDate: Date

    @State private var completedHabits: [TherapySessionEntity] = []

    var body: some View {
        if !completedHabits.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.green)

                    Text("Completed Today")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))

                    Spacer()

                    Text("\(completedHabits.count)")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.green.opacity(0.15))
                        )
                }

                // Grid of completed habits
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(completedHabits.prefix(6), id: \.id) { habit in
                        CompletedHabitItem(habit: habit)
                    }

                    if completedHabits.count > 6 {
                        HStack(spacing: 4) {
                            Text("+\(completedHabits.count - 6)")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(.white.opacity(0.6))
                            Text("more")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.5))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white.opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                        )
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.1),
                                Color.white.opacity(0.06)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.green.opacity(0.3), lineWidth: 1)
                    )
            )
            .transition(.opacity.combined(with: .move(edge: .top)))
            .onAppear {
                loadCompletedHabits()
            }
            .onChange(of: selectedDate) { _ in
                loadCompletedHabits()
            }
        }
    }

    private func loadCompletedHabits() {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: selectedDate)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            completedHabits = []
            return
        }

        let fetchRequest: NSFetchRequest<TherapySessionEntity> = TherapySessionEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "date >= %@ AND date < %@",
            startOfDay as NSDate,
            endOfDay as NSDate
        )
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \TherapySessionEntity.date, ascending: false)]

        do {
            let results = try viewContext.fetch(fetchRequest)
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                completedHabits = results
            }
        } catch {
            print("Error fetching completed habits: \(error)")
            completedHabits = []
        }
    }
}

struct CompletedHabitItem: View {
    let habit: TherapySessionEntity

    private var therapyType: TherapyType {
        TherapyType(rawValue: habit.therapyType ?? "") ?? .custom1
    }

    private var durationText: String {
        let minutes = Int(habit.duration) / 60
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

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: therapyType.icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.green)
                    .frame(width: 20, height: 20)
                    .background(
                        Circle()
                            .fill(Color.green.opacity(0.15))
                    )

                Spacer()

                if habit.isAppleWatch {
                    Image(systemName: "applewatch")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                }
            }

            Text(therapyType.rawValue)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)

            Text(durationText)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.green.opacity(0.2), lineWidth: 1)
                )
        )
    }
}
