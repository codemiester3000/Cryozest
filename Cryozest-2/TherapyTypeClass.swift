//
//  TherapyTypeClass.swift
//  Cryozest-2
//
//  Created by Owen Khoury on 12/30/23.
//

import SwiftUI

class TherapyTypeClass: Identifiable, Codable {
    var id: UUID
    var name: String
    var icon: String
    var color: Color
    
    enum CodingKeys: CodingKey {
        case id, name, icon, color
    }
    
    init(id: UUID = UUID(), name: String, icon: String, color: Color) {
        self.id = id
        self.name = name
        self.icon = icon
        self.color = color
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        icon = try container.decode(String.self, forKey: .icon)
        
        // Decode Color
        let colorData = try container.decode(Data.self, forKey: .color)
        color = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(colorData) as? Color ?? Color.clear
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(icon, forKey: .icon)
        
        // Encode Color
        let colorData = try NSKeyedArchiver.archivedData(withRootObject: color, requiringSecureCoding: false)
        try container.encode(colorData, forKey: .color)
    }
    
    // Static method to create predefined therapy types
    static func predefinedTypes() -> [TherapyTypeClass] {
        return [
            TherapyTypeClass(name: "Sauna", icon: "flame.fill", color: Color.orange),
            TherapyTypeClass(name: "Hot Yoga", icon: "bolt.fill", color: Color.orange),
            TherapyTypeClass(name: "Running", icon: "figure.walk", color: Color.orange),
            TherapyTypeClass(name: "Lifting", icon: "dumbbell.fill", color: Color.orange),
            TherapyTypeClass(name: "Cold Plunge", icon: "snow", color: Color.blue),
            TherapyTypeClass(name: "Cold Shower", icon: "drop.fill", color: Color.blue),
            TherapyTypeClass(name: "Ice Bath", icon: "snowflake", color: Color.blue),
            TherapyTypeClass(name: "Yoga", icon: "leaf.arrow.circlepath", color: Color.blue),
            TherapyTypeClass(name: "Meditation", icon: "heart.fill", color: Color(red: 0.0, green: 0.5, blue: 0.0)),
            TherapyTypeClass(name: "Stretching", icon: "person.fill", color: Color(red: 0.0, green: 0.5, blue: 0.0)),
            TherapyTypeClass(name: "Deep Breathing", icon: "wind", color: Color(red: 0.0, green: 0.5, blue: 0.0)),
            TherapyTypeClass(name: "Sleep", icon: "moon.fill", color: Color(red: 0.0, green: 0.5, blue: 0.0))
        ]
    }
}

class TherapyTypeManager: ObservableObject {
    @Published var therapyTypes: [TherapyTypeClass] = []

    init() {
        loadPredefinedTypes()
        loadUserAddedTypes()
    }

    private func loadPredefinedTypes() {
        // Assuming TherapyTypeClass has a static method predefinedTypes
        therapyTypes.append(contentsOf: TherapyTypeClass.predefinedTypes())
    }

    private func loadUserAddedTypes() {
        // Load user-added types from persistent storage
        // For example, if you are using UserDefaults, CoreData, or any other storage mechanism
        // Here's a placeholder for where that logic would go
    }

    func addNewType(name: String, icon: String, color: Color) {
        let newType = TherapyTypeClass(name: name, icon: icon, color: color)
        therapyTypes.append(newType)
        // Optionally save this new type to persistent storage
        // Again, placeholder for persistence logic
    }

    // Additional utility methods as needed, like saving to persistent storage, removing a type, etc.
}
