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
    
    @State private var customTherapyNames: [String] = ["custom 1", "custom 2", "custom 3", "custom 4"]
    
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
                    Text("Select up to 4 exercisesr")
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
                                isCustomTypeViewPresented = false
                            }
                        }) {
                            HStack {
                                Image(systemName: therapyType.icon)
                                    .foregroundColor(selectedTypes.contains(therapyType) ? .white : therapyType.color) // Dynamic icon color
                                    .imageScale(.large) // Larger icon for better visibility
                                Text(getDisplayName(therapyType: therapyType))
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
                fetchCustomTherapyNames()
            }
            .padding(.horizontal, 12)
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        .sheet(isPresented: $isCustomTypeViewPresented, onDismiss: {
            isCustomTypeViewPresented = false
        }) {
            if let selectedCustomType = selectedCustomType {
                CustomTherapyTypeNameView(therapyType: Binding.constant(selectedCustomType), customTherapyNames: $customTherapyNames)
            }
        }
    }
    
    func fetchCustomTherapyNames() {
        let fetchRequest: NSFetchRequest<CustomTherapy> = CustomTherapy.fetchRequest()
        do {
            let therapies = try managedObjectContext.fetch(fetchRequest)
            for therapy in therapies {
                if let name = therapy.name, therapy.id > 0, therapy.id <= customTherapyNames.count {
                    customTherapyNames[Int(therapy.id) - 1] = name
                }
            }
        } catch {
            print("Error fetching custom therapies: \(error)")
        }
    }
    
    
    func getDisplayName(therapyType: TherapyType) -> String {
        if therapyType == .custom1 {
            return customTherapyNames[0]
        }
        
        if therapyType == .custom2 {
            return customTherapyNames[1]
        }
        
        if therapyType == .custom3 {
            return customTherapyNames[2]
        }
        
        if therapyType == .custom4 {
            return customTherapyNames[3]
        }
        
        return therapyType.displayName(managedObjectContext)
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
    @Binding var therapyType: TherapyType
    @Binding var customTherapyNames: [String]
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) private var managedObjectContext
    @State private var customName: String = ""
    
    var body: some View {
        VStack {
            // Title Section
            Text("Custom")
                .font(.title)
                .fontWeight(.bold)
                .padding(.top, 20)
            
            Text("Enter a name for your custom therapy type.")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.bottom, 20)
            
            // Form Section
            Form {
                Section() {
                    TextField("Enter Custom Name", text: $customName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                }
                
                Section {
                    Button(action: {
                        saveCustomTherapy()
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Save")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(minWidth: 0, maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                }
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
            
            if let existingTherapy = results.first {
                // Update existing therapy
                therapy = existingTherapy
            } else {
                // Create new therapy
                therapy = CustomTherapy(context: managedObjectContext)
                therapy.id = therapyID
            }
            
            customTherapyNames[Int(therapyID) - 1] = customName
            therapy.name = customName
            try managedObjectContext.save()
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

