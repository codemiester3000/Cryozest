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
    
    @State private var allTherapyTypes: [TherapyType] = TherapyType.allCases
    
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
                    
                    
                    ForEach(allTherapyTypes, id: \.self) { therapyType in
                        Button(action: {
                            switch therapyType {
                            case .custom1:
                                if !selectedTypes.contains(therapyType) {
                                    selectedCustomType = therapyType
                                    isCustomTypeViewPresented = true
                                }
                            case .custom2:
                                if !selectedTypes.contains(therapyType) {
                                    selectedCustomType = therapyType
                                    isCustomTypeViewPresented = true
                                }
                            case .custom3:
                                if !selectedTypes.contains(therapyType) {
                                    selectedCustomType = therapyType
                                    isCustomTypeViewPresented = true
                                }
                            case .custom4:
                                if !selectedTypes.contains(therapyType) {
                                    selectedCustomType = therapyType
                                    isCustomTypeViewPresented = true
                                }
                            default:
                                print()
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
                                Text(therapyType.displayName(managedObjectContext))
                                    .fontWeight(.medium) // Slightly bolder text for better readability
                                    .foregroundColor(.white) // Use primary color for better adaptability to dark/light mode
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
                            .accessibility(label: Text("Therapy type: \(therapyType.displayName(managedObjectContext))")) // Accessibility label for better UI/UX
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
                CustomTherapyTypeNameView(allTherapyTypes: self.allTherapyTypes, therapyType: Binding.constant(selectedCustomType), onSave: refreshUI)
            }
        }
    }
    
    func refreshUI() {
        // Trigger some state change that causes the view to redraw
        // For instance, you could toggle a boolean State variable
        self.showAlert = false // As an example
        // Add any other logic to refresh data if needed
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

import CoreData

struct CustomTherapyTypeNameView: View {
    @State  var allTherapyTypes: [TherapyType]
    @Binding var therapyType: TherapyType
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) private var managedObjectContext
    @State private var customName: String = ""
    
    var onSave: () -> Void
    
    var body: some View {
        Form {
            TextField("Enter Custom Name", text: $customName)
            Button("Save") {
                saveCustomTherapy()
                presentationMode.wrappedValue.dismiss()
            }
        }
        .navigationBarTitle("Set Custom Name", displayMode: .inline)
        .onAppear() {
            loadCustomTherapyName()
        }
    }
    
    private func loadCustomTherapyName() {
        let therapyID = therapyTypeToID(therapyType)
        
        let fetchRequest: NSFetchRequest<CustomTherapy> = CustomTherapy.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %d", therapyID)
        
        do {
            let results = try managedObjectContext.fetch(fetchRequest)
            if let existingTherapy = results.first {
                self.customName = existingTherapy.name ?? ""
            }
        } catch {
            // Handle error
            print("Error loading custom therapy: \(error)")
        }
    }
    
    private func saveCustomTherapy() {
        let therapyID = therapyTypeToID(therapyType)
        
        let fetchRequest: NSFetchRequest<CustomTherapy> = CustomTherapy.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %d", therapyID)
        
        do {
            let results = try managedObjectContext.fetch(fetchRequest)
            let therapy: CustomTherapy
            
            print("therapyId, ", therapyID)
            
            print("results: ", results)
            
            if let existingTherapy = results.first {
                // Update existing therapy
                therapy = existingTherapy
            } else {
                // Create new therapy
                therapy = CustomTherapy(context: managedObjectContext)
                therapy.id = therapyID
            }
            
            therapy.name = customName
            try managedObjectContext.save()
            
            allTherapyTypes = []
            allTherapyTypes = TherapyType.allCases
        } catch {
            // Handle error
            print("Error saving custom therapy: \(error)")
        }
    }
    
    private func therapyTypeToID(_ therapyType: TherapyType) -> Int16 {
        switch therapyType {
        case .custom1:
            return 1
        case .custom2:
            return 2
        case .custom3:
            return 3
        case .custom4:
            return 4
        default:
            return 0 // Or handle other cases as needed
        }
    }
}

