/// Les soldes tels que l'app les affiche, calculés sur les journées stockées.
///
/// Décisions d'`AVANCEMENT.md` : les soldes se lisent « au soir d'hier ».
/// Aujourd'hui n'y entre jamais, même complet : deux pointages à midi se liraient
/// sinon comme un départ, et le solde plongerait jusqu'à la reprise. Une journée
/// passée restée incomplète n'y entre pas non plus, et elle est signalée. La
/// période court jusqu'à hier : un jour ouvré passé sans journée complète compte
/// en déficit, même après le dernier jour renseigné.
struct Bilan: Equatable, Sendable {
    /// Nil tant qu'aucune journée complète n'existe.
    let rapport: Calculateur.Rapport?
    /// Journées passées sans départ, les plus anciennes d'abord.
    let journeesIncompletes: [DateCivile]
    /// Écart de la semaine ISO d'aujourd'hui, aujourd'hui exclu.
    let ecartSemaine: Int
    /// Solde cumulé depuis le début de l'historique.
    let soldeCumule: Int
    let horsTolerance: Bool

    init(jours: [JourStocke], aujourdhui: DateCivile, reglages: Reglages) {
        var completes: [Journee] = []
        var incompletes: [DateCivile] = []
        for jour in jours {
            switch jour.etat {
            case .vide:
                break
            case .enCours:
                if jour.date < aujourdhui { incompletes.append(jour.date) }
            case let .complete(journee):
                if jour.date < aujourdhui { completes.append(journee) }
            }
        }
        journeesIncompletes = incompletes.sorted()

        let rapport = Calculateur.calculer(completes, reglages: reglages, jusquA: aujourdhui.ajoutant(jours: -1))
        self.rapport = rapport
        let (annee, numero) = aujourdhui.semaineIso
        let semaine = rapport?.semaines.first { $0.anneeIso == annee && $0.semaineIso == numero }
        ecartSemaine = semaine?.ecart ?? 0
        let dernierMois = rapport?.mois.last
        soldeCumule = dernierMois?.soldeCumule ?? 0
        horsTolerance = dernierMois?.horsTolerance ?? false
    }
}
