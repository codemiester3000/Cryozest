import SwiftUI

class ExertionModel: ObservableObject {
    
    // Put necessary variables
    
    @Published var exertionScore: Double
    
    init() {
        // Make HealthKitManager method calls to populate @Published variables
        exertionScore = 10.0
    }
    
    // Add functions to pull data here
}

struct ExertionView: View {
    
    @ObservedObject var model: ExertionModel
    
    var body: some View {
        Text("hello world")
    }
}
