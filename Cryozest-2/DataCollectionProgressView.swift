//
//  DataCollectionProgressView.swift
//  Cryozest-2
//
//  Shows progress toward unlocking insights for a habit
//

import SwiftUI

struct DataCollectionProgressView: View {
    let progress: DataCollectionProgress
    let habitColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.08))

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [habitColor.opacity(0.5), habitColor.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * progress.overallProgress)
                        .animation(.easeInOut(duration: 0.5), value: progress.overallProgress)
                }
            }
            .frame(height: 4)

            // Description text
            Text(progress.progressDescription)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.45))
                .lineLimit(1)
        }
    }
}
