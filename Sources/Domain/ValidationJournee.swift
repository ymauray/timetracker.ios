/// Les règles de cohérence d'une journée, reprises de `ReleveParser` de la CLI
/// avec ses messages au caractère près. Le parser et l'écran d'édition passent
/// tous deux par ici.
enum ValidationJournee {
    /// Heures en minutes depuis minuit. Renvoie le contenu de la journée, ou le
    /// message de la première règle enfreinte.
    static func valider(
        arrivee: Int?, debutPause: Int?, finPause: Int?, depart: Int?, absence: Absence?
    ) -> Result<Journee.Contenu, MessageInvalide> {
        if let absence {
            guard arrivee == nil, debutPause == nil, finPause == nil, depart == nil else {
                return .failure("Jour marque en absence mais des horaires sont renseignes : videz les colonnes horaires ou retirez le code absence.")
            }
            return .success(.absence(absence))
        }
        guard let arrivee, let depart else {
            return .failure("Arrivee et Depart sont obligatoires pour un jour travaille (ou renseignez un code Absence).")
        }
        guard depart > arrivee else {
            return .failure("Depart (\(Formats.heureMessage(depart))) doit etre apres Arrivee (\(Formats.heureMessage(arrivee))).")
        }
        switch (debutPause, finPause) {
        case (nil, nil):
            return .success(.travail(arrivee: arrivee, pause: nil, depart: depart))
        case let (debut?, fin?):
            guard fin > debut else {
                return .failure("Fin pause (\(Formats.heureMessage(fin))) doit etre apres Debut pause (\(Formats.heureMessage(debut))).")
            }
            guard debut >= arrivee, fin <= depart else {
                return .failure("La pause doit etre comprise entre l'arrivee et le depart.")
            }
            return .success(.travail(arrivee: arrivee, pause: debut...fin, depart: depart))
        default:
            return .failure("Debut pause et Fin pause doivent etre soit tous les deux renseignes, soit tous les deux vides.")
        }
    }
}

struct MessageInvalide: Error, Equatable, ExpressibleByStringLiteral, ExpressibleByStringInterpolation {
    let texte: String

    init(stringLiteral texte: String) {
        self.texte = texte
    }
}
