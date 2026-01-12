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
                // Deep navy background
                Color(red: 0.06, green: 0.10, blue: 0.18)
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
                    selectedTherapyTypes: selectedTherapyTypes,
                    viewContext: viewContext
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
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // Header - clean, minimal
                HStack(alignment: .center) {
                    Text("Insights")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)

                    Spacer()

                    // Config button - subtle
                    Button(action: { showConfigSheet = true }) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                            .frame(width: 40, height: 40)
                    }

                    // Info button - subtle
                    Button(action: { showInfoSheet = true }) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                            .frame(width: 40, height: 40)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 24)

                // Health Trends Section (moved to top)
                if insightsConfig.isEnabled(.healthTrends) && !viewModel.healthTrends.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        InsightsSectionHeader(
                            title: "Health This Week",
                            icon: "chart.line.uptrend.xyaxis",
                            color: .cyan
                        )
                        .padding(.horizontal, 20)

                        VStack(spacing: 16) {
                            ForEach(viewModel.healthTrends) { trend in
                                HealthTrendCard(trend: trend)
                                    .padding(.horizontal, 20)
                            }
                        }
                    }

                    InsightsDivider()
                        .padding(.horizontal, 20)
                }

                // Top Performers Section (moved to second)
                if insightsConfig.isEnabled(.topPerformers) {
                    VStack(alignment: .leading, spacing: 8) {
                        InsightsSectionHeader(
                            title: "Top Correlations",
                            icon: "chart.bar.xaxis",
                            color: .orange
                        )
                        .padding(.horizontal, 20)
                        .padding(.bottom, 12)

                        if viewModel.topHabitImpacts.isEmpty {
                            InsightsEmptyStateCard(
                                title: "More Data Needed",
                                message: "Track habits for at least 14 days to see statistically reliable associations.",
                                icon: "chart.bar.fill"
                            )
                            .padding(.horizontal, 20)
                        } else {
                            VStack(spacing: 10) {
                                ForEach(Array(viewModel.topHabitImpacts.enumerated()), id: \.element.id) { index, impact in
                                    TopImpactCard(impact: impact, rank: index + 1)
                                        .padding(.horizontal, 20)
                                }
                            }
                        }
                    }

                    InsightsDivider()
                        .padding(.horizontal, 20)
                }

                // Wellness Trends Section
                if insightsConfig.isEnabled(.wellnessTrends) {
                    WellnessInsightsSection(
                        ratings: Array(wellnessRatings),
                        sessions: Array(sessions),
                        therapyTypes: selectedTherapyTypes
                    )

                    InsightsDivider()
                        .padding(.horizontal, 20)
                }

                // Medication Adherence Section
                if insightsConfig.isEnabled(.medicationAdherence) {
                    MedicationAdherenceSection()
                        .environment(\.managedObjectContext, viewContext)

                    InsightsDivider()
                        .padding(.horizontal, 20)
                }

                // Sleep Association Section
                if insightsConfig.isEnabled(.sleepImpact) {
                    VStack(alignment: .leading, spacing: 8) {
                        InsightsSectionHeader(
                            title: "Sleep Associations",
                            icon: "bed.double.fill",
                            color: .purple
                        )
                        .padding(.horizontal, 20)

                        if viewModel.sleepImpacts.isEmpty {
                            InsightsEmptyStateCard(
                                title: "More Data Needed",
                                message: "Track habits for 14+ days with sleep data to see associations.",
                                icon: "bed.double.fill"
                            )
                            .padding(.horizontal, 20)
                        } else {
                            VStack(spacing: 0) {
                                ForEach(viewModel.sleepImpacts) { impact in
                                    MetricImpactRow(impact: impact)
                                        .padding(.horizontal, 20)
                                }
                            }
                        }
                    }

                    InsightsDivider()
                        .padding(.horizontal, 20)
                }

                // HRV Association Section
                if insightsConfig.isEnabled(.hrvImpact) {
                    VStack(alignment: .leading, spacing: 8) {
                        InsightsSectionHeader(
                            title: "HRV Associations",
                            icon: "waveform.path.ecg",
                            color: .green
                        )
                        .padding(.horizontal, 20)

                        if viewModel.hrvImpacts.isEmpty {
                            InsightsEmptyStateCard(
                                title: "More Data Needed",
                                message: "Track habits for 14+ days with HRV data (Apple Watch required).",
                                icon: "applewatch"
                            )
                            .padding(.horizontal, 20)
                        } else {
                            VStack(spacing: 0) {
                                ForEach(viewModel.hrvImpacts) { impact in
                                    MetricImpactRow(impact: impact)
                                        .padding(.horizontal, 20)
                                }
                            }
                        }
                    }

                    InsightsDivider()
                        .padding(.horizontal, 20)
                }

                // RHR Association Section
                if insightsConfig.isEnabled(.rhrImpact) {
                    VStack(alignment: .leading, spacing: 8) {
                        InsightsSectionHeader(
                            title: "Heart Rate Associations",
                            icon: "heart.fill",
                            color: .red
                        )
                        .padding(.horizontal, 20)

                        if viewModel.rhrImpacts.isEmpty {
                            InsightsEmptyStateCard(
                                title: "More Data Needed",
                                message: "Track habits for 14+ days with RHR data (Apple Watch required).",
                                icon: "applewatch"
                            )
                            .padding(.horizontal, 20)
                        } else {
                            VStack(spacing: 0) {
                                ForEach(viewModel.rhrImpacts) { impact in
                                    MetricImpactRow(impact: impact)
                                        .padding(.horizontal, 20)
                                }
                            }
                        }
                    }

                    InsightsDivider()
                        .padding(.horizontal, 20)
                }

                // Pain Association Section
                if insightsConfig.isEnabled(.painImpact) {
                    VStack(alignment: .leading, spacing: 8) {
                        InsightsSectionHeader(
                            title: "Pain Level Associations",
                            icon: "bolt.fill",
                            color: .orange
                        )
                        .padding(.horizontal, 20)

                        if viewModel.painImpacts.isEmpty {
                            InsightsEmptyStateCard(
                                title: "More Data Needed",
                                message: "Track your pain levels and habits for 14+ days to see associations.",
                                icon: "bolt.fill"
                            )
                            .padding(.horizontal, 20)
                        } else {
                            VStack(spacing: 0) {
                                ForEach(viewModel.painImpacts) { impact in
                                    MetricImpactRow(impact: impact)
                                        .padding(.horizontal, 20)
                                }
                            }
                        }
                    }

                    InsightsDivider()
                        .padding(.horizontal, 20)
                }

                // Water Intake Association Section
                if insightsConfig.isEnabled(.waterImpact) {
                    VStack(alignment: .leading, spacing: 8) {
                        InsightsSectionHeader(
                            title: "Hydration Associations",
                            icon: "drop.fill",
                            color: .cyan
                        )
                        .padding(.horizontal, 20)

                        if viewModel.waterImpacts.isEmpty {
                            InsightsEmptyStateCard(
                                title: "More Data Needed",
                                message: "Track your water intake and habits for 14+ days to see associations.",
                                icon: "drop.fill"
                            )
                            .padding(.horizontal, 20)
                        } else {
                            VStack(spacing: 0) {
                                ForEach(viewModel.waterImpacts) { impact in
                                    MetricImpactRow(impact: impact)
                                        .padding(.horizontal, 20)
                                }
                            }
                        }
                    }
                }

                // Bottom spacer
                Color.clear
                    .frame(height: 120)
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
            // Deep navy background
            Color(red: 0.06, green: 0.10, blue: 0.18)
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
