//
//  InsightsView.swift
//  Cryozest-2
//
//  Created by Owen Khoury on 10/9/25.
//

import SwiftUI
import CoreData
import Combine

struct InsightsView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        entity: TherapySessionEntity.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \TherapySessionEntity.date, ascending: false)]
    )
    private var sessions: FetchedResults<TherapySessionEntity>

    @FetchRequest(
        entity: SelectedTherapy.entity(),
        sortDescriptors: []
    )
    private var selectedTherapies: FetchedResults<SelectedTherapy>

    @FetchRequest(
        entity: WellnessRating.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \WellnessRating.date, ascending: false)]
    )
    private var wellnessRatings: FetchedResults<WellnessRating>

    @StateObject private var viewModelWrapper = InsightsViewModelWrapper()
    @State private var showInfoSheet = false
    @State private var showConfigSheet = false
    @ObservedObject var insightsConfig = InsightsConfigurationManager.shared

    private var selectedTherapyTypes: [TherapyType] {
        if selectedTherapies.isEmpty {
            // Updated for App Store compliance - removed extreme temperature therapies
            return [.running, .weightTraining, .cycling, .meditation]
        } else {
            return selectedTherapies.compactMap { TherapyType(rawValue: $0.therapyType ?? "") }
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Modern gradient background matching app theme
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.05, green: 0.15, blue: 0.25),
                        Color(red: 0.1, green: 0.2, blue: 0.35),
                        Color(red: 0.15, green: 0.25, blue: 0.4)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                // Subtle gradient overlay
                RadialGradient(
                    gradient: Gradient(colors: [
                        Color.purple.opacity(0.3),
                        Color.clear
                    ]),
                    center: .topTrailing,
                    startRadius: 100,
                    endRadius: 500
                )
                .ignoresSafeArea()

                if let viewModel = viewModelWrapper.viewModel {
                    Group {
                        if viewModel.isLoading {
                            loadingView
                        } else {
                            mainContentView(viewModel: viewModel)
                        }
                    }
                } else {
                    loadingView
                }
            }
        }
        .navigationViewStyle(.stack)
        .onAppear {
            // Initialize viewModel on appear with actual sessions
            if viewModelWrapper.viewModel == nil {
                viewModelWrapper.viewModel = InsightsViewModel(
                    sessions: sessions,
                    selectedTherapyTypes: selectedTherapyTypes
                )
            }
        }
        .sheet(isPresented: $showInfoSheet) {
            InsightsInfoSheet()
        }
        .sheet(isPresented: $showConfigSheet) {
            InsightsConfigSheet()
        }
    }

    private var loadingView: some View {
        VStack(spacing: 20) {
            Text("Insights")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.top, 16)

            InsightsLoadingSkeleton()
                .padding(.horizontal)

            Spacer()
        }
    }

    private func mainContentView(viewModel: InsightsViewModel) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                HStack {
                    Text("Insights")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)

                    Spacer()

                    // Config button
                    Button(action: {
                        showConfigSheet = true
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.15))
                                .frame(width: 44, height: 44)

                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.cyan)
                        }
                    }

                    // Info button
                    Button(action: {
                        showInfoSheet = true
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.15))
                                .frame(width: 44, height: 44)

                            Image(systemName: "info.circle.fill")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.purple)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 16)

                // Wellness Trends Section
                if insightsConfig.isEnabled(.wellnessTrends) {
                    WellnessInsightsSection(
                        ratings: Array(wellnessRatings),
                        sessions: Array(sessions),
                        therapyTypes: selectedTherapyTypes
                    )

                    Divider()
                        .background(Color.white.opacity(0.2))
                        .padding(.vertical, 8)
                        .padding(.horizontal)
                }

                // Medication Adherence Section
                if insightsConfig.isEnabled(.medicationAdherence) {
                    MedicationAdherenceSection()
                        .environment(\.managedObjectContext, viewContext)

                    Divider()
                        .background(Color.white.opacity(0.2))
                        .padding(.vertical, 8)
                        .padding(.horizontal)
                }

                // Health Trends Section
                if insightsConfig.isEnabled(.healthTrends) && !viewModel.healthTrends.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        InsightsSectionHeader(
                            title: "Your Health This Week",
                            icon: "chart.line.uptrend.xyaxis",
                            color: .cyan
                        )
                        .padding(.horizontal)

                        VStack(spacing: 12) {
                            ForEach(viewModel.healthTrends) { trend in
                                HealthTrendCard(trend: trend)
                                    .padding(.horizontal)
                            }
                        }
                    }

                    Divider()
                        .background(Color.white.opacity(0.2))
                        .padding(.vertical, 8)
                        .padding(.horizontal)
                }

                // Top Performers Section
                if insightsConfig.isEnabled(.topPerformers) {
                    VStack(alignment: .leading, spacing: 16) {
                        InsightsSectionHeader(
                            title: "Top Performers",
                            icon: "trophy.fill",
                            color: .yellow
                        )
                        .padding(.horizontal)

                        if viewModel.topHabitImpacts.isEmpty {
                            InsightsEmptyStateCard(
                                title: "Track Your Habits",
                                message: "Track your habits for at least 3 days to see which ones have the biggest positive impact on your health metrics.",
                                icon: "chart.bar.fill"
                            )
                            .padding(.horizontal)
                        } else {
                            VStack(spacing: 12) {
                                ForEach(Array(viewModel.topHabitImpacts.enumerated()), id: \.element.id) { index, impact in
                                    TopImpactCard(impact: impact, rank: index + 1)
                                        .padding(.horizontal)
                                }
                            }
                        }
                    }

                    Divider()
                        .background(Color.white.opacity(0.2))
                        .padding(.vertical, 8)
                        .padding(.horizontal)
                }

                // Sleep Impact Section
                if insightsConfig.isEnabled(.sleepImpact) {
                    VStack(alignment: .leading, spacing: 16) {
                        InsightsSectionHeader(
                            title: "Sleep Impact",
                            icon: "bed.double.fill",
                            color: .purple
                        )
                        .padding(.horizontal)

                        if viewModel.sleepImpacts.isEmpty {
                            InsightsEmptyStateCard(
                                title: "Sleep Tracking Needed",
                                message: "Sleep tracking in the Health app or an Apple Watch is needed to see how your habits affect your sleep duration.",
                                icon: "bed.double.fill"
                            )
                            .padding(.horizontal)
                        } else {
                            VStack(spacing: 10) {
                                ForEach(viewModel.sleepImpacts) { impact in
                                    MetricImpactRow(impact: impact)
                                        .padding(.horizontal)
                                }
                            }
                        }
                    }

                    Divider()
                        .background(Color.white.opacity(0.2))
                        .padding(.vertical, 8)
                        .padding(.horizontal)
                }

                // HRV Impact Section
                if insightsConfig.isEnabled(.hrvImpact) {
                    VStack(alignment: .leading, spacing: 16) {
                        InsightsSectionHeader(
                            title: "HRV Impact",
                            icon: "waveform.path.ecg",
                            color: .green
                        )
                        .padding(.horizontal)

                        if viewModel.hrvImpacts.isEmpty {
                            InsightsEmptyStateCard(
                                title: "Apple Watch Required",
                                message: "Wear an Apple Watch to track Heart Rate Variability and see how your habits improve your HRV.",
                                icon: "applewatch"
                            )
                            .padding(.horizontal)
                        } else {
                            VStack(spacing: 10) {
                                ForEach(viewModel.hrvImpacts) { impact in
                                    MetricImpactRow(impact: impact)
                                        .padding(.horizontal)
                                }
                            }
                        }
                    }

                    Divider()
                        .background(Color.white.opacity(0.2))
                        .padding(.vertical, 8)
                        .padding(.horizontal)
                }

                // RHR Impact Section
                if insightsConfig.isEnabled(.rhrImpact) {
                    VStack(alignment: .leading, spacing: 16) {
                        InsightsSectionHeader(
                            title: "Heart Rate Impact",
                            icon: "heart.fill",
                            color: .red
                        )
                        .padding(.horizontal)

                        if viewModel.rhrImpacts.isEmpty {
                            InsightsEmptyStateCard(
                                title: "Apple Watch Required",
                                message: "Wear an Apple Watch to track heart rate and see how your habits optimize your resting heart rate.",
                                icon: "applewatch"
                            )
                            .padding(.horizontal)
                        } else {
                            VStack(spacing: 10) {
                                ForEach(viewModel.rhrImpacts) { impact in
                                    MetricImpactRow(impact: impact)
                                        .padding(.horizontal)
                                }
                            }
                        }
                    }
                }

                // Bottom spacer to prevent tab bar overlap
                Color.clear
                    .frame(height: 100)
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
                .frame(height: 60)

            InsightsEmptyStateCard(
                title: "Not Enough Data Yet",
                message: "We need more health data from HealthKit to generate insights. Make sure you've synced your health data and check back soon!",
                icon: "chart.bar.xaxis"
            )
            .padding(.horizontal)

            Spacer()
        }
    }
}

