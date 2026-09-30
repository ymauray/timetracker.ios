import SwiftUI

@main
struct PointageApp: App {
    @State private var pointer = Result {
        PointerModel(repository: JoursRepository(base: try Base.ouvrir()), horloge: HorlogeSysteme(), preferences: .shared)
    }

    var body: some Scene {
        WindowGroup {
            switch pointer {
            case let .success(model):
                PointerView(model: model)
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
