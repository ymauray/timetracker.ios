import Foundation
import Testing

@testable import Pointage

@MainActor
struct ReglagesModelTests {
    private struct HorlogeFixe: Horloge {
        let date: DateCivile
        func maintenant() -> (date: DateCivile, minute: Int) { (date, 600) }
    }

    private let lundi = DateCivile(annee: 2026, mois: 9, jour: 28)!

    private func contexte() throws -> (ReglagesModel, JoursRepository, AppPreferences) {
        let repository = JoursRepository(base: try Base.enMemoire())
        let preferences = AppPreferences(defaults: UserDefaults(suiteName: UUID().uuidString)!)
        let model = ReglagesModel(
            repository: repository, horloge: HorlogeFixe(date: lundi.ajoutant(jours: 2)), preferences: preferences
        )
        return (model, repository, preferences)
    }

    @Test func lesReglagesSEnregistrent() throws {
        let (model, _, preferences) = try contexte()
        model.reglages.seuilPause = 4 * 60
        #expect(preferences.reglages.seuilPause == 240)
    }

    @Test func exportQueLaCLIRelit() throws {
        let (model, repository, _) = try contexte()
        try repository.enregistrer(JourStocke(date: lundi, heures: [480, 720, 750, 1002]))
        try repository.enregistrer(JourStocke(date: lundi.ajoutant(jours: 1), absence: .ferie))
        try repository.enregistrer(JourStocke(date: lundi.ajoutant(jours: 2), heures: [480])) // aujourd'hui, en cours
        model.rafraichir()

        let export = try #require(model.export)
        #expect(export.contains("|28.9.2026|8h00|12h00|12h30|16h42||"))
        #expect(export.contains("|29.9.2026|||||Ferie|"))
        #expect(!export.contains("30.9.2026"))
        #expect(ReleveParser.analyser(export).erreurs.isEmpty)
    }

    @Test func uneJourneeSansDepartBloqueLExport() throws {
        let (model, repository, _) = try contexte()
        try repository.enregistrer(JourStocke(date: lundi, heures: [480]))
        model.rafraichir()
        #expect(model.journeesIncompletes == [lundi])
        #expect(model.export == nil)
    }

    @Test func unFichierInvalideNeModifieRien() throws {
        let (model, repository, _) = try contexte()
        try repository.enregistrer(JourStocke(date: lundi, absence: .maladie))
        model.lire("|Date|Arrivée|Début pause|Fin pause|Départ|Absence|\n|---|---|---|---|---|---|\n|31.9.2026|||||CP|\n")

        #expect(model.erreursImport == [ErreurReleve(
            ligne: 3, message: "Date invalide '31.9.2026' (format attendu jj.mm.aaaa, ex: 1.10.2026 ou 21.02.2027)."
        )])
        #expect(model.importEnAttente == nil)
        #expect(try repository.tous() == [JourStocke(date: lundi, absence: .maladie)])
    }

    @Test func lImportConfirmeRemplaceHistoriqueEtReglages() throws {
        let (model, repository, preferences) = try contexte()
        try repository.enregistrer(JourStocke(date: lundi, absence: .maladie))
        model.lire("""
            ---
            duree_journee: 7h00
            ---
            |Date|Arrivée|Début pause|Fin pause|Départ|Absence|
            |---|---|---|---|---|---|
            |1.10.2026|8h00|||15h30||
            """)
        #expect(try repository.tous().count == 1) // rien avant confirmation

        model.confirmerImport()
        #expect(try repository.tous() == [JourStocke(date: DateCivile(annee: 2026, mois: 10, jour: 1)!, heures: [480, 930])])
        #expect(preferences.reglages.dureeJournee == 420)
        #expect(model.reglages.dureeJournee == 420)
    }
}
