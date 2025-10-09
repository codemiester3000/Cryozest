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
        ZStack {
            // Modern gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.05, green: 0.15, blue: 0.25),
                    Color(red: 0.1, green: 0.2, blue: 0.35),
                    Color(red: 0.15, green: 0.25, blue: 0.4)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Subtle gradient overlay
            RadialGradient(
                gradient: Gradient(colors: [
                    Color.blue.opacity(0.3),
                    Color.clear
                ]),
                center: .topTrailing,
                startRadius: 100,
                endRadius: 500
            )
            .ignoresSafeArea()

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
                    HStack(spacing: 8) {
                        Text("Save Timers")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                    }
                    .foregroundColor(Color(red: 0.05, green: 0.15, blue: 0.25))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [.white, Color.white.opacity(0.95)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(14)
                    .shadow(color: .white.opacity(0.3), radius: 12, x: 0, y: 6)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
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
