import Testing

@testable import Pointage

private let lundi = DateCivile(annee: 2026, mois: 9, jour: 28)!

struct HistoriqueTests {
    @Test func regroupeParSemaineLaPlusRecenteDAbord() {
        let historique = Historique(
            jours: [
                JourStocke(date: lundi, heures: [480, 720, 750, 1002]),
                JourStocke(date: lundi.ajoutant(jours: 7), heures: [480, 1002]),
            ],
            aujourdhui: lundi.ajoutant(jours: 8), reglages: .defaut
        )
        #expect(historique.semaines.map(\.numero) == [41, 40])
        #expect(historique.semaines[0].jours.map(\.date) == [lundi.ajoutant(jours: 7)])
        // la semaine 40 liste ses cinq jours ouvrés, du vendredi au lundi
        #expect(historique.semaines[1].jours.map(\.date) == (0..<5).reversed().map { lundi.ajoutant(jours: $0) })
    }

    @Test func statutsEtEcarts() {
        let mardi = lundi.ajoutant(jours: 1)
        let mercredi = lundi.ajoutant(jours: 2)
        let jeudi = lundi.ajoutant(jours: 3)
        let vendredi = lundi.ajoutant(jours: 4)
        let historique = Historique(
            jours: [
                JourStocke(date: lundi, heures: [480, 720, 750, 1002]),
                JourStocke(date: mardi, heures: [480]),
                JourStocke(date: jeudi, absence: .ferie),
                JourStocke(date: vendredi, heures: [480, 720, 750]),
            ],
            aujourdhui: vendredi, reglages: .defaut
        )
        let jours = Dictionary(uniqueKeysWithValues: historique.semaines[0].jours.map { ($0.date, $0) })

        #expect(jours[lundi]?.statut == .travail)
        #expect(jours[lundi]?.ecart == 0)
        #expect(jours[mardi]?.statut == .sansDepart)
        #expect(jours[mardi]?.ecart == -492)
        #expect(jours[mercredi]?.statut == .nonRenseigne)
        #expect(jours[mercredi]?.ecart == -492)
        #expect(jours[jeudi]?.statut == .absence(.ferie))
        #expect(jours[jeudi]?.ecart == 0)
        #expect(jours[vendredi]?.statut == .enCours)
        #expect(jours[vendredi]?.ecart == nil)
        #expect(historique.semaines[0].ecart == -984)
    }
}

struct EditionJourTests {
    @Test func reprendUneJourneeEtLaRevalide() {
        var edition = EditionJour(JourStocke(date: lundi, heures: [480, 1020]))
        #expect(edition.arrivee == 480)
        #expect(edition.depart == 1020)
        #expect(edition.resultat == JourStocke(date: lundi, heures: [480, 1020]))

        edition.debutPause = 720
        #expect(edition.resultat == nil)
        #expect(edition.messageErreur == "Renseignez le début et la fin de la pause, ou aucun des deux.")

        edition.finPause = 750
        #expect(edition.resultat == JourStocke(date: lundi, heures: [480, 720, 750, 1020]))
    }

    @Test func uneJourneeEnCoursNeSEnregistrePasSansDepart() {
        var edition = EditionJour(JourStocke(date: lundi, heures: [480, 720, 750]))
        #expect(edition.debutPause == 720)
        #expect(edition.resultat == nil)
        edition.depart = 1020
        #expect(edition.resultat == JourStocke(date: lundi, heures: [480, 720, 750, 1020]))
    }

    @Test func absence() {
        var edition = EditionJour(JourStocke(date: lundi, heures: [480, 1020]))
        edition.mode = .absence
        edition.absence = .maladie
        #expect(edition.resultat == JourStocke(date: lundi, absence: .maladie))
    }
}
