//
//  WellnessCheckInCard.swift
//  Cryozest-2
//
//  Created by Owen Khoury on 10/9/25.
//

import SwiftUI
import Combine

struct WellnessCheckInCard: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Binding var selectedDate: Date

    @State private var selectedRating: Int?
    @State private var hasSubmitted = false
    @State private var showFeedback = false

    var body: some View {
        Group {
            if hasSubmitted, let rating = selectedRating {
                compactView(rating: rating)
            } else {
                fullPickerView
            }
        }
        .onAppear {
            loadRatingForSelectedDate()
        }
        .onChange(of: selectedDate) { _ in
            loadRatingForSelectedDate()
        }
    }

    private func loadRatingForSelectedDate() {
        // Check if there's a rating for the selected date
        if let rating = WellnessRating.getRating(for: selectedDate, context: viewContext) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedRating = Int(rating.rating)
                hasSubmitted = true
                showFeedback = false
            }
        } else {
            // No rating exists for this date - show picker
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedRating = nil
                hasSubmitted = false
                showFeedback = false
            }
        }
    }

    private var fullPickerView: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Rate your mood from 1 to 5")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))

                Spacer()
            }

            HStack(spacing: 8) {
                ForEach(1...5, id: \.self) { rating in
                    Button(action: {
                        selectRating(rating)
                    }) {
                        Text("\(rating)")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(selectedRating == rating ? .white : .white.opacity(0.5))
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(
                                        selectedRating == rating
                                            ? LinearGradient(
                                                gradient: Gradient(colors: [
                                                    moodColor(for: rating),
                                                    moodColor(for: rating).opacity(0.8)
                                                ]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                            : LinearGradient(
                                                gradient: Gradient(colors: [
                                                    Color.white.opacity(0.08),
                                                    Color.white.opacity(0.05)
                                                ]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(
                                                selectedRating == rating
                                                    ? moodColor(for: rating).opacity(0.5)
                                                    : Color.white.opacity(0.1),
                                                lineWidth: 1
                                            )
                                    )
                            )
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }

            if showFeedback, let rating = selectedRating {
                Text(feedbackMessage(for: rating))
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(moodColor(for: rating).opacity(0.9))
                    .transition(.opacity.combined(with: .move(edge: .top)))
                    .frame(maxWidth: .infinity, alignment: .leading)
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
                        .stroke(
                            Color.white.opacity(0.15),
                            lineWidth: 1
                        )
                )
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showFeedback)
    }

    private func selectRating(_ rating: Int) {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()

        selectedRating = rating
        showFeedback = true

        WellnessRating.setRating(rating: rating, for: selectedDate, context: viewContext)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                hasSubmitted = true
            }
        }
    }

    private func compactView(rating: Int) -> some View {
        HStack(spacing: 10) {
            Text(dateLabel)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.6))

            HStack(spacing: 2) {
                ForEach(1...5, id: \.self) { star in
                    Circle()
                        .fill(star <= rating ? moodColor(for: rating) : Color.white.opacity(0.2))
                        .frame(width: 8, height: 8)
                }
            }

            Text(moodLabel(for: rating))
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(moodColor(for: rating))

            Spacer()

            // Undo button
            Button(action: undoRating) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.system(size: 11, weight: .semibold))
                    Text("Undo")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                }
                .foregroundColor(.white.opacity(0.6))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.1))
                        .overlay(
                            Capsule()
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.08),
                            Color.white.opacity(0.04)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            moodColor(for: rating).opacity(0.3),
                            lineWidth: 1
                        )
                )
        )
    }

    private func undoRating() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()

        // Delete the rating from Core Data
        WellnessRating.deleteRating(for: selectedDate, context: viewContext)

        // Reset state
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            selectedRating = nil
            hasSubmitted = false
            showFeedback = false
        }
    }

    private func moodColor(for rating: Int) -> Color {
        switch rating {
        case 1: return Color.red
        case 2: return Color.orange
        case 3: return Color.yellow
        case 4: return Color.green
        case 5: return Color.cyan
        default: return Color.cyan
        }
    }

    private func moodLabel(for rating: Int) -> String {
        switch rating {
        case 1: return "Rough"
        case 2: return "Not great"
        case 3: return "Okay"
        case 4: return "Good"
        case 5: return "Great"
        default: return "Good"
        }
    }

    private func feedbackMessage(for rating: Int) -> String {
        let messages: [Int: [String]] = [
            5: ["Outstanding", "Excellent day", "Keep it up"],
            4: ["Great to hear", "Solid day", "Going well"],
            3: ["Onwards", "Tomorrow's new", "Steady progress"],
            2: ["Hang in there", "Be patient", "Rest when needed"],
            1: ["Tough days happen", "Take care", "You've got this"]
        ]

        return messages[rating]?.randomElement() ?? "Thanks for checking in"
    }

    private var dateLabel: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(selectedDate) {
            return "Today:"
        } else if calendar.isDateInYesterday(selectedDate) {
            return "Yesterday:"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d:"
            return formatter.string(from: selectedDate)
        }
    }
}
