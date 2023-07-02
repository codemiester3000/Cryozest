import SwiftUI

struct CreateTimerView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode // Add this line
    @FetchRequest(
        entity: CustomTimer.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \CustomTimer.duration, ascending: true)]
    ) private var timers: FetchedResults<CustomTimer>
    
    @State private var durations = [5, 10, 15]
    
    var body: some View {
        ZStack {  // Wrapping content in ZStack for full background coverage
            LinearGradient(
                gradient: Gradient(colors: [Color.gray, Color.gray.opacity(0.8)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all) // Now the gradient covers whole background
            
            VStack(spacing: 20) {
                ForEach(0..<3) { index in
                    VStack {  // Added VStack for each picker and title
                        Text("Timer \(index + 1)") // Titles for each picker
                            .font(.headline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        Picker(selection: $durations[index], label: Text("Duration")) {
                            ForEach(1...60, id: \.self) {
                                Text("\($0) min")
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(15)
                        .frame(height: 100) // Reduced height for pickers
                        .foregroundColor(.white)
                        .labelsHidden()
                    }
                    .padding(.top, 20)
                }
                
                Spacer()
                
                Button(action: {
                    saveDurations()
                    self.presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Done")
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .padding(.horizontal, 80)
                        .padding(.vertical, 14)
                        .background(.orange
                        )
                        .cornerRadius(40)
                        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 10)
                }
                .padding()
            }
            .padding()
        }
        .onAppear(perform: loadTimers)
    }
    
    private func loadTimers() {
        if !timers.isEmpty {
            durations = timers.map { Int($0.duration) }
        }
    }
    
    private func saveDurations() {
        deleteExistingTimers()
        
        for duration in durations {
            let newTimer = CustomTimer(context: viewContext)
            newTimer.duration = Int32(duration)
        }
        
        try? viewContext.save()
    }
    
    private func deleteExistingTimers() {
        for timer in timers {
            viewContext.delete(timer)
        }
    }
}
