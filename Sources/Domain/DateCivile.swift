/// Une date du calendrier, sans heure ni fuseau.
///
/// Les calculs passent par un numéro de jour (jours écoulés depuis le
/// 1er janvier 1970) plutôt que par `Date` et `Calendar` : aucun fuseau ni
/// changement d'heure ne peut décaler un jour.
struct DateCivile: Hashable, Comparable, Sendable {
    let annee: Int
    let mois: Int
    let jour: Int

    init?(annee: Int, mois: Int, jour: Int) {
        guard (1...12).contains(mois), jour >= 1,
              jour <= Self.joursDansLeMois(mois, annee: annee)
        else { return nil }
        self.annee = annee
        self.mois = mois
        self.jour = jour
    }

    init(numeroDeJour: Int) {
        // Algorithme « civil_from_days » de Howard Hinnant.
        let z = numeroDeJour + 719_468
        let ere = (z >= 0 ? z : z - 146_096) / 146_097
        let jourDeLEre = z - ere * 146_097
        let anneeDeLEre = (jourDeLEre - jourDeLEre / 1460 + jourDeLEre / 36524 - jourDeLEre / 146_096) / 365
        let jourDeLAnnee = jourDeLEre - (365 * anneeDeLEre + anneeDeLEre / 4 - anneeDeLEre / 100)
        let moisDecale = (5 * jourDeLAnnee + 2) / 153
        jour = jourDeLAnnee - (153 * moisDecale + 2) / 5 + 1
        mois = moisDecale < 10 ? moisDecale + 3 : moisDecale - 9
        annee = anneeDeLEre + ere * 400 + (mois <= 2 ? 1 : 0)
    }

    /// Jours écoulés depuis le 1er janvier 1970.
    var numeroDeJour: Int {
        let a = mois <= 2 ? annee - 1 : annee
        let ere = (a >= 0 ? a : a - 399) / 400
        let anneeDeLEre = a - ere * 400
        let jourDeLAnnee = (153 * (mois > 2 ? mois - 3 : mois + 9) + 2) / 5 + jour - 1
        let jourDeLEre = anneeDeLEre * 365 + anneeDeLEre / 4 - anneeDeLEre / 100 + jourDeLAnnee
        return ere * 146_097 + jourDeLEre - 719_468
    }

    /// 1 pour lundi, 7 pour dimanche (ISO 8601).
    var jourDeLaSemaine: Int {
        // Le 1er janvier 1970 était un jeudi.
        ((numeroDeJour + 3) % 7 + 7) % 7 + 1
    }

    var estOuvre: Bool { jourDeLaSemaine <= 5 }

    func ajoutant(jours: Int) -> DateCivile {
        DateCivile(numeroDeJour: numeroDeJour + jours)
    }

    /// Année et numéro de semaine ISO 8601 : la semaine appartient à l'année de
    /// son jeudi.
    var semaineIso: (annee: Int, semaine: Int) {
        let jeudi = ajoutant(jours: 4 - jourDeLaSemaine)
        let premierJanvier = DateCivile(annee: jeudi.annee, mois: 1, jour: 1)!
        return (jeudi.annee, (jeudi.numeroDeJour - premierJanvier.numeroDeJour) / 7 + 1)
    }

    var lundiDeLaSemaine: DateCivile {
        ajoutant(jours: 1 - jourDeLaSemaine)
    }

    static func < (lhs: DateCivile, rhs: DateCivile) -> Bool {
        (lhs.annee, lhs.mois, lhs.jour) < (rhs.annee, rhs.mois, rhs.jour)
    }

    private static func joursDansLeMois(_ mois: Int, annee: Int) -> Int {
        switch mois {
        case 2:
            let bissextile = annee % 4 == 0 && (annee % 100 != 0 || annee % 400 == 0)
            return bissextile ? 29 : 28
        case 4, 6, 9, 11:
            return 30
        default:
            return 31
        }
    }
}
