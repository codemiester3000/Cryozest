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
    @State var selectedCategory: Category = Category.category0
    
    @State private var isCustomTypeViewPresented = false
    @State private var selectedCustomType: TherapyType?
    
    @State private var customTherapyNames: [String] = ["custom 1", "custom 2", "custom 3", "custom 4"]
    
    @FetchRequest(
        entity: SelectedTherapy.entity(),
        sortDescriptors: []
    ) private var selectedTherapies: FetchedResults<SelectedTherapy>
    
    @State private var animateContent = false

    var body: some View {
        ZStack {
            // Modern gradient background matching welcome screen
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

            VStack {
                ScrollView(showsIndicators: false) {

                    HStack {
                        Spacer()

                        Text("Choose your habits")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.white)

                        Spacer()
                    }
                    .padding(.top, 60)
                    .padding(.bottom, 8)
                    .opacity(animateContent ? 1.0 : 0)

                    // Device safety notice
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.orange)

                        Text("Safety: Never bring your iPhone into extreme temperatures (saunas, cold plunges)")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.9))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.orange.opacity(0.15))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal, 24)
                    .padding(.bottom, 12)
                    .opacity(animateContent ? 1.0 : 0)
                
                    CategoryPillsView(selectedCategory: $selectedCategory)
                        .padding(.bottom, 60)
                    
                    if selectedCategory == Category.category0 {
                        Text("CryoZest instantly updates with Apple Watch workout sessions.")
                            .font(.system(size: 16, weight: .bold, design: .default))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.leading)
                            .lineLimit(5)
                            .padding(.bottom, 30)
                            .padding(.horizontal)
                    }
                    
                    ForEach(TherapyType.therapies(forCategory: selectedCategory), id: \.self) { therapyType in
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
                            } else if selectedTypes.count < 6 {
                                selectedTypes.append(therapyType)
                            } else {
                                // user tried to select a 5th type
                                alertTitle = "Too Many Types"
                                alertMessage = "Please remove a type before adding another."
                                showAlert = true
                                isCustomTypeViewPresented = false
                            }
                        }) {
                            ModernTherapyCard(
                                therapyType: therapyType,
                                displayName: getDisplayName(therapyType: therapyType),
                                isSelected: selectedTypes.contains(therapyType)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                    }
                }
                
                Spacer()

                // Modern Continue button
                Button(action: {
                    if selectedTypes.count < 2 {
                        alertTitle = "Select More Types"
                        alertMessage = "Please select at least 2 habits to continue."
                        showAlert = true
                    } else {
                        saveSelectedTherapies(therapyTypes: selectedTypes, context: managedObjectContext)
                        appState.hasSelectedTherapyTypes = true
                        presentationMode.wrappedValue.dismiss()
                    }
                }) {
                    HStack(spacing: 12) {
                        Text("Continue")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(selectedTypes.count >= 2 ? Color(red: 0.05, green: 0.15, blue: 0.25) : .white.opacity(0.5))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        Group {
                            if selectedTypes.count >= 2 {
                                LinearGradient(
                                    gradient: Gradient(colors: [.white, Color.white.opacity(0.95)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            } else {
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.white.opacity(0.2), Color.white.opacity(0.15)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            }
                        }
                    )
                    .cornerRadius(16)
                    .shadow(color: selectedTypes.count >= 2 ? .white.opacity(0.3) : .clear, radius: 20, x: 0, y: 10)
                }
                .disabled(selectedTypes.count < 2)
                .padding(.horizontal, 32)
                .padding(.bottom, 50)
                .opacity(animateContent ? 1.0 : 0)
                .alert(isPresented: $showAlert) {
                    Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("OK")))
                }
                
            }
            .onAppear {
                selectedTypes = selectedTherapies.compactMap { TherapyType(rawValue: $0.therapyType!) }
                fetchCustomTherapyNames()
                withAnimation(.easeOut(duration: 0.8)) {
                    animateContent = true
                }
            }
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

// Modern therapy card component
struct ModernTherapyCard: View {
    let therapyType: TherapyType
    let displayName: String
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 16) {
            // Icon with gradient background
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                therapyType.color.opacity(0.8),
                                therapyType.color.opacity(0.6)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)

                Image(systemName: therapyType.icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white)
            }

            // Therapy type name
            Text(displayName)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(.white)

            Spacer()

            // Selection indicator
            Circle()
                .strokeBorder(isSelected ? Color.cyan : Color.white.opacity(0.3), lineWidth: 2)
                .background(
                    Circle()
                        .fill(isSelected ? Color.cyan : Color.clear)
                )
                .frame(width: 28, height: 28)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    isSelected
                        ? Color.white.opacity(0.12)
                        : Color.white.opacity(0.06)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(
                            isSelected
                                ? Color.cyan.opacity(0.5)
                                : Color.white.opacity(0.1),
                            lineWidth: isSelected ? 2 : 1
                        )
                )
        )
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .shadow(
            color: isSelected ? therapyType.color.opacity(0.3) : .clear,
            radius: 12,
            x: 0,
            y: 6
        )
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

struct CategoryPillsView: View {
    @Binding var selectedCategory: Category
    @State private var scrollViewWidth: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(Category.allCases, id: \.self) { category in
                            PillView(category: category, isSelected: Binding(get: {
                                self.selectedCategory == category
                            }, set: { _ in }))
                                .id(category.id)
                                .onTapGesture {
                                    self.selectedCategory = category
                                    withAnimation {
                                        proxy.scrollTo(category.id, anchor: .center)
                                    }
                                }
                        }
                    }
                    .padding()
                    .onAppear {
                        scrollViewWidth = geometry.size.width
                    }
                }
            }
        }
    }
}


struct PillView: View {
    let category: Category
    let isSelected: Binding<Bool>
    
    var body: some View {
        Text(category == Category.category0 ? "⭐️ \(category.rawValue)" : category.rawValue)
            .padding(.horizontal)
            .padding(.vertical, 5)
            .background(isSelected.wrappedValue ? Color.blue : Color.clear)
            .foregroundColor(isSelected.wrappedValue ? .white : Color.blue)
            .cornerRadius(9) // Updated corner radius
            .overlay(
                RoundedRectangle(cornerRadius: 9) // Updated corner radius for the border
                    .stroke(Color.blue, lineWidth: 1)
                    .opacity(isSelected.wrappedValue ? 0 : 1)
            )
    }
}
