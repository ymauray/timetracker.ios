import Testing

@testable import Pointage

struct DateCivileTests {
    private func date(_ annee: Int, _ mois: Int, _ jour: Int) -> DateCivile {
        DateCivile(annee: annee, mois: mois, jour: jour)!
    }

    @Test func refuseLesDatesQuiNExistentPas() {
        #expect(DateCivile(annee: 2026, mois: 9, jour: 31) == nil)
        #expect(DateCivile(annee: 2026, mois: 2, jour: 29) == nil)
        #expect(DateCivile(annee: 2028, mois: 2, jour: 29) != nil)
        #expect(DateCivile(annee: 2100, mois: 2, jour: 29) == nil)
        #expect(DateCivile(annee: 2000, mois: 2, jour: 29) != nil)
    }

    @Test func numeroDeJourAllerRetour() {
        for numero in stride(from: -800_000, through: 800_000, by: 997) {
            #expect(DateCivile(numeroDeJour: numero).numeroDeJour == numero)
        }
        #expect(date(1970, 1, 1).numeroDeJour == 0)
        #expect(date(2026, 9, 28).numeroDeJour == 20_724)
    }

    @Test func jourDeLaSemaine() {
        #expect(date(2026, 9, 28).jourDeLaSemaine == 1) // lundi
        #expect(date(2026, 10, 3).jourDeLaSemaine == 6) // samedi
        #expect(date(2026, 10, 4).jourDeLaSemaine == 7) // dimanche
        #expect(!date(2026, 10, 4).estOuvre)
    }

    /// Les semaines à cheval sur deux années sont le piège classique de l'ISO 8601.
    @Test(arguments: [
        ((2026, 12, 31), 2026, 53),
        ((2027, 1, 3), 2026, 53),
        ((2027, 1, 4), 2027, 1),
        ((2024, 12, 30), 2025, 1),
        ((2021, 1, 3), 2020, 53),
        ((2026, 9, 28), 2026, 40),
    ])
    func semaineIso(jour: (Int, Int, Int), annee: Int, semaine: Int) {
        let iso = date(jour.0, jour.1, jour.2).semaineIso
        #expect(iso.annee == annee)
        #expect(iso.semaine == semaine)
    }

    @Test func lundiDeLaSemaine() {
        #expect(date(2026, 10, 4).lundiDeLaSemaine == date(2026, 9, 28))
        #expect(date(2027, 1, 1).lundiDeLaSemaine == date(2026, 12, 28))
    }
}
