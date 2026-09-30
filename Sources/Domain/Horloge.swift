import Foundation

/// L'instant présent, en date civile et minute du jour (secondes tronquées).
/// Injectée, pour tester le bouton sans dépendre de l'heure réelle.
protocol Horloge: Sendable {
    func maintenant() -> (date: DateCivile, minute: Int)
}

/// Un instant figé : celui des tests d'interface.
struct HorlogeFixe: Horloge {
    let date: DateCivile
    let minute: Int

    func maintenant() -> (date: DateCivile, minute: Int) { (date, minute) }
}

/// L'heure de l'appareil, dans son fuseau courant : c'est l'heure affichée par
/// le téléphone qui fait foi.
struct HorlogeSysteme: Horloge {
    func maintenant() -> (date: DateCivile, minute: Int) {
        let c = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: Date())
        return (DateCivile(annee: c.year!, mois: c.month!, jour: c.day!)!, c.hour! * 60 + c.minute!)
    }
}
