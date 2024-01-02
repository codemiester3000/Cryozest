import SwiftUI
import CoreData

struct TherapyTypeSelectionView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) var managedObjectContext
    @EnvironmentObject var appState: AppState
    @State var selectedTypes: [TherapyType] = []
    @State var showAlert = false
    @State var alertTitle = ""
    @State var alertMessage = ""
    
    @State private var isCustomTypeViewPresented = false
    @State private var selectedCustomType: TherapyType?
    
    @FetchRequest(
        entity: SelectedTherapy.entity(),
        sortDescriptors: []
    ) private var selectedTherapies: FetchedResults<SelectedTherapy>
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [.black, .black]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)
            
            VStack {
                ScrollView {
                    Text("Select up to 4 therapy types")
                        .font(.system(size: 24, weight: .bold, design: .default))
                        .fontWeight(.semibold) // Slightly heavier font weight for emphasis
                        .foregroundColor(.white)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 20) // Add horizontal padding for better spacing
                        .cornerRadius(10) // Rounded corners for a smoother look
                        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2) // Subtle shadow for depth
                        .multilineTextAlignment(.center) // Center align for better readability in multiple lines
                        .frame(maxWidth: .infinity) // Ensure it spans the width of the container
                        .lineLimit(2) // Limit to 2 lines to maintain layout consistency
                    
                    
                    ForEach(TherapyType.allCases, id: \.self) { therapyType in
                        Button(action: {
                            if case .custom1 = therapyType {
                                selectedCustomType = therapyType
                                isCustomTypeViewPresented = true
                            }
                            if selectedTypes.contains(therapyType) {
                                selectedTypes.removeAll(where: { $0 == therapyType })
                            } else if selectedTypes.count < 4 {
                                selectedTypes.append(therapyType)
                            } else {
                                // user tried to select a 5th type
                                alertTitle = "Too Many Types"
                                alertMessage = "Please remove a type before adding another."
                                showAlert = true
                            }
                        }) {
                            HStack {
                                Image(systemName: therapyType.icon)
                                    .foregroundColor(selectedTypes.contains(therapyType) ? .white : therapyType.color) // Dynamic icon color
                                    .imageScale(.large) // Larger icon for better visibility
                                Text(therapyType.rawValue)
                                    .fontWeight(.medium) // Slightly bolder text for better readability
                                    .foregroundColor(.primary) // Use primary color for better adaptability to dark/light mode
                                Spacer()
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8) // Balanced padding
                            .background(selectedTypes.contains(therapyType) ? therapyType.color : .clear) //
                            .cornerRadius(8) // Rounded corners
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(therapyType.color, lineWidth: 2) // Colored border
                            )
                            .shadow(color: .gray.opacity(0.3), radius: 3, x: 0, y: 2) // Subtle shadow for depth
                            .animation(.easeInOut, value: selectedTypes.contains(therapyType)) // Smooth animation for selection changes
                            .accessibility(label: Text("Therapy type: \(therapyType.rawValue)")) // Accessibility label for better UI/UX
                            
                            
                            
                        }
                        .padding(.vertical, 2)
                    }
                }
                
                Spacer()
                Button(action: {
                    // Action handling logic
                    if selectedTypes.count < 2 {
                        alertTitle = "Too Few Types"
                        alertMessage = "Please select at least two types."
                        showAlert = true
                    } else {
                        saveSelectedTherapies(therapyTypes: selectedTypes, context: managedObjectContext)
                        appState.hasSelectedTherapyTypes = true
                        presentationMode.wrappedValue.dismiss()
                    }
                }) {
                    Text("Done")
                        .font(.footnote) // Updated font for better readability
                        .foregroundColor(.black)
                        .frame(minWidth: 0, maxWidth: .infinity) // Make the button width responsive
                        .padding(.vertical, 15)
                        .background(Color.white)
                        .cornerRadius(40)
                        .shadow(color: Color.black.opacity(0.25), radius: 8, x: 0, y: 4) // Refined shadow for depth
                        .overlay(
                            RoundedRectangle(cornerRadius: 40)
                                .stroke(Color.white.opacity(0.4), lineWidth: 1) // Subtle border for added detail
                        )
                }
                .padding(.horizontal, 20) // Padding to ensure the button does not touch the screen edges
                .padding(.bottom, 10) // Bottom padding for spacing from other elements
                .alert(isPresented: $showAlert) { // Alert for validation
                    Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("OK")))
                }
                
            }
            .onAppear {
                selectedTypes = selectedTherapies.compactMap { TherapyType(rawValue: $0.therapyType!) }
            }
            .padding(.horizontal, 12)
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        .sheet(isPresented: $isCustomTypeViewPresented) {
            if let selectedCustomType = selectedCustomType {
                CustomTherapyTypeNameView(therapyType: Binding.constant(selectedCustomType))
            }
        }
    }
    
    // Saves a therapy type to Core Data.
    func saveTherapyType(type: TherapyType, context: NSManagedObjectContext) {
        let selectedTherapy = SelectedTherapy(context: context)
        selectedTherapy.therapyType = type.rawValue
        do {
            try context.save()
        } catch let error {
            print("Failed to save therapy type: \(error)")
        }
    }
    
    // Deletes all selected therapies from Core Data.
    func deleteAllTherapies(context: NSManagedObjectContext) {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = SelectedTherapy.fetchRequest()
        
        do {
            if let results = try context.fetch(fetchRequest) as? [NSManagedObject] {
                for object in results {
                    context.delete(object)
                }
                try context.save()
            }
        } catch let error {
            print("Failed to delete therapies: \(error)")
        }
    }
    
    
    // Saves the selected therapies, deleting any existing selections first.
    func saveSelectedTherapies(therapyTypes: [TherapyType], context: NSManagedObjectContext) {
        // Delete all existing selections.
        deleteAllTherapies(context: context)
        
        // Save new selections.
        for type in therapyTypes {
            saveTherapyType(type: type, context: context)
        }
    }
}


struct CustomTherapyTypeNameView: View {
    @Binding var therapyType: TherapyType
    @Environment(\.presentationMode) var presentationMode
    @State private var customName: String = ""
    
    var body: some View {
        Form {
            TextField("Enter Custom Name", text: $customName)
            Button("Save") {
                // Update the name of the custom therapy type
//                if case .custom(_, let icon, let color) = therapyType {
//                    therapyType = .custom(name: customName, icon: icon, color: color)
//                }
                presentationMode.wrappedValue.dismiss()
            }
        }
        .navigationBarTitle("Set Custom Name", displayMode: .inline)
        .onAppear {
//            if case .custom(let name, _, _) = therapyType {
//                customName = name
//            }
        }
    }
}
