import Foundation

/// Les réglages du calcul, dans les `UserDefaults`. L'écran Réglages arrive à
/// l'étape 6 ; d'ici là, les valeurs par défaut s'appliquent.
final class AppPreferences: @unchecked Sendable {
    static let shared = AppPreferences()

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var reglages: Reglages {
        get {
            Reglages(
                dureeJournee: minutes("dureeJournee", defaut: Reglages.defaut.dureeJournee),
                pauseMinimum: minutes("pauseMinimum", defaut: Reglages.defaut.pauseMinimum),
                seuilPause: minutes("seuilPause", defaut: Reglages.defaut.seuilPause),
                tolerance: minutes("tolerance", defaut: Reglages.defaut.tolerance)
            )
        }
        set {
            defaults.set(newValue.dureeJournee, forKey: "dureeJournee")
            defaults.set(newValue.pauseMinimum, forKey: "pauseMinimum")
            defaults.set(newValue.seuilPause, forKey: "seuilPause")
            defaults.set(newValue.tolerance, forKey: "tolerance")
        }
    }

    private func minutes(_ cle: String, defaut: Int) -> Int {
        defaults.object(forKey: cle) as? Int ?? defaut
    }
}
