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

    @StateObject private var viewModelWrapper = InsightsViewModelWrapper()

    private var selectedTherapyTypes: [TherapyType] {
        if selectedTherapies.isEmpty {
            return [.drySauna, .weightTraining, .coldPlunge, .meditation]
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
        .onAppear {
            // Initialize viewModel on appear with actual sessions
            if viewModelWrapper.viewModel == nil {
                viewModelWrapper.viewModel = InsightsViewModel(
                    sessions: sessions,
                    selectedTherapyTypes: selectedTherapyTypes
                )
            }
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

                    // Info button
                    Button(action: {}) {
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

                // Health Trends Section (always show if available)
                if !viewModel.healthTrends.isEmpty {
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

                    if !viewModel.topHabitImpacts.isEmpty {
                        Divider()
                            .background(Color.white.opacity(0.2))
                            .padding(.vertical, 8)
                            .padding(.horizontal)
                    }
                }

                // Top Performers Section (always show)
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

                // Sleep Impact Section (always show)
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
                            message: "Enable sleep tracking in the Health app or wear an Apple Watch to see how your habits affect your sleep duration.",
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

                // HRV Impact Section (always show)
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

                // RHR Impact Section (always show)
                VStack(alignment: .leading, spacing: 16) {
                    InsightsSectionHeader(
                        title: "Resting Heart Rate Impact",
                        icon: "heart.fill",
                        color: .red
                    )
                    .padding(.horizontal)

                    if viewModel.rhrImpacts.isEmpty {
                        InsightsEmptyStateCard(
                            title: "Apple Watch Required",
                            message: "Wear an Apple Watch to track Resting Heart Rate and see how your habits optimize your RHR.",
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
            .padding(.bottom, 40)
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
