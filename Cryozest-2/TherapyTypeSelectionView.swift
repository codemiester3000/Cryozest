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

    @State private var customTherapyNames: [String] = ["Custom 1", "Custom 2", "Custom 3", "Custom 4"]

    @FetchRequest(
        entity: SelectedTherapy.entity(),
        sortDescriptors: []
    ) private var selectedTherapies: FetchedResults<SelectedTherapy>

    private let maxSelections = 6
    private let minSelections = 2

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    var body: some View {
        ZStack {
            // Our navy background
            Color(red: 0.06, green: 0.10, blue: 0.18)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack(alignment: .top) {
                    // Left - title
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Choose Habits")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)

                        Text("\(selectedTypes.count) of \(maxSelections) selected")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.5))
                    }

                    Spacer()

                    // Right - close
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white.opacity(0.6))
                            .frame(width: 32, height: 32)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)

                // Category tabs
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(Category.allCases, id: \.self) { category in
                            CategoryChip(
                                title: category.rawValue,
                                isSelected: selectedCategory == category,
                                hasWatch: category == .category0
                            ) {
                                withAnimation(.easeOut(duration: 0.15)) {
                                    selectedCategory = category
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }

                // Grid
                ScrollView(showsIndicators: false) {
                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(TherapyType.therapies(forCategory: selectedCategory), id: \.self) { therapyType in
                            let isWorkout = selectedCategory == .category0 || (selectedCategory == .category1 && Category.category0.therapies().contains(therapyType))

                            HabitSelectionCard(
                                therapyType: therapyType,
                                name: getDisplayName(therapyType: therapyType),
                                isSelected: selectedTypes.contains(therapyType),
                                syncs: isWorkout
                            ) {
                                handleTap(therapyType)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 140)
                }
            }

            // Bottom
            VStack {
                Spacer()
                bottomSection
            }
        }
        .onAppear {
            selectedTypes = selectedTherapies.compactMap { TherapyType(rawValue: $0.therapyType!) }
            fetchCustomTherapyNames()
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        .sheet(isPresented: $isCustomTypeViewPresented) {
            if let selectedCustomType = selectedCustomType {
                CustomHabitSheet(
                    therapyType: Binding.constant(selectedCustomType),
                    customTherapyNames: $customTherapyNames
                )
            }
        }
        .alert("Safety Notice", isPresented: $showExtremeTempAlert) {
            Button("Cancel", role: .cancel) { pendingExtremeTempTherapy = nil }
            Button("Continue") {
                if let therapy = pendingExtremeTempTherapy {
                    withAnimation { selectedTypes.append(therapy) }
                    pendingExtremeTempTherapy = nil
                }
            }
        } message: {
            Text("Ensure your device is safe during this activity.")
        }
    }

    // MARK: - Bottom Section
    private var bottomSection: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [
                    Color(red: 0.06, green: 0.10, blue: 0.18).opacity(0),
                    Color(red: 0.06, green: 0.10, blue: 0.18)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 60)

            VStack(spacing: 16) {
                Button(action: handleContinue) {
                    HStack(spacing: 8) {
                        Text(selectedTypes.count >= minSelections ? "Continue" : "Select at least \(minSelections)")
                            .font(.system(size: 16, weight: .semibold))

                        if selectedTypes.count >= minSelections {
                            Image(systemName: "arrow.right")
                                .font(.system(size: 13, weight: .semibold))
                        }
                    }
                    .foregroundColor(selectedTypes.count >= minSelections ? .black : .white.opacity(0.4))
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(selectedTypes.count >= minSelections ? Color.cyan : Color.white.opacity(0.1))
                    )
                }
                .disabled(selectedTypes.count < minSelections)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
            .background(Color(red: 0.06, green: 0.10, blue: 0.18))
        }
    }

    // MARK: - Actions
    private func handleTap(_ therapyType: TherapyType) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        if [.custom1, .custom2, .custom3, .custom4].contains(therapyType) && !selectedTypes.contains(therapyType) {
            selectedCustomType = therapyType
            isCustomTypeViewPresented = true
        }

        withAnimation(.easeOut(duration: 0.15)) {
            if selectedTypes.contains(therapyType) {
                selectedTypes.removeAll { $0 == therapyType }
            } else if selectedTypes.count < maxSelections {
                if isExtremeTempTherapy(therapyType) {
                    pendingExtremeTempTherapy = therapyType
                    showExtremeTempAlert = true
                } else {
                    selectedTypes.append(therapyType)
                }
            } else {
                alertTitle = "Limit Reached"
                alertMessage = "Remove a habit to add another."
                showAlert = true
                isCustomTypeViewPresented = false
            }
        }
    }

    private func handleContinue() {
        if selectedTypes.count >= minSelections {
            saveSelectedTherapies(therapyTypes: selectedTypes, context: managedObjectContext)
            appState.hasSelectedTherapyTypes = true
            presentationMode.wrappedValue.dismiss()
        }
    }

    // MARK: - Data
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
        switch therapyType {
        case .custom1: return customTherapyNames[0]
        case .custom2: return customTherapyNames[1]
        case .custom3: return customTherapyNames[2]
        case .custom4: return customTherapyNames[3]
        default: return therapyType.displayName(managedObjectContext)
        }
    }

    func isExtremeTempTherapy(_ therapy: TherapyType) -> Bool { false }

    func saveTherapyType(type: TherapyType, context: NSManagedObjectContext) {
        let selectedTherapy = SelectedTherapy(context: context)
        selectedTherapy.therapyType = type.rawValue
        try? context.save()
    }

    func deleteAllTherapies(context: NSManagedObjectContext) {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = SelectedTherapy.fetchRequest()
        if let results = try? context.fetch(fetchRequest) as? [NSManagedObject] {
            results.forEach { context.delete($0) }
            try? context.save()
        }
    }

    func saveSelectedTherapies(therapyTypes: [TherapyType], context: NSManagedObjectContext) {
        deleteAllTherapies(context: context)
        therapyTypes.forEach { saveTherapyType(type: $0, context: context) }
    }
}

