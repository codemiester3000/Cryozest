import SwiftUI

struct SessionSummary: View {
    @Binding var duration: TimeInterval
    @Binding var temperature: Int
    @Binding var humidity: Int
    @Binding var therapyType: TherapyType
    @Binding var bodyWeight: Double
    
    private var waterConsumption: Int {
        let waterOunces = bodyWeight / 30
        return Int(waterOunces * (duration / 900)) // 900 seconds = 15 minutes
    }
    
    private var motivationalMessage: String {
        switch duration {
        case ..<300: // less than 5 minutes
            return "Good work, next time try and go for a little bit longer."
        case 300..<900: // 5-15 minutes
            return "Great job on that session!"
        case 900..<1800: // 15-30 minutes
            return "Awesome work, you're really building up your tolerance!"
        default: // 30+ minutes
            return "WOW, great work on that intense session!"
        }
    }
    
    private var waterMessage: String {
        return "Drink \(waterConsumption) ounces of water every 15 minutes to stay hydrated during a demanding activity."
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text(motivationalMessage)
                .font(.title)
                .multilineTextAlignment(.center)
                .padding()
            
            Text(waterMessage)
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding()
            
            Spacer()
        }
        .navigationBarTitle("\(therapyType.rawValue) Session Summary", displayMode: .inline)
    }
}

struct SessionSummary_Previews: PreviewProvider {
    static var previews: some View {
        SessionSummary(duration: .constant(1500), temperature: .constant(20), humidity: .constant(50), therapyType: .constant(.drySauna), bodyWeight: .constant(150))
    }
}

