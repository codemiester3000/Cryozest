//
//  WellnessCheckInCard.swift
//  Cryozest-2
//
//  Created by Owen Khoury on 10/9/25.
//  Supports multiple entries per day
//

import SwiftUI
import Combine

struct WellnessCheckInCard: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Binding var selectedDate: Date

    @State private var todayRatings: [WellnessRating] = []
    @State private var isAddingNew = false
    @State private var selectedRating: Int?
    @State private var showFeedback = false
    @State private var isExpanded = false
    var body: some View {
        Group {
            if todayRatings.isEmpty || isAddingNew {
                fullPickerView
            } else {
                compactSummaryView
            }
        }
        .onAppear {
            loadRatingsForSelectedDate()
        }
        .onChange(of: selectedDate) { _ in
            loadRatingsForSelectedDate()
        }
    }

    private func loadRatingsForSelectedDate() {
        todayRatings = WellnessRating.getAllRatingsForDay(date: selectedDate, context: viewContext)
        isAddingNew = false
        selectedRating = nil
        showFeedback = false
        isExpanded = false
    }

    // MARK: - Full Picker View (for adding new entry)

    private var fullPickerView: some View {
        VStack(spacing: 12) {
            // Header with icon
            HStack(spacing: 12) {
                Image(systemName: "face.smiling")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.cyan)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(Color.cyan.opacity(0.15))
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text("How are you feeling?")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)

                    Text(isAddingNew ? "Add another entry" : "Track your mood right now")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }

                Spacer()

                // Cancel button if adding new
                if isAddingNew {
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            isAddingNew = false
                            selectedRating = nil
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.white.opacity(0.4))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }

            // Mood rating buttons with emojis
            HStack(spacing: 8) {
                ForEach(1...5, id: \.self) { rating in
                    Button(action: {
                        selectRating(rating)
                    }) {
                        VStack(spacing: 4) {
                            Text(moodEmoji(for: rating))
                                .font(.system(size: 20))

                            Text(moodLabel(for: rating))
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(selectedRating == rating ? .white : moodColor(for: rating))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selectedRating == rating ? moodColor(for: rating) : Color.white.opacity(0.06))
                        )
                        .scaleEffect(selectedRating == rating ? 1.02 : 1.0)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }

            if showFeedback, let rating = selectedRating {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(moodColor(for: rating))

                    Text(feedbackMessage(for: rating))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(moodColor(for: rating).opacity(0.9))
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(16)
        .feedWidgetStyle(style: .hero)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showFeedback)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedRating)
    }

    private func selectRating(_ rating: Int) {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()

        selectedRating = rating
        showFeedback = true

        WellnessRating.addRating(rating: rating, for: selectedDate, context: viewContext)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                loadRatingsForSelectedDate()
            }
        }
    }

    // MARK: - Compact Summary View (shows all entries)

    private var compactSummaryView: some View {
        VStack(spacing: 0) {
            // Main summary row
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            }) {
                HStack(spacing: 12) {
                    // Mood icon
                    Image(systemName: "face.smiling")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.cyan)

                    // Average and count
                    if let average = averageRating {
                        Text(moodEmoji(for: Int(average.rounded())))
                            .font(.system(size: 18))

                        VStack(alignment: .leading, spacing: 1) {
                            Text(moodLabel(for: Int(average.rounded())))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(moodColor(for: Int(average.rounded())))

                            Text(entryCountLabel)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }

                    Spacer()

                    // Mini entry indicators (show up to 5 recent)
                    HStack(spacing: 3) {
                        ForEach(todayRatings.prefix(5).reversed(), id: \.id) { rating in
                            Circle()
                                .fill(moodColor(for: Int(rating.rating)))
                                .frame(width: 8, height: 8)
                        }
                        if todayRatings.count > 5 {
                            Text("+\(todayRatings.count - 5)")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }

                    // Expand indicator
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.4))

                    // Add button
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            isAddingNew = true
                            selectedRating = nil
                            showFeedback = false
                        }
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.cyan)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            .buttonStyle(PlainButtonStyle())

            // Expanded entries list
            if isExpanded {
                Divider()
                    .background(Color.white.opacity(0.1))
                    .padding(.horizontal, 16)

                VStack(spacing: 8) {
                    ForEach(todayRatings, id: \.id) { rating in
                        entryRow(for: rating)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .feedWidgetStyle(style: .hero)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isExpanded)
    }

    private func entryRow(for rating: WellnessRating) -> some View {
        HStack(spacing: 10) {
            Text(moodEmoji(for: Int(rating.rating)))
                .font(.system(size: 16))

            Text(moodLabel(for: Int(rating.rating)))
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(moodColor(for: Int(rating.rating)))

            Spacer()

            // Time
            if let timestamp = rating.timestamp {
                Text(timeString(from: timestamp))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.4))
            }

            // Delete button
            Button(action: {
                deleteEntry(rating)
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.3))
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.05))
        )
    }

    private func deleteEntry(_ rating: WellnessRating) {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()

        if let id = rating.id {
            WellnessRating.deleteRating(id: id, context: viewContext)

            // Reload after a brief delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    loadRatingsForSelectedDate()
                }
            }
        }
    }

    // MARK: - Helpers

    private var averageRating: Double? {
        WellnessRating.getAverageRatingForDay(date: selectedDate, context: viewContext)
    }

    private var entryCountLabel: String {
        let count = todayRatings.count
        if count == 1 {
            return "1 entry"
        } else {
            return "\(count) entries"
        }
    }

    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
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
        case 2: return "Low"
        case 3: return "Okay"
        case 4: return "Good"
        case 5: return "Great"
        default: return "Good"
        }
    }

    private func moodEmoji(for rating: Int) -> String {
        switch rating {
        case 1: return "😞"
        case 2: return "😕"
        case 3: return "😐"
        case 4: return "😊"
        case 5: return "😄"
        default: return "😊"
        }
    }

    private func feedbackMessage(for rating: Int) -> String {
        let messages: [Int: [String]] = [
            5: ["Outstanding!", "Excellent", "Keep it up"],
            4: ["Great to hear", "Solid", "Going well"],
            3: ["Onwards", "Tomorrow's new", "Steady"],
            2: ["Hang in there", "Be patient", "Rest up"],
            1: ["Tough days happen", "Take care", "You've got this"]
        ]

        return messages[rating]?.randomElement() ?? "Logged"
    }
}
