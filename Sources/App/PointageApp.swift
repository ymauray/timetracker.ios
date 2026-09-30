import SwiftUI

@main
struct PointageApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

/// Écran provisoire, le temps de valider la chaîne de livraison. Remplacé par
/// l'écran Pointer à l'étape 4.
struct ContentView: View {
    var body: some View {
        ContentUnavailableView("Pointage", systemImage: "clock.badge.checkmark")
    }
}