// MARK: - Category Chip
struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let hasWatch: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if hasWatch {
                    Image(systemName: "applewatch")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.green)
                }
                Text(title)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(isSelected ? .white : .white.opacity(0.6))
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(
                Capsule()
                    .fill(isSelected ? Color.cyan.opacity(0.25) : Color.white.opacity(0.08))
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.cyan.opacity(0.5) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Habit Selection Card
struct HabitSelectionCard: View {
    let therapyType: TherapyType
    let name: String
    let isSelected: Bool
    let syncs: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 14) {
                // Icon
                ZStack {
                    Circle()
                        .fill(therapyType.color.opacity(0.2))
                        .frame(width: 56, height: 56)

                    Image(systemName: therapyType.icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(therapyType.color)
                }

                // Name
                Text(name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                // Sync indicator
                if syncs {
                    HStack(spacing: 4) {
                        Image(systemName: "applewatch")
                            .font(.system(size: 9))
                        Text("syncs")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(.green.opacity(0.8))
                } else {
                    Text(" ")
                        .font(.system(size: 11))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(isSelected ? 0.12 : 0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.cyan : Color.white.opacity(0.08), lineWidth: isSelected ? 2 : 1)
            )
            .overlay(
                // Checkmark
                VStack {
                    HStack {
                        Spacer()
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.cyan)
                                .padding(10)
                        }
                    }
                    Spacer()
                }
            )
        }
        .buttonStyle(HabitScaleButtonStyle())
    }
}

// MARK: - Habit Scale Button Style
struct HabitScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Custom Habit Sheet
struct CustomHabitSheet: View {
    @Binding var therapyType: TherapyType
    @Binding var customTherapyNames: [String]
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var managedObjectContext
    @State private var customName: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        ZStack {
            Color(red: 0.06, green: 0.10, blue: 0.18).ignoresSafeArea()

            VStack(spacing: 0) {
                // Handle
                Capsule()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 36, height: 4)
                    .padding(.top, 12)

                // Header
                HStack {
                    Button("Cancel") { dismiss() }
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.5))

                    Spacer()

                    Text("Custom Habit")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)

                    Spacer()

                    Button("Save") {
                        saveCustomTherapy()
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(customName.isEmpty ? .white.opacity(0.3) : .cyan)
                    .disabled(customName.isEmpty)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)

                // Icon
                ZStack {
                    Circle()
                        .fill(Color.purple.opacity(0.2))
                        .frame(width: 72, height: 72)

                    Image(systemName: "star.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.purple)
                }
                .padding(.top, 40)

                // Input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Name")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.5))

                    TextField("", text: $customName, prompt: Text("Enter habit name").foregroundColor(.white.opacity(0.3)))
                        .font(.system(size: 17))
                        .foregroundColor(.white)
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.08))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(isFocused ? Color.cyan.opacity(0.5) : Color.white.opacity(0.1), lineWidth: 1)
                                )
                        )
                        .focused($isFocused)
                        .autocapitalization(.words)
                }
                .padding(.horizontal, 24)
                .padding(.top, 32)

                Spacer()
            }
        }
        .onAppear {
            loadCustomTherapyName()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                isFocused = true
            }
        }
    }

    private func loadCustomTherapyName() {
        let therapyID = therapyTypeToID(therapyType)
        let fetchRequest: NSFetchRequest<CustomTherapy> = CustomTherapy.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %d", therapyID)

        if let result = try? managedObjectContext.fetch(fetchRequest).first {
            customName = result.name ?? ""
        }
    }

    private func saveCustomTherapy() {
        let therapyID = therapyTypeToID(therapyType)
        let fetchRequest: NSFetchRequest<CustomTherapy> = CustomTherapy.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %d", therapyID)

        let therapy: CustomTherapy
        if let existing = try? managedObjectContext.fetch(fetchRequest).first {
            therapy = existing
        } else {
            therapy = CustomTherapy(context: managedObjectContext)
            therapy.id = therapyID
        }

        customTherapyNames[Int(therapyID) - 1] = customName
        therapy.name = customName
        try? managedObjectContext.save()
    }

    private func therapyTypeToID(_ type: TherapyType) -> Int16 {
        switch type {
        case .custom1: return 1
        case .custom2: return 2
        case .custom3: return 3
        case .custom4: return 4
        default: return 0
        }
    }
}

// MARK: - Category Extension
extension Category {
    func therapies() -> [TherapyType] {
        return TherapyType.therapies(forCategory: self)
    }
}

// MARK: - Legacy Support
struct CategoryPillsView: View {
    @Binding var selectedCategory: Category

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(Category.allCases, id: \.self) { category in
                    CategoryChip(
                        title: category.rawValue,
                        isSelected: selectedCategory == category,
                        hasWatch: category == .category0
                    ) {
                        selectedCategory = category
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

struct PillView: View {
    let category: Category
    let isSelected: Binding<Bool>

    var body: some View {
        CategoryChip(
            title: category.rawValue,
            isSelected: isSelected.wrappedValue,
            hasWatch: category == .category0,
            action: {}
        )
    }
}
