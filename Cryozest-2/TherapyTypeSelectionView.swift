import SwiftUI
import CoreData

struct TherapyTypeSelectionView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) var managedObjectContext
    @State var selectedTypes: [TherapyType] = []
    
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
                            //.padding()

                        ScrollView {  // wrap ForEach with ScrollView
                            ForEach(TherapyType.allCases, id: \.self) { therapyType in
                                Button(action: {
                                    if selectedTypes.contains(therapyType) {
                                        selectedTypes.removeAll(where: { $0 == therapyType })
                                    } else if selectedTypes.count < 4 {
                                        selectedTypes.append(therapyType)
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
                                .padding(.horizontal)
                            }
                        }

                        Spacer()
                        Button("Done") {
                            // Save the selected types and dismiss the view.
                            saveSelectedTherapies(therapyTypes: selectedTypes, context: managedObjectContext)
                            presentationMode.wrappedValue.dismiss()
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .onAppear {
                        selectedTypes = selectedTherapies.compactMap { TherapyType(rawValue: $0.therapyType!) }
                    }
                    .padding()
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
