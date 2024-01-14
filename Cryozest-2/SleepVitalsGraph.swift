import SwiftUI

class SleepVitalsDataModel: ObservableObject {
    var timeFrame: TimeFrame {
        didSet {
            fetchSleepVitalsData()
        }
    }
    
    var sessions: FetchedResults<TherapySessionEntity>
    
    @Published var therapyType: TherapyType {
        didSet {
            fetchSleepVitalsData()
        }
    }
    
    // Resting Heart Rate
    @Published var baselineRestingHeartRate: Double
    @Published var excerciseRestingHeartRate: Double
    
    // Resting Heart Rate Variability
    @Published var baselineRestingHRV: Double
    @Published var excerciseRestingHRV: Double
    
    init(therapyType: TherapyType, timeFrame: TimeFrame, sessions: FetchedResults<TherapySessionEntity>) {
        self.sessions = sessions
        self.timeFrame = timeFrame
        self.therapyType = therapyType
        
        baselineRestingHeartRate = 0.0
        excerciseRestingHeartRate = 0.0
        
        baselineRestingHRV = 0.0
        excerciseRestingHRV = 0.0
        
        fetchSleepVitalsData()
    }
    
    private func fetchSleepVitalsData() {
        // TODO: Implement
    }
    
    
}

struct SleepVitalsGraph: View {
    @ObservedObject var model: SleepVitalsDataModel
    
    var body: some View {
        VStack(alignment: .leading) {
            BarGraphView(
                title: "Resting Heart Rate",
                baselineValue: 50.0,
                excerciseValue: 150.0,
                barColor: model.therapyType.color
            )
            .padding(.bottom)
            
            BarGraphView(
                title: "Resting Heart Rate Variability",
                baselineValue: 70.0,
                excerciseValue: 225.0,
                barColor: model.therapyType.color
            )
            .padding(.bottom)
            
        }
    }
}

struct BarGraphView: View {
    var title: String
    var baselineValue: Double
    var excerciseValue: Double
    var barColor: Color
    
    // These are used for the growing animation.
    @State private var baselineBarWidth: CGFloat = 0
    @State private var exerciseBarWidth: CGFloat = 0
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.footnote)
                .foregroundColor(.white)
            Rectangle()
                .fill(LinearGradient(gradient: Gradient(colors: [Color.gray.opacity(0.5), .gray]), startPoint: .leading, endPoint: .trailing))
                .frame(width: baselineBarWidth, height: 20)
                .onAppear {
                    withAnimation(.linear(duration: 3.0)) {
                        baselineBarWidth = baselineValue
                    }
                }
                .cornerRadius(6.0)
            
            Rectangle()
                .fill(LinearGradient(gradient: Gradient(colors: [barColor.opacity(0.6), barColor.opacity(0.9)]), startPoint: .leading, endPoint: .trailing))
                .frame(width: excerciseValue, height: 20)
                .onAppear {
                    withAnimation(.linear(duration: 3.0)) {
                        exerciseBarWidth = excerciseValue
                    }
                }
                .cornerRadius(6.0)
        }
    }
}
