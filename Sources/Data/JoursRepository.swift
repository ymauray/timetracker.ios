import GRDB

/// Lecture et écriture des journées stockées.
struct JoursRepository: Sendable {
    let base: any DatabaseWriter

    func tous() throws -> [JourStocke] {
        try base.read { db in
            try LigneJour.order(Column("date")).fetchAll(db).compactMap(\.jour)
        }
    }

    func jour(_ date: DateCivile) throws -> JourStocke {
        try base.read { db in
            try LigneJour.fetchOne(db, key: LigneJour.cle(date))?.jour
        } ?? JourStocke(date: date)
    }

    /// Une journée vide n'a pas de ligne : l'enregistrer supprime la sienne.
    func enregistrer(_ jour: JourStocke) throws {
        try base.write { db in
            if jour.heures.isEmpty, jour.absence == nil {
                _ = try LigneJour.deleteOne(db, key: LigneJour.cle(jour.date))
            } else {
                try LigneJour(jour).save(db)
            }
        }
    }

    func supprimer(_ date: DateCivile) throws {
        _ = try base.write { db in
            try LigneJour.deleteOne(db, key: LigneJour.cle(date))
        }
    }

    /// Remplace tout l'historique, en une transaction.
    func remplacerTout(par jours: [JourStocke]) throws {
        try base.write { db in
            try LigneJour.deleteAll(db)
            for jour in jours {
                try LigneJour(jour).insert(db)
            }
        }
    }
}

private struct LigneJour: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "jour"

    var date: String
    var h1: Int?
    var h2: Int?
    var h3: Int?
    var h4: Int?
    var absence: String?

    init(_ jour: JourStocke) {
        date = Self.cle(jour.date)
        let heures = jour.heures.map(Optional.some) + Array(repeating: nil, count: 4 - jour.heures.count)
        (h1, h2, h3, h4) = (heures[0], heures[1], heures[2], heures[3])
        absence = jour.absence?.rawValue
    }

    /// Nil pour une ligne illisible, écrite par une version future par exemple.
    var jour: JourStocke? {
        let parties = date.split(separator: "-").compactMap { Int($0) }
        guard parties.count == 3, let date = DateCivile(annee: parties[0], mois: parties[1], jour: parties[2]) else {
            return nil
        }
        return JourStocke(date: date, heures: [h1, h2, h3, h4].compactMap(\.self), absence: absence.flatMap(Absence.init))
    }

    static func cle(_ date: DateCivile) -> String {
        func deux(_ n: Int) -> String { n < 10 ? "0\(n)" : "\(n)" }
        return "\(date.annee)-\(deux(date.mois))-\(deux(date.jour))"
    }
}
