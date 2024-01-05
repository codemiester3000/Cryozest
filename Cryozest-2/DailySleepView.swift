import SwiftUI

class DailySleepViewModel: ObservableObject {
    // Add your variables here
    @Published var tempVar: Int
    
    init() {
        tempVar = 5
    }
}

struct DailySleepView: View {
    @ObservedObject var dailySleepModel: DailySleepViewModel
    
    var body: some View {
        /*@START_MENU_TOKEN@*//*@PLACEHOLDER=Hello, world!@*/Text("Hello, world!")/*@END_MENU_TOKEN@*/
    }
}
