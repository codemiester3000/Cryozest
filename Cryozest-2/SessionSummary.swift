import SwiftUI

import SwiftUI

struct SessionSummary: View {
    @State private var duration: TimeInterval
    @State private var temperature: Int
    @State private var humidity: Int
    @State private var therapyType: TherapyType
    @State private var bodyWeight: Double
    @Binding var sessions: [LogbookView.Session]
    @Environment(\.presentationMode) var presentationMode
    
    init(duration: TimeInterval, temperature: Int, humidity: Int, therapyType: TherapyType, bodyWeight: Double, sessions: Binding<[LogbookView.Session]>) {
        _duration = State(initialValue: duration)
        _temperature = State(initialValue: temperature)
        _humidity = State(initialValue: humidity)
        _therapyType = State(initialValue: therapyType)
        _bodyWeight = State(initialValue: bodyWeight)
        _sessions = sessions
    }
    
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
                    .font(.system(size: 24, design: .rounded))
                    .multilineTextAlignment(.center)
                    .padding()
                    .foregroundColor(.white)
                
                Text(waterMessage)
                    .font(.system(size: 18, design: .rounded))
                    .multilineTextAlignment(.center)
                    .padding()
                    .foregroundColor(.white)
                
                HStack {
                    Button(action: discardSession) {
                        Text("Discard")
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                            .font(.headline)
                    }
                    .padding([.leading, .bottom, .trailing])
                    
                    Button(action: logSession) {
                        Text("Log Session")
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                            .font(.headline)
                    }
                    .padding([.leading, .bottom, .trailing])
                }
                
                Spacer()
            }
            .padding(.horizontal)
            .background(Color.darkBackground.edgesIgnoringSafeArea(.all))
            .navigationBarTitle("\(therapyType.rawValue) Session Summary", displayMode: .inline)
        }
    
    private func logSession() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"
        let session = LogbookView.Session(date: dateFormatter.string(from: Date()), duration: duration, temperature: temperature, humidity: humidity, therapyType: therapyType)
        
        sessions.append(session)
        
        presentationMode.wrappedValue.dismiss()
    }
    
    private func discardSession() {
        presentationMode.wrappedValue.dismiss()
    }
}

struct SessionSummary_Previews: PreviewProvider {
    static var previews: some View {
        SessionSummary(duration: 1500, temperature: 20, humidity: 50, therapyType: .drySauna, bodyWeight: 150, sessions: .constant([]))
    }
}

