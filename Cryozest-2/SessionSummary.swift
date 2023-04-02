import SwiftUI
import CoreData

struct SessionSummary: View {
    @State private var duration: TimeInterval
    @State private var temperature: Double
    @State private var therapyType: TherapyType
    @State private var bodyWeight: Double
    @Binding var sessions: [TherapySession]
    @Environment(\.presentationMode) var presentationMode
    
    @Environment(\.managedObjectContext) private var viewContext
    
    init(duration: TimeInterval, temperature: Double, therapyType: TherapyType, bodyWeight: Double, sessions: Binding<[TherapySession]>) {
        _duration = State(initialValue: duration)
        _temperature = State(initialValue: temperature)
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
            
            // Therapy Type Picker
            VStack(alignment: .leading, spacing: 10) {
                Text("Therapy Type: ")
                    .foregroundColor(.white)
                    .font(.headline)
                Picker(selection: $therapyType, label: Text("Therapy Type")) {
                    ForEach(TherapyType.allCases) { therapyType in
                        Text(therapyType.rawValue)
                            .tag(therapyType)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .accentColor(.blue)
            }
            .padding()
            
            // Temperature Slider
            VStack(alignment: .leading, spacing: 10) {
                Text("Temperature (F): \(Int(temperature))")
                    .foregroundColor(.white)
                    .font(.headline)
                Slider(value: $temperature, in: 60...250, step: 1)
                    .accentColor(.blue)
            }
            .padding()
    
            
            // Body Weight Slider
            VStack(alignment: .leading, spacing: 10) {
                Text("Body Weight (lbs): \(Int(bodyWeight))")
                    .foregroundColor(.white)
                    .font(.headline)
                Slider(value: $bodyWeight, in: 80...400, step: 1)
                    .accentColor(.blue)
            }
            .padding()
            
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
        let newSession = TherapySessionEntity(context: viewContext)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"
        newSession.date = dateFormatter.string(from: Date())
        newSession.duration = duration
        newSession.temperature = Double(temperature)
        newSession.therapyType = therapyType.rawValue
        newSession.id = UUID()
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        
        presentationMode.wrappedValue.dismiss()
    }
    
    private func discardSession() {
        presentationMode.wrappedValue.dismiss()
    }
}

struct SessionSummary_Previews: PreviewProvider {
    static var previews: some View {
        SessionSummary(duration: 1500, temperature: 20, therapyType: .drySauna, bodyWeight: 150, sessions: .constant([]))
    }
}
