import Observation

/// Les réglages du calcul, l'export et l'import de `releve.md`.
@MainActor @Observable
final class ReglagesModel {
    private let repository: JoursRepository
    private let horloge: any Horloge
    private let preferences: AppPreferences

    var reglages: Reglages {
        didSet { preferences.reglages = reglages }
    }

    private var jours: [JourStocke] = []
    private var aujourdhui: DateCivile

    /// Un fichier lu sans erreur, en attente de confirmation avant de remplacer
    /// l'historique.
    var importEnAttente: ReleveParser.Resultat?
    /// Les erreurs du dernier fichier lu, présentées comme dans la CLI.
    var erreursImport: [ErreurReleve]?
    var message: String?

    init(repository: JoursRepository, horloge: any Horloge, preferences: AppPreferences) {
        self.repository = repository
        self.horloge = horloge
        self.preferences = preferences
        reglages = preferences.reglages
        aujourdhui = horloge.maintenant().date
        rafraichir()
    }

    /// Journées passées sans départ : tant qu'il en reste, l'export est bloqué,
    /// `releve.md` ne sachant pas les écrire.
    var journeesIncompletes: [DateCivile] {
        jours.filter { $0.etat == .enCours && $0.date < aujourdhui }.map(\.date)
    }

    /// Le `releve.md` à exporter, nil quand l'export est bloqué. La journée du
    /// jour n'y figure qu'une fois complète.
    var export: String? {
        guard journeesIncompletes.isEmpty else { return nil }
        let completes = jours.compactMap { jour -> Journee? in
            if case let .complete(journee) = jour.etat { journee } else { nil }
        }
        return ReleveWriter.ecrire(completes, reglages: reglages)
    }

    func rafraichir() {
        if preferences.reglages != reglages { reglages = preferences.reglages }
        aujourdhui = horloge.maintenant().date
        do {
            jours = try repository.tous()
        } catch {
            message = "Lecture impossible : \(error.localizedDescription)"
        }
    }

    /// Lit un `releve.md` : ses erreurs s'affichent, sinon il attend confirmation.
    func lire(_ texte: String) {
        let resultat = ReleveParser.analyser(texte)
        if resultat.erreurs.isEmpty {
            importEnAttente = resultat
        } else {
            erreursImport = resultat.erreurs
        }
    }

    /// Remplace tout l'historique et les réglages par ceux du fichier confirmé.
    func confirmerImport() {
        guard let resultat = importEnAttente else { return }
        importEnAttente = nil
        do {
            try repository.remplacerTout(par: resultat.journees.map(JourStocke.init))
            reglages = resultat.reglages
        } catch {
            message = "Import impossible : \(error.localizedDescription)"
        }
        rafraichir()
    }
}
