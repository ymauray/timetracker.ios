import GRDB
import SwiftUI

@main
struct PointageApp: App {
    @State private var ecrans = Result {
        try ProcessInfo.processInfo.arguments.contains("-tests-interface") ? Ecrans.pourTestsInterface() : Ecrans()
    }

    var body: some Scene {
        WindowGroup {
            switch ecrans {
            case let .success(ecrans):
                TabView {
                    Tab("Pointer", systemImage: "hand.tap") {
                        PointerView(model: ecrans.pointer)
                    }
                    Tab("Historique", systemImage: "calendar") {
                        HistoriqueView(model: ecrans.historique)
                    }
                    Tab("Réglages", systemImage: "gearshape") {
                        ReglagesView(model: ecrans.reglages)
                    }
                }
            case let .failure(erreur):
                ContentUnavailableView(
                    "Base de données inaccessible",
                    systemImage: "externaldrive.badge.exclamationmark",
                    description: Text(erreur.localizedDescription)
                )
            }
        }
    }
}

/// Les modèles des écrans, branchés sur la même base.
@MainActor
private struct Ecrans {
    let pointer: PointerModel
    let historique: HistoriqueModel
    let reglages: ReglagesModel

    init() throws {
        try self.init(base: Base.ouvrir(), horloge: HorlogeSysteme(), preferences: .shared)
    }

    /// Lancée avec `-tests-interface` : base vide en mémoire, réglages par défaut
    /// hors des préférences réelles, et le lundi 5 octobre 2026 à 8h00 pour
    /// toujours.
    static func pourTestsInterface() throws -> Ecrans {
        let defaults = UserDefaults(suiteName: "tests-interface")!
        defaults.removePersistentDomain(forName: "tests-interface")
        return try Ecrans(
            base: Base.enMemoire(),
            horloge: HorlogeFixe(date: DateCivile(annee: 2026, mois: 10, jour: 5)!, minute: 8 * 60),
            preferences: AppPreferences(defaults: defaults)
        )
    }

    private init(base: DatabaseQueue, horloge: any Horloge, preferences: AppPreferences) {
        let repository = JoursRepository(base: base)
        pointer = PointerModel(repository: repository, horloge: horloge, preferences: preferences)
        historique = HistoriqueModel(repository: repository, horloge: horloge, preferences: preferences)
        reglages = ReglagesModel(repository: repository, horloge: horloge, preferences: preferences)
    }
}
