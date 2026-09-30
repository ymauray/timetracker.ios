/// Les formats de texte partagés avec la CLI.
enum Formats {
    /// Lit « 8h12 », « 8h » ou « 0h30 » (insensible à la casse) : heures sur un
    /// ou deux chiffres, minutes facultatives sur deux chiffres. Reprise de
    /// `DureeParsing` de la CLI.
    static func lireDuree(_ texte: String) -> (heures: Int, minutes: Int)? {
        let caracteres = Array(texte.trimmed.lowercased())
        guard let h = caracteres.firstIndex(of: "h"),
              (1...2).contains(h),
              caracteres[..<h].allSatisfy(\.isASCIIChiffre)
        else { return nil }
        let apres = caracteres[(h + 1)...]
        guard apres.isEmpty || (apres.count == 2 && apres.allSatisfy(\.isASCIIChiffre)) else { return nil }
        let heures = Int(String(caracteres[..<h]))!
        let minutes = apres.isEmpty ? 0 : Int(String(apres))!
        guard minutes <= 59 else { return nil }
        return (heures, minutes)
    }

    /// « 8h12 », « 10h00 », « -0h45 » : le format des durées de la CLI.
    static func duree(_ minutes: Int) -> String {
        let signe = minutes < 0 ? "-" : ""
        let valeur = abs(minutes)
        return "\(signe)\(valeur / 60)h\(deuxChiffres(valeur % 60))"
    }

    /// « 08h50 » : l'heure telle que les messages d'erreur de la CLI l'écrivent.
    static func heureMessage(_ minutes: Int) -> String {
        "\(deuxChiffres(minutes / 60))h\(deuxChiffres(minutes % 60))"
    }

    /// « 8h50 » : l'heure telle que `releve.md` l'écrit.
    static func heureReleve(_ minutes: Int) -> String {
        "\(minutes / 60)h\(deuxChiffres(minutes % 60))"
    }

    /// « 28/09/2026 » : la date telle que les messages d'erreur de la CLI l'écrivent.
    static func dateMessage(_ date: DateCivile) -> String {
        "\(deuxChiffres(date.jour))/\(deuxChiffres(date.mois))/\(date.annee)"
    }

    /// « 5.10.2026 » : la date telle que `releve.md` l'écrit.
    static func dateReleve(_ date: DateCivile) -> String {
        "\(date.jour).\(date.mois).\(date.annee)"
    }

    private static func deuxChiffres(_ n: Int) -> String {
        n < 10 ? "0\(n)" : "\(n)"
    }
}

extension Character {
    var isASCIIChiffre: Bool { isASCII && isWholeNumber }
}

extension StringProtocol {
    /// Espaces retirés aux deux bouts, comme `Trim()` en C#.
    var trimmed: String {
        var debut = startIndex
        var fin = endIndex
        while debut < fin, self[debut].isWhitespace { debut = index(after: debut) }
        while fin > debut, self[index(before: fin)].isWhitespace { fin = index(before: fin) }
        return String(self[debut..<fin])
    }
}
