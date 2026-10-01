import Foundation
import Testing

@testable import Pointage

private let lundi = DateCivile(annee: 2026, mois: 10, jour: 5)!

struct JourStockeTests {
    @Test func lectureSelonLeNombreDHeures() {
        #expect(JourStocke(date: lundi).etat == .vide)
        #expect(JourStocke(date: lundi, heures: [480]).etat == .enCours)
        #expect(JourStocke(date: lundi, heures: [480, 720, 750]).etat == .enCours)
        #expect(JourStocke(date: lundi, heures: [480, 1020]).etat
            == .complete(Journee(date: lundi, contenu: .travail(arrivee: 480, pause: nil, depart: 1020))))
        #expect(JourStocke(date: lundi, heures: [480, 720, 750, 1020]).etat
            == .complete(Journee(date: lundi, contenu: .travail(arrivee: 480, pause: 720...750, depart: 1020))))
        #expect(JourStocke(date: lundi, absence: .ferie).etat
            == .complete(Journee(date: lundi, contenu: .absence(.ferie))))
    }

    /// Le deuxième pointage est un départ tant qu'un troisième n'en fait pas un
    /// début de pause.
    @Test func leDeuxiemePointageChangeDeNom() {
        #expect(JourStocke(date: lundi, heures: [480, 720]).nomsDesHeures == ["Arrivée", "Départ"])
        #expect(JourStocke(date: lundi, heures: [480, 720, 750]).nomsDesHeures == ["Arrivée", "Début pause", "Fin pause"])
    }

    @Test func leBoutonAnnonceLActionSuivante() throws {
        var jour = JourStocke(date: lundi)
        var libelles = [jour.actionSuivante]
        for minute in [480, 720, 750, 1020] {
            try jour.pointer(a: minute)
            libelles.append(jour.actionSuivante)
        }
        #expect(libelles == ["Arrivée", "Pause ou départ", "Fin de pause", "Départ", nil])
    }

    @Test func unCinquiemeAppuiEstRefuse() throws {
        var jour = JourStocke(date: lundi, heures: [480, 720, 750, 1020])
        #expect(throws: JourStocke.RefusPointage.journeeComplete) { try jour.pointer(a: 1030) }
        #expect(jour.heures.count == 4)
    }

    @Test func unAppuiDansLaMemeMinuteEstRefuse() throws {
        var jour = JourStocke(date: lundi, heures: [480])
        #expect(throws: JourStocke.RefusPointage.memeMinute) { try jour.pointer(a: 480) }
        #expect(throws: JourStocke.RefusPointage.memeMinute) { try jour.pointer(a: 470) }
        try jour.pointer(a: 481)
        #expect(jour.heures == [480, 481])
    }

    @Test func unJourDAbsenceRefuseLePointage() {
        var jour = JourStocke(date: lundi, absence: .conges)
        #expect(throws: JourStocke.RefusPointage.absence) { try jour.pointer(a: 480) }
        #expect(jour.actionSuivante == nil)
    }

    @Test func demiEtMaladieAcceptentLePointage() throws {
        var demi = JourStocke(date: lundi, absence: .demi)
        #expect(demi.etat == .enCours)
        #expect(demi.actionSuivante == "Arrivée")
        try demi.pointer(a: 480)
        try demi.pointer(a: 720)
        #expect(demi.etat == .complete(Journee(date: lundi, contenu: .travail(arrivee: 480, pause: nil, depart: 720, absence: .demi))))

        var maladie = JourStocke(date: lundi, absence: .maladie)
        #expect(maladie.etat == .complete(Journee(date: lundi, contenu: .absence(.maladie))))
        try maladie.pointer(a: 470)
        #expect(maladie.etat == .enCours)
    }

    @Test func realiseEnCoursDUneDemiJournee() {
        // 4h06 de demi-journée dès le matin, puis le travail s'y ajoute.
        #expect(JourStocke(date: lundi, absence: .demi).realise(a: 600, reglages: .defaut) == 246)
        #expect(JourStocke(date: lundi, heures: [480], absence: .demi).realise(a: 600, reglages: .defaut) == 366)
        #expect(JourStocke(date: lundi, heures: [480, 720], absence: .demi).realise(a: 800, reglages: .defaut) == 486)
    }

    @Test func annulerRetireLeDernierPointage() {
        var jour = JourStocke(date: lundi, heures: [480, 720, 750])
        jour.annulerDernierPointage()
        #expect(jour.heures == [480, 720])
        var vide = JourStocke(date: lundi)
        vide.annulerDernierPointage()
        #expect(vide.heures.isEmpty)
    }

    @Test func realiseEnCours() {
        let reglages = Reglages.defaut
        #expect(JourStocke(date: lundi, heures: [480]).realise(a: 600, reglages: reglages) == 120)
        // matin 8h–12h, retour à 12h30, il est 14h : 4h + 1h30
        #expect(JourStocke(date: lundi, heures: [480, 720, 750]).realise(a: 840, reglages: reglages) == 330)
        // journée complète : le calcul, pause minimum comprise
        #expect(JourStocke(date: lundi, heures: [480, 1020]).realise(a: 1100, reglages: reglages) == 510)
    }
}

struct BilanTests {
    private let mardi = lundi.ajoutant(jours: 1)
    private let mercredi = lundi.ajoutant(jours: 2)

