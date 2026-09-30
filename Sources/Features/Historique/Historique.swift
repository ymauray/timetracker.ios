/// Le contenu de l'écran Historique : les jours regroupés par semaine ISO, la
/// plus récente d'abord.
struct Historique: Equatable, Sendable {
    struct Semaine: Equatable, Sendable, Identifiable {
        let anneeIso: Int
        let numero: Int
        let lundi: DateCivile
        /// Nil quand la semaine n'a encore rien de compté (journée en cours seule).
        let ecart: Int?
        /// Du plus récent au plus ancien.
        let jours: [Jour]

        var id: Int { anneeIso * 100 + numero }
    }

    struct Jour: Equatable, Sendable, Identifiable {
        enum Statut: Equatable, Sendable {
            case travail
            case absence(Absence)
            /// Aujourd'hui, une ou trois heures.
            case enCours
            /// Un jour passé, une ou trois heures : il manque le départ.
            case sansDepart
            /// Un jour ouvré passé sans rien.
            case nonRenseigne
        }

        let stocke: JourStocke
        let statut: Statut
        /// Nil pour la journée en cours, qui ne compte pas encore. Une journée sans
        /// départ compte en déficit, comme un jour non renseigné.
        let ecart: Int?

        var id: DateCivile { stocke.date }
        var date: DateCivile { stocke.date }
    }

    let semaines: [Semaine]

    init(jours stockes: [JourStocke], aujourdhui: DateCivile, reglages: Reglages) {
        let bilan = Bilan(jours: stockes, aujourdhui: aujourdhui, reglages: reglages)
        let calcules = Dictionary((bilan.rapport?.jours ?? []).map { ($0.date, $0) }, uniquingKeysWith: { a, _ in a })
        let stockesParDate = Dictionary(stockes.map { ($0.date, $0) }, uniquingKeysWith: { a, _ in a })
        let semainesCalculees = Dictionary(
            (bilan.rapport?.semaines ?? []).map { ($0.anneeIso * 100 + $0.semaineIso, $0) },
            uniquingKeysWith: { a, _ in a }
        )

        let dates = Set(calcules.keys).union(stockesParDate.keys.filter { stockesParDate[$0]!.etat != .vide })
        let jours = dates.sorted(by: >).map { date -> Jour in
            let stocke = stockesParDate[date] ?? JourStocke(date: date)
            let calcule = calcules[date]
            let statut: Jour.Statut = switch stocke.etat {
            case .vide: .nonRenseigne
            case .enCours: date < aujourdhui ? .sansDepart : .enCours
            case let .complete(journee):
                if case let .absence(absence) = journee.contenu { .absence(absence) } else { .travail }
            }
            return Jour(stocke: stocke, statut: statut, ecart: calcule?.ecart)
        }

        let groupes = Dictionary(grouping: jours) { $0.date.semaineIso.annee * 100 + $0.date.semaineIso.semaine }
        semaines = groupes.keys.sorted(by: >).map { cle in
            let joursDeLaSemaine = groupes[cle]!
            return Semaine(
                anneeIso: cle / 100, numero: cle % 100, lundi: joursDeLaSemaine[0].date.lundiDeLaSemaine,
                ecart: semainesCalculees[cle]?.ecart, jours: joursDeLaSemaine
            )
        }
    }
}
