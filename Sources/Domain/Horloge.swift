import Foundation

/// L'instant présent, en date civile et minute du jour (secondes tronquées).
/// Injectée, pour tester le bouton sans dépendre de l'heure réelle.
protocol Horloge: Sendable {
    func maintenant() -> (date: DateCivile, minute: Int)
}

/// L'heure de l'appareil, dans son fuseau courant : c'est l'heure affichée par
/// le téléphone qui fait foi.
struct HorlogeSysteme: Horloge {
    func maintenant() -> (date: DateCivile, minute: Int) {
        let c = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: Date())
        return (DateCivile(annee: c.year!, mois: c.month!, jour: c.day!)!, c.hour! * 60 + c.minute!)
    }
}
