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
