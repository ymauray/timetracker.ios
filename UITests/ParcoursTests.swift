import XCTest

/// Les gestes que les tests unitaires ne couvrent pas : de vrais appuis sur
/// l'app, lancée sur une base vide un lundi 5 octobre 2026 à 8h00, horloge
/// arrêtée.
@MainActor
final class ParcoursTests: XCTestCase {
    private func lancer() -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-tests-interface"]
        app.launch()
        return app
    }

    func testPointerRefuserPuisAnnuler() {
        let app = lancer()
        let bouton = app.buttons["bouton-pointer"]
        XCTAssertEqual(bouton.label, "Pointer : Arrivée")

        bouton.tap()
        XCTAssertEqual(bouton.label, "Pointer : Pause ou départ")
        // La ligne « Arrivée » et son heure forment un seul élément d'accessibilité.
        XCTAssertTrue(app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS '8h00'")).firstMatch.exists)

        // L'horloge est arrêtée : un second appui tombe dans la même minute.
        bouton.tap()
        let refus = app.alerts["Un pointage existe déjà à cette minute ou plus tard."]
        XCTAssertTrue(refus.waitForExistence(timeout: 2))
        refus.buttons.firstMatch.tap()
        XCTAssertEqual(bouton.label, "Pointer : Pause ou départ")

        app.buttons["Annuler le dernier pointage"].tap()
        XCTAssertEqual(bouton.label, "Pointer : Arrivée")
    }

    func testCompleterLaJourneeDepuisLHistorique() {
        let app = lancer()
        app.buttons["bouton-pointer"].tap()

        app.tabBars.buttons["Historique"].tap()
        let ligne = app.buttons.containing(NSPredicate(format: "label CONTAINS 'En cours'")).firstMatch
        XCTAssertTrue(ligne.waitForExistence(timeout: 2))
        ligne.tap()

        let enregistrer = app.buttons["Enregistrer"]
        XCTAssertTrue(enregistrer.waitForExistence(timeout: 2))
        XCTAssertFalse(enregistrer.isEnabled)
        XCTAssertTrue(app.staticTexts["Renseignez l'arrivée et le départ, ou choisissez une absence."].exists)

        // Le départ s'ajoute à 17h00 et déplie ses roues : minutes de 5 en 5.
        app.buttons["Ajouter départ"].tap()
        XCTAssertTrue(enregistrer.isEnabled)
        let minutes = app.pickerWheels.element(boundBy: 1)
        XCTAssertTrue(minutes.waitForExistence(timeout: 2))
        minutes.adjust(toPickerWheelValue: "15")
        XCTAssertTrue(app.buttons["Départ : 17h15"].exists)
        enregistrer.tap()

        // 8h00–17h15, 30 min de pause décomptées : 8h45 pour 8h12.
        XCTAssertTrue(app.staticTexts["+0h33"].waitForExistence(timeout: 2))

        // Arrivée et départ : deux heures, le bouton propose encore une fin de
        // pause, qui ferait du départ un début de pause (voir SPECS.md).
        app.tabBars.buttons["Pointer"].tap()
        XCTAssertEqual(app.buttons["bouton-pointer"].label, "Pointer : Fin de pause")
    }

    func testReglerUneDuree() {
        let app = lancer()
        app.tabBars.buttons["Réglages"].tap()
        let seuil = app.buttons.containing(NSPredicate(format: "label CONTAINS 'Seuil de pause'")).firstMatch
        XCTAssertTrue(seuil.waitForExistence(timeout: 2))
        seuil.tap()

        let heures = app.pickerWheels.element(boundBy: 0)
        XCTAssertTrue(heures.waitForExistence(timeout: 2))
        heures.adjust(toPickerWheelValue: "4 h")
        XCTAssertTrue(seuil.label.contains("4h00"))

        XCTAssertTrue(app.buttons["Exporter releve.md"].exists)
    }
}
