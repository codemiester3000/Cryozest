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
        VStack {
            ForEach(0..<3) { index in
                Picker(selection: $durations[index], label: Text("Duration")) {
                    ForEach(1...60, id: \.self) {
                        Text("\($0) min")
                    }
                }
            }
            Button(action: {
                saveDurations()
                self.presentationMode.wrappedValue.dismiss() // Add this line
            }) {
                Text("Done")
            }
        }.onAppear(perform: loadTimers)
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
