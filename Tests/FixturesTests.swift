import Foundation
import Testing

/// Les fixtures copiées depuis la CLI doivent arriver entières dans le bundle de
/// test : le calcul de l'étape 3 sera vérifié contre elles, et une fixture
/// absente ferait passer ces tests sans rien vérifier.
struct FixturesTests {
    private static let dossier = Bundle(for: Marqueur.self).resourceURL!
        .appending(path: "Fixtures")

    private final class Marqueur {}

    @Test func chaqueFixtureALesDeuxFichiers() throws {
        let fixtures = try FileManager.default
            .contentsOfDirectory(at: Self.dossier, includingPropertiesForKeys: [.isDirectoryKey])
            .filter { try $0.resourceValues(forKeys: [.isDirectoryKey]).isDirectory == true }

        #expect(!fixtures.isEmpty)
        for fixture in fixtures {
            for fichier in ["releve.md", "attendu.json"] {
                #expect(
                    FileManager.default.fileExists(atPath: fixture.appending(path: fichier).path),
                    "\(fixture.lastPathComponent)/\(fichier) manquant"
                )
            }
        }
    }
}