    /// Hier sans départ, et aujourd'hui en cours : hier compte en déficit même
    /// s'il vient après le dernier jour complet.
    @Test func laVeilleIncompleteCompteEnDeficit() {
        let bilan = Bilan(
            jours: [
                JourStocke(date: lundi, heures: [480, 720, 750, 1002]),
                JourStocke(date: mardi, heures: [480]),
                JourStocke(date: mercredi, heures: [480]),
            ],
            aujourdhui: mercredi, reglages: .defaut
        )
        #expect(bilan.journeesIncompletes == [mardi])
        #expect(bilan.ecartSemaine == -492)
    }

    /// Deux pointages à midi se liraient comme un départ : aujourd'hui n'entre
    /// jamais dans les soldes, même complet.
    @Test func aujourdhuiNeComptePasMemeComplet() {
        let bilan = Bilan(
            jours: [
                JourStocke(date: lundi, heures: [480, 720, 750, 1002]),
                JourStocke(date: mardi, heures: [480, 720]),
            ],
            aujourdhui: mardi, reglages: .defaut
        )
        #expect(bilan.ecartSemaine == 0)
        #expect(bilan.soldeCumule == 0)
    }

    @Test func laJourneeEnCoursNeComptePas() {
        let bilan = Bilan(
            jours: [
                JourStocke(date: lundi, heures: [480, 720, 750, 1002]), // 8h12 pile
                JourStocke(date: mardi, heures: [480]),
            ],
            aujourdhui: mardi, reglages: .defaut
        )
        #expect(bilan.ecartSemaine == 0)
        #expect(bilan.soldeCumule == 0)
        #expect(bilan.journeesIncompletes.isEmpty)
    }

    @Test func uneJourneePasseeIncompleteEstSignaleeEtCompteEnDeficit() {
        let bilan = Bilan(
            jours: [
                JourStocke(date: lundi, heures: [480, 720, 750, 1002]),
                JourStocke(date: mardi, heures: [480]),
                JourStocke(date: mercredi, heures: [480, 720, 750, 1002]),
            ],
            aujourdhui: mercredi, reglages: .defaut
        )
        #expect(bilan.journeesIncompletes == [mardi])
        #expect(bilan.ecartSemaine == -492)
    }

    @Test func horsTolerance() {
        let bilan = Bilan(
            jours: [JourStocke(date: lundi, heures: [480, 540])],
            aujourdhui: mardi, reglages: Reglages(dureeJournee: 492, pauseMinimum: 30, seuilPause: 300, tolerance: 60)
        )
        #expect(bilan.soldeCumule == 60 - 492)
        #expect(bilan.horsTolerance)
    }
}

struct JoursRepositoryTests {
    @Test func enregistreRelitEtSupprime() throws {
        let repository = JoursRepository(base: try Base.enMemoire())
        try repository.enregistrer(JourStocke(date: lundi, heures: [480, 720, 750]))
        try repository.enregistrer(JourStocke(date: lundi.ajoutant(jours: 1), absence: .maladie))

        #expect(try repository.tous() == [
            JourStocke(date: lundi, heures: [480, 720, 750]),
            JourStocke(date: lundi.ajoutant(jours: 1), absence: .maladie),
        ])

        try repository.enregistrer(JourStocke(date: lundi))
        #expect(try repository.tous().map(\.date) == [lundi.ajoutant(jours: 1)])
        #expect(try repository.jour(lundi) == JourStocke(date: lundi))
    }
}

@MainActor
struct PointerModelTests {
    private final class HorlogeReglable: Horloge, @unchecked Sendable {
        var instant: (date: DateCivile, minute: Int)
        init(_ date: DateCivile, _ minute: Int) { instant = (date, minute) }
        func maintenant() -> (date: DateCivile, minute: Int) { instant }
    }

    private func model(_ horloge: HorlogeReglable) throws -> PointerModel {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        return PointerModel(
            repository: JoursRepository(base: try Base.enMemoire()),
            horloge: horloge,
            preferences: AppPreferences(defaults: defaults)
        )
    }

    @Test func uneJourneeAuBouton() throws {
        let horloge = HorlogeReglable(lundi, 480)
        let model = try model(horloge)

        for minute in [480, 720, 750, 1002] {
            horloge.instant.minute = minute
            model.pointer()
        }
        #expect(model.aujourdhui.heures == [480, 720, 750, 1002])
        #expect(model.message == nil)

        model.pointer()
        #expect(model.message == JourStocke.RefusPointage.journeeComplete.message)

        model.annulerDernierPointage()
        #expect(model.aujourdhui.heures == [480, 720, 750])
    }

    @Test func leDoubleAppuiEstRefuse() throws {
        let model = try model(HorlogeReglable(lundi, 480))
        model.pointer()
        model.pointer()
        #expect(model.aujourdhui.heures == [480])
        #expect(model.message == JourStocke.RefusPointage.memeMinute.message)
    }

    @Test func minuitChangeDeJournee() throws {
        let horloge = HorlogeReglable(lundi, 1400)
        let model = try model(horloge)
        model.pointer()

        horloge.instant = (lundi.ajoutant(jours: 1), 5)
        model.rafraichir()
        #expect(model.aujourdhui.date == lundi.ajoutant(jours: 1))
        #expect(model.aujourdhui.heures.isEmpty)
        #expect(model.bilan.journeesIncompletes == [lundi])
    }
}
