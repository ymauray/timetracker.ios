/// L'écriture de `releve.md`, dans le format que la CLI lit tel quel.
enum ReleveWriter {
    static func ecrire(_ journees: [Journee], reglages: Reglages) -> String {
        var lignes = [
            "---",
            "duree_journee: \(Formats.duree(reglages.dureeJournee))",
            "pause_minimum: \(Formats.duree(reglages.pauseMinimum))",
            "seuil_pause: \(Formats.duree(reglages.seuilPause))",
            "tolerance: \(Formats.duree(reglages.tolerance))",
            "---",
            "|Date|Arrivée|Début pause|Fin pause|Départ|Absence|",
            "|---|---|---|---|---|---|",
        ]
        for journee in journees.sorted(by: { $0.date < $1.date }) {
            let date = Formats.dateReleve(journee.date)
            switch journee.contenu {
            case let .travail(arrivee, pause, depart):
                let debut = pause.map { Formats.heureReleve($0.lowerBound) } ?? ""
                let fin = pause.map { Formats.heureReleve($0.upperBound) } ?? ""
                lignes.append("|\(date)|\(Formats.heureReleve(arrivee))|\(debut)|\(fin)|\(Formats.heureReleve(depart))||")
            case let .absence(absence):
                lignes.append("|\(date)|||||\(absence.rawValue)|")
            }
        }
        return lignes.joined(separator: "\n") + "\n"
    }
}
