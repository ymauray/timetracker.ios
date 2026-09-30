import SwiftUI

/// La saisie d'une journée : quatre heures ou un code d'absence, avec les
/// validations de `releve.md`.
struct EditionJourView: View {
    @State var edition: EditionJour
    let enregistrer: (JourStocke) -> Void
    let supprimer: () -> Void
    @Environment(\.dismiss) private var fermer
    @State private var confirmerSuppression = false
    @State private var champOuvert: String?

    var body: some View {
        NavigationStack {
            Form {
                Picker("Journée", selection: $edition.mode) {
                    Text("Travail").tag(EditionJour.Mode.travail)
                    Text("Absence").tag(EditionJour.Mode.absence)
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)

                switch edition.mode {
                case .travail:
                    Section {
                        ChampHeure(titre: "Arrivée", minutes: $edition.arrivee, parDefaut: 8 * 60, ouvert: $champOuvert)
                        ChampHeure(titre: "Départ", minutes: $edition.depart, parDefaut: 17 * 60, ouvert: $champOuvert)
                    }
                    Section("Pause") {
                        ChampHeure(titre: "Début pause", minutes: $edition.debutPause, parDefaut: 12 * 60, ouvert: $champOuvert)
                        ChampHeure(titre: "Fin pause", minutes: $edition.finPause, parDefaut: 12 * 60 + 30, ouvert: $champOuvert)
                    }
                case .absence:
                    Picker("Motif", selection: $edition.absence) {
                        ForEach(Absence.allCases, id: \.self) { absence in
                            Text(Affichage.absence(absence)).tag(absence)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }

                if let message = edition.messageErreur {
                    Label(message, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                        .font(.subheadline)
                }

                Section {
                    Button("Supprimer la journée", role: .destructive) { confirmerSuppression = true }
                }
            }
            .navigationTitle(Affichage.dateAbregee(edition.date))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { fermer() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Enregistrer") {
                        if let jour = edition.resultat {
                            enregistrer(jour)
                            fermer()
                        }
                    }
                    .disabled(edition.resultat == nil)
                }
            }
            .confirmationDialog("Supprimer cette journée ?", isPresented: $confirmerSuppression, titleVisibility: .visible) {
                Button("Supprimer", role: .destructive) {
                    supprimer()
                    fermer()
                }
            } message: {
                Text("Un jour ouvré vide compte en déficit d'une journée entière.")
            }
        }
    }
}
