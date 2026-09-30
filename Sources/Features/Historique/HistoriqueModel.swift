import Observation

@MainActor @Observable
final class HistoriqueModel {
    private let repository: JoursRepository
    private let horloge: any Horloge
    private let preferences: AppPreferences

    private(set) var historique: Historique
    private(set) var aujourdhui: DateCivile
    var message: String?

    init(repository: JoursRepository, horloge: any Horloge, preferences: AppPreferences) {
        self.repository = repository
        self.horloge = horloge
        self.preferences = preferences
        let date = horloge.maintenant().date
        aujourdhui = date
        historique = Historique(jours: [], aujourdhui: date, reglages: preferences.reglages)
        rafraichir()
    }

    func rafraichir() {
        aujourdhui = horloge.maintenant().date
        do {
            historique = Historique(jours: try repository.tous(), aujourdhui: aujourdhui, reglages: preferences.reglages)
        } catch {
            message = "Lecture impossible : \(error.localizedDescription)"
        }
    }

    func jour(_ date: DateCivile) -> JourStocke {
        (try? repository.jour(date)) ?? JourStocke(date: date)
    }

    func enregistrer(_ jour: JourStocke) {
        faire { try repository.enregistrer(jour) }
    }

    func supprimer(_ date: DateCivile) {
        faire { try repository.supprimer(date) }
    }

    private func faire(_ action: () throws -> Void) {
        do {
            try action()
        } catch {
            message = "Enregistrement impossible : \(error.localizedDescription)"
        }
        rafraichir()
    }
}
