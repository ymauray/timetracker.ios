import Foundation
import Testing

@testable import Pointage

/// Les fixtures naissent dans le dépôt de la CLI, qui les vérifie de son côté.
/// Passer les mêmes ici garantit que l'app et la CLI calculent pareil.
struct FixturesTests {
    private final class Marqueur {}

    private static let dossier = Bundle(for: Marqueur.self).resourceURL!.appending(path: "Fixtures")

    static let noms: [String] = {
        let contenu = try? FileManager.default.contentsOfDirectory(
            at: dossier, includingPropertiesForKeys: [.isDirectoryKey]
        )
        return (contenu ?? [])
            .filter { (try? $0.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true }
            .map(\.lastPathComponent)
            .sorted()
    }()

    /// Sans fixture dans le bundle, le test paramétré passerait sans rien vérifier.
    @Test func lesFixturesSontDansLeBundle() {
        #expect(Self.noms.count >= 5)
    }

    @Test(arguments: noms)
    func produitLeResultatAttendu(nom: String) throws {
        let releve = try String(contentsOf: Self.dossier.appending(path: "\(nom)/releve.md"), encoding: .utf8)
        let donnees = try Data(contentsOf: Self.dossier.appending(path: "\(nom)/attendu.json"))
        let attendu = try JSONDecoder().decode(Attendu.self, from: donnees)

        #expect(Attendu(ReleveParser.analyser(releve)) == attendu)
    }

    /// Ce que l'app exporte, la CLI doit le relire à l'identique.
    @Test(arguments: noms)
    func exportPuisRelectureDonneLesMemesJournees(nom: String) throws {
        let releve = try String(contentsOf: Self.dossier.appending(path: "\(nom)/releve.md"), encoding: .utf8)
        let lu = ReleveParser.analyser(releve)
        guard lu.erreurs.isEmpty else { return }

        let relu = ReleveParser.analyser(ReleveWriter.ecrire(lu.journees, reglages: lu.reglages))

        #expect(relu.erreurs.isEmpty)
        #expect(relu.reglages == lu.reglages)
        #expect(relu.journees == lu.journees.sorted { $0.date < $1.date })
    }
}

/// Le contenu d'`attendu.json`, décrit dans `Fixtures/LISEZMOI.md`.
private struct Attendu: Decodable, Equatable {
    struct Config: Decodable, Equatable {
        let dureeJournee: Int
        let pauseMinimum: Int
        let seuilPause: Int
        let tolerance: Int
    }

    struct Erreur: Decodable, Equatable {
        let ligne: Int
        let message: String
    }

    struct Jour: Decodable, Equatable {
        let date: String
        let pauseDecomptee: Int
        let theorique: Int
        let realise: Int
    }

    struct Semaine: Decodable, Equatable {
        let anneeIso: Int
        let semaineIso: Int
        let lundi: String
        let theorique: Int
        let realise: Int
        let ecartCumule: Int
    }

    struct Mois: Decodable, Equatable {
        let annee: Int
        let mois: Int
        let theorique: Int
        let realise: Int
        let soldeCumule: Int
        let horsTolerance: Bool
    }

    let config: Config
    let erreurs: [Erreur]
    let jours: [Jour]
    let joursNonRenseignes: [String]
    let semaines: [Semaine]
    let mois: [Mois]
}

extension Attendu {
    /// Même construction que `FixturesTests.cs` : sans calcul dès qu'il y a une
    /// erreur.
    init(_ resultat: ReleveParser.Resultat) {
        let r = resultat.reglages
        config = Config(dureeJournee: r.dureeJournee, pauseMinimum: r.pauseMinimum, seuilPause: r.seuilPause, tolerance: r.tolerance)
        erreurs = resultat.erreurs.map { Erreur(ligne: $0.ligne, message: $0.message) }

        guard erreurs.isEmpty, let rapport = Calculateur.calculer(resultat.journees, reglages: r) else {
            jours = []
            joursNonRenseignes = []
            semaines = []
            mois = []
            return
        }
        jours = rapport.jours.map {
            Jour(date: iso($0.date), pauseDecomptee: $0.pauseDecomptee, theorique: $0.theorique, realise: $0.realise)
        }
        joursNonRenseignes = rapport.joursNonRenseignes.map(iso)
        semaines = rapport.semaines.map {
            Semaine(anneeIso: $0.anneeIso, semaineIso: $0.semaineIso, lundi: iso($0.lundi),
                    theorique: $0.theorique, realise: $0.realise, ecartCumule: $0.ecartCumule)
        }
        mois = rapport.mois.map {
            Mois(annee: $0.annee, mois: $0.mois, theorique: $0.theorique, realise: $0.realise,
                 soldeCumule: $0.soldeCumule, horsTolerance: $0.horsTolerance)
        }
    }
}

private func iso(_ date: DateCivile) -> String {
    func deux(_ n: Int) -> String { n < 10 ? "0\(n)" : "\(n)" }
    return "\(date.annee)-\(deux(date.mois))-\(deux(date.jour))"
}
