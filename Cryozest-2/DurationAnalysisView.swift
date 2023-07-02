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
                    
                    VStack {
                        HStack {
                            Text("Completed: ")
                                .font(.system(size: 18, weight: .bold, design: .default))
                                .fontWeight(.bold)
                                .foregroundColor(.orange)
                            Spacer()
                            
                            HStack {
                                Text("\(totalSessions) sessions")
                                    .font(.system(size: 18, weight: .bold, design: .default))
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 20)
                            }
                            .padding(.vertical, 5) // Provide some space
                            .background(therapyType.color.opacity(0.2))
                            .cornerRadius(15) // Adds rounded corners
                            
                        }
                        .padding(.vertical, 8)
                        
                        HStack {
                            Text("Time Spent: ")
                                .font(.system(size: 18, weight: .bold, design: .default))
                                .fontWeight(.bold)
                                .foregroundColor(.orange)
                            Spacer()
                            HStack {
                                Text("\(Int(totalTime / 60)) mins")
                                    .font(.system(size: 18, weight: .bold, design: .default))
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 20)
                            }
                            .padding(.vertical, 5) // Provide some space
                            .background(therapyType.color.opacity(0.2))
                            .cornerRadius(15) // Adds rounded corners
                        }
                        .padding(.vertical, 8)
                        
                        HStack {
                            
                            Text("Current Streak: ")
                                .font(.system(size: 18, weight: .bold, design: .default))
                                .fontWeight(.bold)
                                .foregroundColor(.orange)
                            
                            Spacer()
                            
                            HStack {
                                Text("\(currentStreak) days")
                                    .font(.system(size: 18, weight: .bold, design: .default))
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 20)
                            }
                            .padding(.vertical, 5) // Provide some space
                            .background(therapyType.color.opacity(0.2))
                            .cornerRadius(15) // Adds rounded corners
                        }
                        .padding(.vertical, 8)
                    }
                    .padding(.top, 4)
                    
//                    StreakCalendarView(therapySessions: Array(sessions), therapyType: therapyType)
//                        .padding(.top, 10)
//                        .padding(.bottom, 10)
                }
                .frame(maxWidth: .infinity)
                .padding(EdgeInsets(top: 20, leading: 30, bottom: 20, trailing: 30))
                .background(Color(.darkGray))
                .cornerRadius(16)
                .transition(.opacity) // The view will fade in when it appears
                .animation(.easeIn)
                
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isLoading = false
        }
    }
}

