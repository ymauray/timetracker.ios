import SwiftUI

@main
struct PointageApp: App {
    @State private var ecrans = Result { try Ecrans() }

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

    init() throws {
        let repository = JoursRepository(base: try Base.ouvrir())
        let horloge = HorlogeSysteme()
        pointer = PointerModel(repository: repository, horloge: horloge, preferences: .shared)
        historique = HistoriqueModel(repository: repository, horloge: horloge, preferences: .shared)
    }
}
