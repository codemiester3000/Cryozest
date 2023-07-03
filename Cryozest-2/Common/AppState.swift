import Combine
import SwiftUI

class AppState: ObservableObject {
    @Published var hasLaunchedBefore: Bool {
        didSet {
            UserDefaults.standard.set(hasLaunchedBefore, forKey: "hasLaunchedBefore")
        }
    }

    @Published var hasSelectedTherapyTypes: Bool {
        didSet {
            UserDefaults.standard.set(hasSelectedTherapyTypes, forKey: "hasSelectedTherapyTypes")
        }
    }

    init() {
        self.hasLaunchedBefore = UserDefaults.standard.bool(forKey: "hasLaunchedBefore")
        self.hasSelectedTherapyTypes = UserDefaults.standard.bool(forKey: "hasSelectedTherapyTypes")
    }
}
