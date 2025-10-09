import SwiftUI

struct CreateTimerView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode // Add this line
    @FetchRequest(
        entity: CustomTimer.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \CustomTimer.duration, ascending: true)]
    ) private var timers: FetchedResults<CustomTimer>
    
    @State private var durations = [10, 15]

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

            VStack(spacing: 24) {
                Text("Customize Timer Durations")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.top, 40)

                ForEach(0..<2) { index in
                    VStack(spacing: 12) {
                        Text("Timer \(index + 1)")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.white.opacity(0.9))
                        Picker(selection: $durations[index], label: Text("Duration")) {
                            ForEach(1...60, id: \.self) {
                                Text("\($0) min")
                                    .foregroundColor(.white)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.08))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                                )
                        )
                        .frame(height: 120)
                        .foregroundColor(.white)
                        .labelsHidden()
                    }
                }
                
                Spacer()

                Button(action: {
                    saveDurations()
                    self.presentationMode.wrappedValue.dismiss()
                }) {
                    HStack(spacing: 10) {
                        Text("Save Timers")
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.cyan,
                                Color.cyan.opacity(0.8)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(14)
                    .shadow(color: Color.cyan.opacity(0.4), radius: 12, x: 0, y: 6)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
            .padding()
        }
        .onAppear(perform: loadTimers)
    }
    
    private func loadTimers() {
        if timers.count >= 2 {
            durations = Array(timers.prefix(2).map { Int($0.duration) })
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
