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
    @State private var showExtremeTempAlert = false
    @State private var pendingExtremeTempTherapy: TherapyType?
    
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
                    .padding(.bottom, 20)
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
                    .padding(.bottom, 24)
                    .opacity(animateContent ? 1.0 : 0)

                    CategoryPillsView(selectedCategory: $selectedCategory)
                        .frame(height: 60)
                        .padding(.bottom, 20)

                    // Apple Watch sync info card
                    if selectedCategory == Category.category0 {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.green.opacity(0.3),
                                                Color.green.opacity(0.1)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 44, height: 44)

                                Image(systemName: "applewatch.watchface")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.green)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 6) {
                                    Text("Auto-Sync Enabled")
                                        .font(.system(size: 16, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)

                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(.green)
                                }

                                Text("Workouts recorded on your Apple Watch automatically sync to the app")
                                    .font(.system(size: 13, weight: .regular, design: .rounded))
                                    .foregroundColor(.white.opacity(0.7))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.green.opacity(0.12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                                )
                        )
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
                    } else if selectedCategory != .category1 {
                        // Manual entry info for other categories
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.cyan.opacity(0.15))
                                    .frame(width: 44, height: 44)

                                Image(systemName: "hand.tap.fill")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.cyan)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Manual Tracking")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)

                                Text("Use the in-app timer to track these habits")
                                    .font(.system(size: 13, weight: .regular, design: .rounded))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.white.opacity(0.06))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color.cyan.opacity(0.2), lineWidth: 1)
                                )
                        )
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
                    }

                    ForEach(TherapyType.therapies(forCategory: selectedCategory), id: \.self) { therapyType in
                        let isWorkout = selectedCategory == .category0 || (selectedCategory == .category1 && Category.category0.therapies().contains(therapyType))
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
                                // Check if this is an extreme temp therapy
                                if isExtremeTempTherapy(therapyType) {
                                    pendingExtremeTempTherapy = therapyType
                                    showExtremeTempAlert = true
                                } else {
                                    selectedTypes.append(therapyType)
                                }
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
                                isSelected: selectedTypes.contains(therapyType),
                                isWorkout: isWorkout
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.horizontal, 24)
                        .padding(.vertical, 8)
                    }

                    // Bottom padding to ensure last card isn't cut off
                    Spacer()
                        .frame(height: 100)
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
        .alert("Device Safety Warning", isPresented: $showExtremeTempAlert) {
            Button("Cancel", role: .cancel) {
                pendingExtremeTempTherapy = nil
            }
            Button("I Understand") {
                if let therapy = pendingExtremeTempTherapy {
                    selectedTypes.append(therapy)
                    pendingExtremeTempTherapy = nil
                }
            }
        } message: {
            Text("Never bring your iPhone or Apple Watch into extreme temperatures. Apple devices operate safely between 32°F - 95°F (0°C - 35°C). Start your timer BEFORE entering, then leave your device outside.")
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

    func isExtremeTempTherapy(_ therapy: TherapyType) -> Bool {
        return [.drySauna, .hotYoga, .coldPlunge, .coldShower, .iceBath].contains(therapy)
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

// Helper extension for Category
extension Category {
    func therapies() -> [TherapyType] {
        return TherapyType.therapies(forCategory: self)
    }
}

// Modern therapy card component
struct ModernTherapyCard: View {
    let therapyType: TherapyType
    let displayName: String
    let isSelected: Bool
    let isWorkout: Bool

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

            // Therapy type name and badge
            VStack(alignment: .leading, spacing: 4) {
                Text(displayName)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)

                // Apple Watch badge for workout types
                if isWorkout {
                    HStack(spacing: 4) {
                        Image(systemName: "applewatch")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.green)

                        Text("Auto-Sync")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(.green)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(Color.green.opacity(0.15))
                    )
                }
            }

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

            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white.opacity(0.8))
                    }

                    Spacer()

                    Text("Custom Habit")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)

                    Spacer()

                    // Invisible placeholder for symmetry
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 28))
                        .opacity(0)
                }
                .padding(.horizontal, 24)
                .padding(.top, 60)
                .padding(.bottom, 20)

                Text("Create a custom habit to track your unique wellness routine")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 40)

                Spacer()

                // Input Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Habit Name")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))

                    TextField("", text: $customName, prompt: Text("e.g., Breathwork, Yoga, Stretching").foregroundColor(.white.opacity(0.4)))
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.white.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
                                )
                        )
                        .autocapitalization(.words)
                }
                .padding(.horizontal, 24)

                Spacer()

                // Save Button
                Button(action: {
                    saveCustomTherapy()
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Save Habit")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(customName.isEmpty ? .white.opacity(0.5) : .white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            Group {
                                if !customName.isEmpty {
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.cyan,
                                            Color.cyan.opacity(0.8)
                                        ]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                } else {
                                    Color.white.opacity(0.15)
                                }
                            }
                        )
                        .cornerRadius(14)
                        .shadow(color: customName.isEmpty ? .clear : Color.cyan.opacity(0.4), radius: 12, x: 0, y: 6)
                }
                .disabled(customName.isEmpty)
                .padding(.horizontal, 24)
                .padding(.bottom, 50)
            }
        }
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
        HStack(spacing: 6) {
            if category == .category0 {
                Image(systemName: "applewatch")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(isSelected.wrappedValue ? .white : .green)
            }
            Text(category.rawValue)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(isSelected.wrappedValue ? Color.blue : Color.clear)
        )
        .foregroundColor(isSelected.wrappedValue ? .white : Color.blue)
        .overlay(
            Capsule()
                .stroke(
                    isSelected.wrappedValue ? Color.clear : (category == .category0 ? Color.green.opacity(0.5) : Color.blue),
                    lineWidth: 1.5
                )
        )
    }
}
