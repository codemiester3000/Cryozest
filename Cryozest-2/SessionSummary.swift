import SwiftUI
import CoreData

struct SessionSummary: View {
    @Binding private var therapyType: TherapyType
    @State private var durationHours: Int
    @State private var durationMinutes: Int
    @State private var durationSeconds: Int
    @State private var temperature: Int = 70
    @State private var bodyWeight: Double
    @State private var showDurationPicker = false
    @State private var showTemperaturePicker = false
    @Environment(\.presentationMode) var presentationMode
    
    @Environment(\.managedObjectContext) private var viewContext
    
    init(duration: TimeInterval, temperature: Int, therapyType: Binding<TherapyType>, bodyWeight: Double) {
        _durationHours = State(initialValue: Int(duration) / 3600)
        _durationMinutes = State(initialValue: (Int(duration) / 60) % 60)
        _durationSeconds = State(initialValue: Int(duration) % 60)
        _temperature = State(initialValue: temperature)
        _therapyType = therapyType
        _bodyWeight = State(initialValue: bodyWeight)
    }
    
    private var totalDurationInSeconds: TimeInterval {
        return TimeInterval((durationHours * 3600) + (durationMinutes * 60) + durationSeconds)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Summary").foregroundColor(.white).font(.system(size: 30, design: .monospaced)).padding()
                Spacer()
            }
            
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
            
            // Duration
            HStack {
                Text("Duration: \(durationMinutes) min \(durationSeconds) sec")
                    .foregroundColor(.white)
                    .font(.system(size: 16, design: .monospaced))
                Spacer()
                Button(action: { showDurationPicker.toggle() }) {
                    Text("Edit")
                        .foregroundColor(.orange)
                        .font(.system(size: 16, design: .monospaced))
                        .bold()
                }
                .sheet(isPresented: $showDurationPicker) {
                    VStack {
                        Text("Choose Duration")
                            .font(.title)
                        HStack {

                            
                            Picker("Minutes", selection: $durationMinutes) {
                                ForEach(0..<60) {
                                    Text("\($0) min")
                                }
                            }
                            .pickerStyle(WheelPickerStyle())
                            .frame(width: 100)
                            .clipped()
                            
                            Picker("Seconds", selection: $durationSeconds) {
                                ForEach(0..<60) {
                                    Text("\($0) sec")
                                }
                            }
                            .pickerStyle(WheelPickerStyle())
                            .frame(width: 100)
                            .clipped()
                        }
                        Button("Done", action: { showDurationPicker.toggle() })
                            .padding()
                            .foregroundColor(.white)
                            .background(Color.orange)
                            .cornerRadius(8)
                    }
                }
            }
            .padding()
            
            // Temperature
            HStack {
                Text("Temperature: \(temperature)°F")
                    .foregroundColor(.white)
                    .font(.system(size: 16, design: .monospaced))
                Spacer()
                Button(action: { showTemperaturePicker.toggle() }) {
                    Text("Edit")
                        .foregroundColor(.orange)
                        .font(.system(size: 16, design: .monospaced))
                        .bold()
                }
                .sheet(isPresented: $showTemperaturePicker) {
                    VStack {
                        Text("Choose Temperature")
                            .font(.title)
                        Picker("Temperature", selection: $temperature) {
                            ForEach(32...212, id: \.self) { temp in
                                Text("\(temp)°F")
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(width: 150, height: 150)
                        .clipped()
                        Button("Done", action: { showTemperaturePicker.toggle() })
                            .padding()
                            .foregroundColor(.white)
                            .background(Color.orange)
                            .cornerRadius(8)
                    }
                }
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
    }
    
    
    private func logSession() {
        let newSession = TherapySessionEntity(context: viewContext)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"
        newSession.date = dateFormatter.string(from: Date())
        newSession.duration = totalDurationInSeconds
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

struct EditValueView: View {
    @Binding var value: String
    @Environment(\.presentationMode) var presentationMode
    let title: String
    let message: String
    
    var body: some View {
        VStack {
            Text(title)
                .font(.title)
            Text(message)
                .font(.subheadline)
            TextField("Enter value", text: $value)
                .padding()
                .keyboardType(.numberPad)
            Button("Done", action: {
                presentationMode.wrappedValue.dismiss()
            })
            .padding()
        }
        .padding()
    }
}
