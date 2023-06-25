import SwiftUI
import CoreData

struct DurationAnalysisView: View {
    var totalTime: TimeInterval
    var totalSessions: Int
    var timeFrame: TimeFrame
    var therapyType: TherapyType
    var currentStreak: Int
    var longestStreak: Int
    var sessions: FetchedResults<TherapySessionEntity>
    
    @State private var isLoading: Bool = true
    
    var body: some View {
        
        Group {
            if (isLoading) {
                LoadingView()
                    .frame(maxWidth: .infinity)
                    .background(Color(.darkGray))
                    .cornerRadius(16)
            } else {
                VStack(alignment: .leading) {
                    HStack {
                        Text("Summary")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        VStack(spacing: 15) {
                            Text(timeFrame.displayString())
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(therapyType.color)
                                .cornerRadius(8)
                        }
                    }
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Total Sessions")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.7))
                            Text("\(totalSessions)")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                        .padding(.top, 10)
                        
                        Spacer()
                        
                        VStack(alignment: .leading) {
                            Text("Total Time")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.7))
                            Text("\(Int(totalTime / 60)) mins")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                        .padding(.top, 10)
                    }
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Current Streak")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.7))
                            Text("\(currentStreak) days")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                        .padding(.top, 10)
                        
                        Spacer()
                    }
                    
                    StreakCalendarView(therapySessions: Array(sessions), therapyType: therapyType)
                        .padding(.top, 10)
                        .padding(.bottom, 10)
                }
                .frame(maxWidth: .infinity)
                .padding(EdgeInsets(top: 20, leading: 30, bottom: 20, trailing: 30))
                .background(Color(.darkGray))
                .cornerRadius(16)
                
            }
        }
        .onAppear {
            startLoading()
        }
        .onChange(of: therapyType) { _ in
            startLoading()
        }
        
    }
    
    private func startLoading() {
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isLoading = false
        }
    }
}

