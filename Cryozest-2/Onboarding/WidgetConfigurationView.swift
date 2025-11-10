//
//  WidgetConfigurationView.swift
//  Cryozest-2
//
//  Widget customization onboarding screen
//

import SwiftUI

struct WidgetConfigurationView: View {
    let onComplete: () -> Void

    @StateObject private var widgetManager = WidgetOrderManager.shared
    @State private var selectedWidgets: Set<DailyWidgetSection> = []
    @State private var animateIcon = false
    @State private var showContent = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Animated icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.purple.opacity(0.3),
                                    Color.purple.opacity(0.1)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                        .scaleEffect(animateIcon ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animateIcon)

                    Image(systemName: "square.grid.3x3.fill")
                        .font(.system(size: 40, weight: .light))
                        .foregroundColor(.purple)
                }
                .padding(.top, 40)

                VStack(spacing: 10) {
                    Text("Customize Your Daily View")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    Text("Select the widgets you want to see")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)

                    // Tooltip about reordering
                    HStack(spacing: 6) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.cyan.opacity(0.8))

                        Text("Tip: Long press widgets later to rearrange")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.08))
                            .overlay(
                                Capsule()
                                    .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
                            )
                    )
                    .padding(.top, 4)
                }

                // Widget selection cards
                VStack(spacing: 12) {
                    ForEach(DailyWidgetSection.allCases) { widget in
                        WidgetSelectionCard(
                            widget: widget,
                            isSelected: selectedWidgets.contains(widget),
                            onToggle: {
                                toggleWidget(widget)
                            }
                        )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)

                // Action buttons
                VStack(spacing: 12) {
                    // Continue button
                    Button(action: saveAndContinue) {
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 17))
                            Text("Continue")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.purple,
                                    Color.purple.opacity(0.8)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(14)
                        .shadow(color: Color.purple.opacity(0.4), radius: 12, x: 0, y: 6)
                    }

                    // Skip button
                    Button(action: useRecommended) {
                        Text("Use Recommended Layout")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.vertical, 12)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)

                // Ghost spacer to allow scrolling past last widget
                Color.clear
                    .frame(height: 150)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.05, green: 0.15, blue: 0.25),
                        Color(red: 0.1, green: 0.2, blue: 0.35),
                        Color(red: 0.15, green: 0.25, blue: 0.4)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                RadialGradient(
                    gradient: Gradient(colors: [
                        Color.purple.opacity(0.2),
                        Color.clear
                    ]),
                    center: .topTrailing,
                    startRadius: 100,
                    endRadius: 500
                )
            }
            .ignoresSafeArea()
        )
        .opacity(showContent ? 1 : 0)
        .offset(y: showContent ? 0 : 20)
        .onAppear {
            animateIcon = true
            // Start with all widgets selected as default
            selectedWidgets = Set(DailyWidgetSection.allCases)
            withAnimation(.easeOut(duration: 0.5)) {
                showContent = true
            }
        }
    }

    private func toggleWidget(_ widget: DailyWidgetSection) {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()

        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            if selectedWidgets.contains(widget) {
                selectedWidgets.remove(widget)
            } else {
                selectedWidgets.insert(widget)
            }
        }
    }

    private func saveAndContinue() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        // Save the selected widgets in order
        widgetManager.widgetOrder = DailyWidgetSection.allCases.filter { selectedWidgets.contains($0) }
        widgetManager.saveOrder()

        onComplete()
    }

    private func useRecommended() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()

        // Use default order (all widgets)
        widgetManager.resetToDefault()

        onComplete()
    }
}

struct WidgetSelectionCard: View {
    let widget: DailyWidgetSection
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(
                            isSelected
                                ? widget.defaultColor.opacity(0.2)
                                : Color.white.opacity(0.05)
                        )
                        .frame(width: 44, height: 44)

                    Image(systemName: widget.icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(
                            isSelected
                                ? widget.defaultColor
                                : .white.opacity(0.4)
                        )
                }

                // Title and description
                VStack(alignment: .leading, spacing: 4) {
                    Text(widget.rawValue)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(isSelected ? .white : .white.opacity(0.6))

                    Text(widgetDescription(for: widget))
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.white.opacity(0.5))
                        .lineLimit(1)
                }

                Spacer()

                // Checkmark
                ZStack {
                    Circle()
                        .stroke(
                            isSelected
                                ? widget.defaultColor.opacity(0.6)
                                : Color.white.opacity(0.2),
                            lineWidth: 2
                        )
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(widget.defaultColor)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        isSelected
                            ? Color.white.opacity(0.08)
                            : Color.white.opacity(0.03)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isSelected
                                    ? widget.defaultColor.opacity(0.3)
                                    : Color.white.opacity(0.1),
                                lineWidth: isSelected ? 1.5 : 1
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func widgetDescription(for widget: DailyWidgetSection) -> String {
        switch widget {
        case .wellnessCheckIn:
            return "Rate your daily mood"
        case .completedHabits:
            return "Track today's habits"
        case .medications:
            return "Manage your medications"
        case .heroScores:
            return "Recovery & exertion scores"
        case .largeSteps:
            return "Daily step count & goals"
        case .largeHeartRate:
            return "Resting heart rate trends"
        case .metricsGrid:
            return "HRV, sleep, and more"
        }
    }
}

#Preview {
    WidgetConfigurationView(onComplete: {})
}
