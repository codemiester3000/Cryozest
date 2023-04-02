import SwiftUI

struct CustomDurationPickerView: View {
    @Binding var customDuration: TimeInterval
    @Environment(\.presentationMode) var presentationMode

    @State private var minutes: Int = 0
    @State private var seconds: Int = 0

    var body: some View {
        NavigationView {
            VStack {
                Text("Custom Duration")
                    .font(.largeTitle)
                    .bold()
                    .padding()
                
                HStack {
                    Picker("", selection: $minutes) {
                        ForEach(0..<60) { minute in
                            Text("\(minute) min")
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                    .labelsHidden()
                    .frame(maxWidth: .infinity)
                    
                    Picker("", selection: $seconds) {
                        ForEach(0..<60) { second in
                            Text("\(second) sec")
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                    .labelsHidden()
                    .frame(maxWidth: .infinity)
                }
                .padding()

                Button(action: {
                    customDuration = TimeInterval(minutes * 60 + seconds)
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Set Timer")
                        .font(.title2)
                        .bold()
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.bottom, 8)
            }
            .navigationBarTitle("Custom Timer", displayMode: .inline)
        }
    }
}

struct CustomDurationPickerView_Previews: PreviewProvider {
    static var previews: some View {
        CustomDurationPickerView(customDuration: .constant(0))
    }
}
