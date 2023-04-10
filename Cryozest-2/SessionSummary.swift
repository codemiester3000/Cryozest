import SwiftUI
import CoreData

struct SessionSummary: View {
    @State private var duration: TimeInterval
    @State private var temperature: Double
    @State private var therapyType: TherapyType
    @State private var bodyWeight: Double
    @Environment(\.presentationMode) var presentationMode
    
    @Environment(\.managedObjectContext) private var viewContext
    
    init(duration: TimeInterval, temperature: Double, therapyType: TherapyType, bodyWeight: Double) {
        _duration = State(initialValue: duration)
        _temperature = State(initialValue: temperature)
        _therapyType = State(initialValue: therapyType)
        _bodyWeight = State(initialValue: bodyWeight)
    }
    
    private var waterConsumption: Int {
        let waterOunces = (bodyWeight / 30)
        return Int(5 + waterOunces * (duration / 900)) // 900 seconds = 15 minutes
    }
    
    private var motivationalMessage: String {
        switch duration {
        case ..<60: // less than 5 minutes
            return "Good work, next time try and go for a little bit longer."
        case 60..<900: // 5-15 minutes
            return "Great job on that session. Keep up the good work!"
        case 900..<1800: // 15-30 minutes
            return "Awesome work, you're really building up your tolerance!"
        default: // 30+ minutes
            return "WOW, great work on that intense session!"
        }
    }
    
    private var waterMessage: String {
        return "Drink \(waterConsumption) ounces of fluids to rehydrate your body from that session!"
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text(motivationalMessage)
                .font(.system(size: 24, design: .rounded))
                .multilineTextAlignment(.center)
                .padding()
                .foregroundColor(.white)
            
            // TODO: Add back once we dynamically caluclate water consumption
            
            HStack {
                Text("Therapy Type: ")
                    .foregroundColor(.white)
                    .font(.system(size: 16, design: .monospaced))

                Spacer()

                Picker(selection: $therapyType, label: HStack {
                    Text("Therapy Type")
                        .foregroundColor(.orange)
                        .font(.system(size: 16, design: .monospaced))
                        .bold()
                    Image(systemName: "chevron.down")
                        .foregroundColor(.orange)
                }) {
                    ForEach(TherapyType.allCases) { therapyType in
                        Text(therapyType.rawValue)
                            .tag(therapyType)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .frame(maxWidth: .infinity)
                .padding(.horizontal)
                .background(RoundedRectangle(cornerRadius: 8).fill(LinearGradient(gradient: Gradient(colors: [Color.gray, Color.gray.opacity(0.8)]), startPoint: .top, endPoint: .bottom)))
                .padding(.trailing)
                .accentColor(.orange)
            }
            .padding()
            
            // Duration Slider
            VStack(alignment: .leading, spacing: 10) {
                Text("Duration (sec): \(Int(duration))")
                    .foregroundColor(.white)
                    .font(.system(size: 16, design: .monospaced))
                Slider(value: $duration, in: 0...3600, step: 1)
                    .accentColor(.orange)
            }
            .padding()
            
            
            
            // Temperature Slider
            VStack(alignment: .leading, spacing: 10) {
                Text("Temperature (F): \(Int(temperature))")
                    .foregroundColor(.white)
                    .font(.system(size: 16, design: .monospaced))
                Slider(value: $temperature, in: 60...250, step: 1)
                    .accentColor(.orange)
            }
            .padding()
    
            
            // Body Weight Slider
//            VStack(alignment: .leading, spacing: 10) {
//                Text("Body Weight (lbs): \(Int(bodyWeight))")
//                    .foregroundColor(.white)
//                    .font(.system(size: 14, design: .monospaced))
//                Slider(value: $bodyWeight, in: 80...400, step: 1)
//                    .accentColor(.orange)
//            }
//            .padding()
            
            HStack {
                Button(action: discardSession) {
                    Text("Discard")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .font(.system(size: 16, design: .monospaced))
                }
                .padding([.leading, .bottom, .trailing])
                
                Button(action: logSession) {
                    Text("Log Session")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .font(.system(size: 16, design: .monospaced))
                }
                .padding([.leading, .bottom, .trailing])
            }
            
            Spacer()
        }
        .padding(.horizontal)
        .background(LinearGradient(gradient: Gradient(colors: [Color.gray, Color.gray.opacity(0.8)]), startPoint: .top, endPoint: .bottom).edgesIgnoringSafeArea(.all))
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

extension Color {
    static let darkGray = Color(red: 30/255, green: 30/255, blue: 30/255)
}
