/// Lecture de `releve.md`, reprise de `ConfigParser` et `ReleveParser` de la
/// CLI : mêmes règles, mêmes messages, mêmes numéros de ligne.
enum ReleveParser {
    struct Resultat: Equatable, Sendable {
        let reglages: Reglages
        let journees: [Journee]
        /// Erreurs du front-matter, puis du tableau.
        let erreurs: [ErreurReleve]
    }

    static func analyser(_ texte: String) -> Resultat {
        let lignes = decouperEnLignes(texte)
        let (reglages, erreursConfig) = analyserFrontMatter(lignes)
        let (journees, erreursTableau) = analyserTableau(lignes)
        return Resultat(reglages: reglages, journees: journees, erreurs: erreursConfig + erreursTableau)
    }

    /// Découpe comme `File.ReadAllLines` : `\n`, `\r\n` ou `\r`, sans ligne vide
    /// finale après le dernier saut, marque d'ordre des octets retirée.
    static func decouperEnLignes(_ texte: String) -> [String] {
        var texte = Substring(texte)
        if texte.first == "\u{FEFF}" { texte = texte.dropFirst() }
        var lignes = texte.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline).map(String.init)
        if lignes.last == "" { lignes.removeLast() }
        return lignes
    }

    // MARK: Front-matter

    private static let delimiteur = "---"

    static func analyserFrontMatter(_ lignes: [String]) -> (Reglages, [ErreurReleve]) {
        var erreurs: [ErreurReleve] = []
        guard lignes.first?.trimmed == delimiteur else { return (.defaut, erreurs) }

        guard let fin = lignes.indices.dropFirst().first(where: { lignes[$0].trimmed == delimiteur }) else {
            erreurs.append(ErreurReleve(ligne: 1, message: "Front-matter non ferme : ligne '---' de fin introuvable."))
            return (.defaut, erreurs)
        }

        var valeurs: [String: String] = [:]
        for i in 1..<fin {
            let ligne = lignes[i].trimmed
            if ligne.isEmpty { continue }
            guard let separateur = ligne.firstIndex(of: ":") else {
                erreurs.append(ErreurReleve(ligne: i + 1, message: "Ligne de front-matter invalide (attendu 'cle: valeur') : '\(ligne)'."))
                continue
            }
            let cle = ligne[..<separateur].trimmed.lowercased()
            valeurs[cle] = ligne[ligne.index(after: separateur)...].trimmed
        }

        func lireDuree(_ cle: String, _ defaut: Int) -> Int {
            guard let texte = valeurs[cle] else { return defaut }
            guard let (heures, minutes) = Formats.lireDuree(texte) else {
                erreurs.append(ErreurReleve(ligne: 1, message: "Valeur invalide pour '\(cle)' dans le front-matter : '\(texte)' (format attendu ex: 8h12)."))
                return defaut
            }
            return heures * 60 + minutes
        }

        // Même ordre de lecture que la CLI, qui fixe l'ordre des erreurs.
        let reglages = Reglages(
            dureeJournee: lireDuree("duree_journee", Reglages.defaut.dureeJournee),
            pauseMinimum: lireDuree("pause_minimum", Reglages.defaut.pauseMinimum),
            seuilPause: lireDuree("seuil_pause", Reglages.defaut.seuilPause),
            tolerance: lireDuree("tolerance", Reglages.defaut.tolerance)
        )
        return (reglages, erreurs)
    }

    // MARK: Tableau

    private static let colonnesAttendues = ["Date", "Arrivee", "Debut pause", "Fin pause", "Depart", "Absence"]

    static func analyserTableau(_ lignes: [String]) -> ([Journee], [ErreurReleve]) {
        var erreurs: [ErreurReleve] = []
        var journees: [Journee] = []
        var datesVues: [DateCivile: Int] = [:]

        let tableau = lignes.enumerated()
            .filter { $0.element.drop(while: \.isWhitespace).first == "|" }
            .map { (texte: $0.element, numero: $0.offset + 1) }

        guard tableau.count >= 2 else {
            erreurs.append(ErreurReleve(ligne: 1, message: "Aucun tableau markdown (lignes commencant par '|') trouve dans le fichier."))
            return (journees, erreurs)
        }

        let enTete = cellules(tableau[0].texte).map { retirerAccents($0.trimmed) }
        guard enTete.count >= colonnesAttendues.count,
              zip(enTete, colonnesAttendues).allSatisfy(==)
        else {
            erreurs.append(ErreurReleve(
                ligne: tableau[0].numero,
                message: "En-tete de tableau invalide : colonnes attendues = |Date|Arrivée|Début pause|Fin pause|Départ|Absence|"
            ))
            return (journees, erreurs)
        }

        // Première ligne : l'en-tête ; deuxième : le séparateur ; ensuite, les données.
        for (texte, numero) in tableau.dropFirst(2) {
            func erreur(_ message: String) {
                erreurs.append(ErreurReleve(ligne: numero, message: message))
            }

            let cellules = cellules(texte)
            guard cellules.count >= colonnesAttendues.count else {
                erreur("Ligne incomplete : \(cellules.count) colonne(s) trouvee(s), 6 attendues.")
                continue
            }

            let dateTexte = cellules[0].trimmed
            if dateTexte.isEmpty { continue } // ligne sans date : séparateur visuel, ignorée

            guard let date = lireDate(dateTexte) else {
                erreur("Date invalide '\(dateTexte)' (format attendu jj.mm.aaaa, ex: 1.10.2026 ou 21.02.2027).")
                continue
            }

            if let premiereLigne = datesVues[date] {
                erreur("Date en double : \(Formats.dateMessage(date)) (deja presente ligne \(premiereLigne)).")
                continue
            }

            let absenceTexte = cellules[5].trimmed
            var absence: Absence?
            if !absenceTexte.isEmpty {
                guard let code = lireAbsence(absenceTexte) else {
                    erreur("Code absence inconnu '\(absenceTexte)' (valeurs valides : Conges ou CP, Maladie, Ferie, RTT, Divers, Demi).")
                    continue
                }
                absence = code
            }

            var erreurHeure = false
            func lireHeure(_ cellule: String, _ nomChamp: String) -> Int? {
                let texteHeure = cellule.trimmed
                if texteHeure.isEmpty { return nil }
                guard let (heures, minutes) = Formats.lireDuree(texteHeure) else {
                    erreur("Heure invalide pour '\(nomChamp)' : '\(texteHeure)' (format attendu ex: 8h50).")
                    erreurHeure = true
                    return nil
                }
                guard heures <= 23 else {
                    erreur("Heure hors limites pour '\(nomChamp)' : '\(texteHeure)'.")
                    erreurHeure = true
                    return nil
                }
                return heures * 60 + minutes
            }

            let arrivee = lireHeure(cellules[1], "Arrivee")
            let debutPause = lireHeure(cellules[2], "Debut pause")
            let finPause = lireHeure(cellules[3], "Fin pause")
            let depart = lireHeure(cellules[4], "Depart")
            if erreurHeure { continue }

            switch ValidationJournee.valider(
                arrivee: arrivee, debutPause: debutPause, finPause: finPause, depart: depart, absence: absence
            ) {
            case let .success(contenu):
                datesVues[date] = numero
                journees.append(Journee(date: date, contenu: contenu))
            case let .failure(erreurJournee):
                erreur(erreurJournee.messageReleve)
            }
        }

        return (journees, erreurs)
    }

    /// « j.m.aaaa », jour et mois sur un ou deux chiffres, année sur quatre.
    private static func lireDate(_ texte: String) -> DateCivile? {
        let parties = texte.split(separator: ".", omittingEmptySubsequences: false)
        guard parties.count == 3,
              (1...2).contains(parties[0].count), (1...2).contains(parties[1].count), parties[2].count == 4,
              parties.allSatisfy({ $0.allSatisfy(\.isASCIIChiffre) }),
              let jour = Int(parties[0]), let mois = Int(parties[1]), let annee = Int(parties[2])
        else { return nil }
        return DateCivile(annee: annee, mois: mois, jour: jour)
    }

    private static func lireAbsence(_ texte: String) -> Absence? {
        switch retirerAccents(texte).trimmed.uppercased() {
        case "CP", "CONGES": .conges
        case "MALADIE": .maladie
        case "FERIE": .ferie
        case "RTT": .rtt
        case "DIVERS": .divers
        case "DEMI": .demi
        default: nil
        }
    }

    private static func retirerAccents(_ texte: String) -> String {
        String(texte.map { caractere -> Character in
            switch caractere {
            case "é", "è", "ê": "e"
            case "É", "È", "Ê": "E"
            default: caractere
            }
        })
    }

    private static func cellules(_ ligne: String) -> [String] {
        var t = Substring(ligne.trimmed)
        if t.first == "|" { t = t.dropFirst() }
        if t.last == "|" { t = t.dropLast() }
        return t.split(separator: "|", omittingEmptySubsequences: false).map(String.init)
    }
}
