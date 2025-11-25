//
//  InsightsConfigSheet.swift
//  Cryozest-2
//
//  Configuration sheet for Insights sections
//

import SwiftUI

struct InsightsConfigSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var config = InsightsConfigurationManager.shared

    var body: some View {
        NavigationView {
            ZStack {
                // Deep navy background
                Color(red: 0.06, green: 0.10, blue: 0.18)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Customize Insights")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)

                            Text("Choose which insights you want to see")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.top)

                        // Section toggles
                        VStack(spacing: 16) {
                            ForEach(InsightSection.allCases) { section in
                                InsightSectionToggle(section: section, isEnabled: config.isEnabled(section)) {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        config.toggle(section)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)

                        // Bottom spacer
                        Color.clear.frame(height: 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(.cyan)
                }
            }
        }
    }
}

struct InsightSectionToggle: View {
    let section: InsightSection
    let isEnabled: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(section.color.opacity(isEnabled ? 0.2 : 0.1))
                        .frame(width: 50, height: 50)

                    Image(systemName: section.icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(isEnabled ? section.color : section.color.opacity(0.4))
                }

                // Label and description
                VStack(alignment: .leading, spacing: 4) {
                    Text(section.rawValue)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(isEnabled ? .white : .white.opacity(0.5))

                    Text(section.description)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(isEnabled ? .white.opacity(0.6) : .white.opacity(0.3))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                // Toggle indicator
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isEnabled ? section.color.opacity(0.3) : Color.white.opacity(0.1))
                        .frame(width: 50, height: 30)

                    Circle()
                        .fill(isEnabled ? section.color : Color.white.opacity(0.4))
                        .frame(width: 26, height: 26)
                        .offset(x: isEnabled ? 10 : -10)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(isEnabled ? 0.1 : 0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isEnabled ? section.color.opacity(0.3) : Color.white.opacity(0.1), lineWidth: 1.5)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
