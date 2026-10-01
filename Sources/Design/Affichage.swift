/// Les textes affichés à l'écran, sans passer par `Date` : l'app ne manipule
/// que des dates civiles et des minutes.
enum Affichage {
    private static let joursDeLaSemaine = ["lundi", "mardi", "mercredi", "jeudi", "vendredi", "samedi", "dimanche"]
    private static let nomsDesMois = [
        "janvier", "février", "mars", "avril", "mai", "juin",
        "juillet", "août", "septembre", "octobre", "novembre", "décembre",
    ]

    /// « Mercredi 30 septembre ».
    static func dateLongue(_ date: DateCivile) -> String {
        let jour = joursDeLaSemaine[date.jourDeLaSemaine - 1]
        return "\(jour.prefix(1).uppercased())\(jour.dropFirst()) \(date.jour) \(nomsDesMois[date.mois - 1])"
    }

    /// « 30 septembre ».
    static func dateCourte(_ date: DateCivile) -> String {
        "\(date.jour) \(nomsDesMois[date.mois - 1])"
    }

    /// « Lun 28 septembre », pour les lignes de l’historique.
    static func dateListe(_ date: DateCivile) -> String {
        let jour = joursDeLaSemaine[date.jourDeLaSemaine - 1].prefix(3)
        return "\(jour.prefix(1).uppercased())\(jour.dropFirst()) \(date.jour) \(nomsDesMois[date.mois - 1])"
    }

    private static let moisAbreges = [
        "janv.", "févr.", "mars", "avr.", "mai", "juin",
        "juil.", "août", "sept.", "oct.", "nov.", "déc.",
    ]

    /// « Mar 29 sept. », pour les titres courts.
    static func dateAbregee(_ date: DateCivile) -> String {
        let jour = joursDeLaSemaine[date.jourDeLaSemaine - 1].prefix(3)
        return "\(jour.prefix(1).uppercased())\(jour.dropFirst()) \(date.jour) \(moisAbreges[date.mois - 1])"
    }

    /// « 28 sept. – 4 oct. », pour les en-têtes de semaine.
    static func semaine(lundi: DateCivile) -> String {
        let dimanche = lundi.ajoutant(jours: 6)
        return "\(lundi.jour) \(moisAbreges[lundi.mois - 1]) – \(dimanche.jour) \(moisAbreges[dimanche.mois - 1])"
    }

    static func absence(_ absence: Absence) -> String {
        switch absence {
        case .conges: "Congés"
        case .maladie: "Maladie"
        case .ferie: "Férié"
        case .rtt: "RTT"
        case .divers: "Divers"
        case .demi: "Demi-journée"
        }
    }

    /// « 8h05 ».
    static func heure(_ minutes: Int) -> String {
        Formats.heureReleve(minutes)
    }

    /// « 7h42 ».
    static func duree(_ minutes: Int) -> String {
        Formats.duree(minutes)
    }

    /// « +1h05 », « −0h45 », « 0h00 ».
    static func ecart(_ minutes: Int) -> String {
        let valeur = Formats.duree(abs(minutes))
        return minutes > 0 ? "+\(valeur)" : minutes < 0 ? "−\(valeur)" : valeur
    }
}
