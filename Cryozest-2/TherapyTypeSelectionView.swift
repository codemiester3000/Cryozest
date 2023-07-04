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
    
    @FetchRequest(
        entity: SelectedTherapy.entity(),
        sortDescriptors: []
    ) private var selectedTherapies: FetchedResults<SelectedTherapy>
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.gray, Color.gray.opacity(0.8)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)
            
            VStack {
                Text("Select up to 4 therapy types")
                    .font(.headline)
                    .foregroundColor(.white)
                    .scaleEffect(1.3)
                    .padding(.vertical, 12)
                
                ScrollView {
                    ForEach(TherapyType.allCases, id: \.self) { therapyType in
                        Button(action: {
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
                                    .foregroundColor(.white)
                                Text(therapyType.rawValue)
                                    .foregroundColor(.white)
                                Spacer()
                                if selectedTypes.contains(therapyType) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.white)
                                }
                            }
                            .padding()
                            .background(therapyType.color.opacity(0.8))
                            .cornerRadius(8)
                        }
                        //.padding(.horizontal)
                    }
                }
                
                Spacer()
                Button(action: {
                    // Check for fewer than 2 types
                    if selectedTypes.count < 2 {
                        alertTitle = "Too Few Types"
                        alertMessage = "Please select at least two types."
                        showAlert = true
                    } else {
                        // Save the selected types and dismiss the view.
                        saveSelectedTherapies(therapyTypes: selectedTypes, context: managedObjectContext)
                        appState.hasSelectedTherapyTypes = true
                        presentationMode.wrappedValue.dismiss()
                    }
                }) {
                    Text("Done")
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .padding(.horizontal, 80)
                        .padding(.vertical, 28)
                        .background(Color.blue)
                        .cornerRadius(40)
                        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 10)
                }
                .padding(.vertical, 12)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .onAppear {
                selectedTypes = selectedTherapies.compactMap { TherapyType(rawValue: $0.therapyType!) }
            }
            .padding(.horizontal, 12)
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("OK")))
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
