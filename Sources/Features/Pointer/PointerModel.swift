import Observation

/// L'état de l'écran Pointer : la journée du jour, le bilan, et les gestes du
/// bouton.
@MainActor @Observable
final class PointerModel {
    private let repository: JoursRepository
    private let horloge: any Horloge
    private let preferences: AppPreferences

    private(set) var aujourdhui: JourStocke
    private(set) var minute: Int
    private(set) var bilan: Bilan
    /// Message d'un appui refusé ou d'une erreur de stockage, à afficher une fois.
    var message: String?

    init(repository: JoursRepository, horloge: any Horloge, preferences: AppPreferences) {
        self.repository = repository
        self.horloge = horloge
        self.preferences = preferences
        let (date, minute) = horloge.maintenant()
        self.minute = minute
        aujourdhui = JourStocke(date: date)
        bilan = Bilan(jours: [], aujourdhui: date, reglages: preferences.reglages)
        rafraichir()
    }

    var realiseDuJour: Int {
        aujourdhui.realise(a: minute, reglages: preferences.reglages)
    }

    var tolerance: Int { preferences.reglages.tolerance }

    /// Relit l'heure et la base : à l'ouverture, à chaque minute, au retour au
    /// premier plan. Passé minuit, la journée affichée change d'elle-même.
    func rafraichir() {
        let (date, minute) = horloge.maintenant()
        self.minute = minute
        do {
            let jours = try repository.tous()
            aujourdhui = jours.first { $0.date == date } ?? JourStocke(date: date)
            bilan = Bilan(jours: jours, aujourdhui: date, reglages: preferences.reglages)
        } catch {
            message = "Lecture impossible : \(error.localizedDescription)"
        }
    }

    func pointer() {
        rafraichir()
        var jour = aujourdhui
        do throws(JourStocke.RefusPointage) {
            try jour.pointer(a: minute)
        } catch {
            message = error.message
            return
        }
        enregistrer(jour)
    }

    func annulerDernierPointage() {
        rafraichir()
        var jour = aujourdhui
        jour.annulerDernierPointage()
        enregistrer(jour)
    }

    private func enregistrer(_ jour: JourStocke) {
        do {
            try repository.enregistrer(jour)
        } catch {
            message = "Enregistrement impossible : \(error.localizedDescription)"
        }
        rafraichir()
    }
}
