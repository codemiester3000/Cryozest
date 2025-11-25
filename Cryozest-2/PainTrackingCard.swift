//
//  PainTrackingCard.swift
//  Cryozest-2
//
//  Pain tracking widget for daily health monitoring
//  Supports multiple entries per day
//

import SwiftUI
import Combine

struct PainTrackingCard: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Binding var selectedDate: Date

    @State private var todayRatings: [PainRating] = []
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
        todayRatings = PainRating.getAllRatingsForDay(date: selectedDate, context: viewContext)
        isAddingNew = false
        selectedRating = nil
        showFeedback = false
        isExpanded = false
    }

    // MARK: - Full Picker View (for adding new entry)

    private var fullPickerView: some View {
        VStack(spacing: 16) {
            // Header with icon
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.red.opacity(0.3),
                                    Color.orange.opacity(0.2)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)

                    Image(systemName: "bolt.heart.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.orange)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Pain Level")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)

                    Text(isAddingNew ? "Add another entry" : "How are you feeling?")
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

            // Pain rating buttons (0-5 scale)
            HStack(spacing: 8) {
                ForEach(0...5, id: \.self) { rating in
                    Button(action: {
                        selectRating(rating)
                    }) {
                        VStack(spacing: 4) {
                            Text(painEmoji(for: rating))
                                .font(.system(size: 24))

                            Text("\(rating)")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(selectedRating == rating ? .white : painColor(for: rating))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(
                                    selectedRating == rating
                                        ? LinearGradient(
                                            gradient: Gradient(colors: [
                                                painColor(for: rating),
                                                painColor(for: rating).opacity(0.8)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                        : LinearGradient(
                                            gradient: Gradient(colors: [
                                                painColor(for: rating).opacity(0.15),
                                                painColor(for: rating).opacity(0.08)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(
                                            selectedRating == rating
                                                ? painColor(for: rating).opacity(0.6)
                                                : painColor(for: rating).opacity(0.3),
                                            lineWidth: selectedRating == rating ? 2 : 1
                                        )
                                )
                        )
                        .scaleEffect(selectedRating == rating ? 1.05 : 1.0)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }

            // Pain level label
            if let rating = selectedRating {
                HStack(spacing: 8) {
                    Circle()
                        .fill(painColor(for: rating))
                        .frame(width: 8, height: 8)

                    Text(painLabel(for: rating))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(painColor(for: rating))
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            if showFeedback, let rating = selectedRating {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(painColor(for: rating))

                    Text(feedbackMessage(for: rating))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(painColor(for: rating).opacity(0.9))
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(20)
        .modernWidgetCard(style: .medical)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showFeedback)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedRating)
    }

    private func selectRating(_ rating: Int) {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()

        selectedRating = rating
        showFeedback = true

        PainRating.addRating(rating: rating, for: selectedDate, context: viewContext)

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
                    // Pain icon
                    Image(systemName: "bolt.heart.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.orange)

                    // Average and count
                    if let average = averageRating {
                        Text(painEmoji(for: Int(average.rounded())))
                            .font(.system(size: 18))

                        VStack(alignment: .leading, spacing: 1) {
                            Text(painLabel(for: Int(average.rounded())))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(painColor(for: Int(average.rounded())))

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
                                .fill(painColor(for: Int(rating.rating)))
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
                            .foregroundColor(.orange)
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
        .modernWidgetCard(style: .medical)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isExpanded)
    }

    private func entryRow(for rating: PainRating) -> some View {
        HStack(spacing: 10) {
            Text(painEmoji(for: Int(rating.rating)))
                .font(.system(size: 16))

            Text(painLabel(for: Int(rating.rating)))
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(painColor(for: Int(rating.rating)))

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

    private func deleteEntry(_ rating: PainRating) {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()

        if let id = rating.id {
            PainRating.deleteRating(id: id, context: viewContext)

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
        PainRating.getAverageRatingForDay(date: selectedDate, context: viewContext)
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

    private func painColor(for rating: Int) -> Color {
        switch rating {
        case 0: return Color.green
        case 1: return Color.mint
        case 2: return Color.yellow
        case 3: return Color.orange
        case 4: return Color.red
        case 5: return Color.purple
        default: return Color.gray
        }
    }

    private func painLabel(for rating: Int) -> String {
        switch rating {
        case 0: return "No Pain"
        case 1: return "Minimal"
        case 2: return "Mild"
        case 3: return "Moderate"
        case 4: return "Severe"
        case 5: return "Extreme"
        default: return "Unknown"
        }
    }

    private func painEmoji(for rating: Int) -> String {
        switch rating {
        case 0: return "😌"
        case 1: return "🙂"
        case 2: return "😐"
        case 3: return "😣"
        case 4: return "😖"
        case 5: return "😫"
        default: return "😐"
        }
    }

    private func feedbackMessage(for rating: Int) -> String {
        let messages: [Int: [String]] = [
            0: ["Pain-free!", "Feeling great", "Keep it up"],
            1: ["Minor discomfort", "Nearly there", "Good progress"],
            2: ["Manageable", "Take it easy", "Listen to your body"],
            3: ["Consider rest", "Take care", "Monitor closely"],
            4: ["Rest recommended", "Be gentle", "Recovery time"],
            5: ["Prioritize rest", "Seek care if needed", "Take it slow"]
        ]

        return messages[rating]?.randomElement() ?? "Logged"
    }
}
