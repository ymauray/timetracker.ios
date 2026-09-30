import Foundation
import GRDB

/// La base SQLite de l'app. Une seule table : une ligne par journée pointée ou
/// saisie, heures en minutes depuis minuit.
enum Base {
    /// Base du fichier de l'app, dans Application Support : hors de portée de
    /// l'app Fichiers, sauvegardée avec l'appareil.
    static func ouvrir() throws -> DatabaseQueue {
        let dossier = try FileManager.default.url(
            for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true
        )
        let base = try DatabaseQueue(path: dossier.appending(path: "pointage.sqlite").path)
        try migrateur.migrate(base)
        return base
    }

    /// Base en mémoire, pour les tests et les aperçus.
    static func enMemoire() throws -> DatabaseQueue {
        let base = try DatabaseQueue()
        try migrateur.migrate(base)
        return base
    }

    static var migrateur: DatabaseMigrator {
        var migrateur = DatabaseMigrator()
        migrateur.registerMigration("v1") { db in
            try db.create(table: "jour") { t in
                t.primaryKey("date", .text) // aaaa-mm-jj
                t.column("h1", .integer)
                t.column("h2", .integer)
                t.column("h3", .integer)
                t.column("h4", .integer)
                t.column("absence", .text)
            }
        }
        return migrateur
    }
}