// Wrapper class to hold the optional viewModel as @Published
class InsightsViewModelWrapper: ObservableObject {
    @Published var viewModel: InsightsViewModel? {
        didSet {
            cancellable?.cancel()
            cancellable = viewModel?.objectWillChange.sink { [weak self] _ in
                self?.objectWillChange.send()
            }
        }
    }

    private var cancellable: AnyCancellable?
}

struct InsightsInfoSheet: View {
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        ZStack {
            // Modern gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.05, green: 0.15, blue: 0.25),
                    Color(red: 0.1, green: 0.2, blue: 0.35),
                    Color(red: 0.15, green: 0.25, blue: 0.4)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("About Insights")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Spacer()

                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 60)
                .padding(.bottom, 30)

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Wellness Trends
                        InfoSection(
                            icon: "heart.fill",
                            color: .pink,
                            title: "Wellness Trends",
                            description: "Track your daily mood ratings and see week-over-week comparisons. The circular indicator shows your wellness score as a percentage of perfect (5/5)."
                        )

                        // Happiness Boosters
                        InfoSection(
                            icon: "trophy.fill",
                            color: .yellow,
                            title: "Happiness Boosters",
                            description: "Discover which habits have the biggest positive impact on your wellness. We compare your ratings on days you do each habit vs days you don't."
                        )

                        // Health Trends
                        InfoSection(
                            icon: "chart.line.uptrend.xyaxis",
                            color: .cyan,
                            title: "Health Trends",
                            description: "Monitor changes in your key health metrics over the past week, including HRV, resting heart rate, and sleep duration."
                        )

                        // Top Performers
                        InfoSection(
                            icon: "star.fill",
                            color: .orange,
                            title: "Top Performers",
                            description: "See which habits consistently improve your health metrics the most. Ranked by overall positive impact."
                        )

                        // Metric Impacts
                        InfoSection(
                            icon: "waveform.path.ecg",
                            color: .green,
                            title: "Metric Impacts",
                            description: "Understand how each habit affects your HRV, sleep duration, and resting heart rate. Positive changes are highlighted in green."
                        )
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
        }
    }
}

struct InfoSection: View {
    let icon: String
    let color: Color
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(color)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.white)

                Text(description)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.white.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
