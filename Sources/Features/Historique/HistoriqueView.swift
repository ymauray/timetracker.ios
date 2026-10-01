import SwiftUI

/// Les jours par semaine, avec l'écart de chacun ; un appui ouvre l'édition.
struct HistoriqueView: View {
    @State var model: HistoriqueModel
    @State private var edition: EditionJour?
    @State private var choixDuJour = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(model.historique.semaines) { semaine in
                    Section {
                        ForEach(semaine.jours) { jour in
                            Button { edition = EditionJour(jour.stocke) } label: { LigneJour(jour: jour) }
                                .tint(.primary)
                        }
                    } header: {
                        EnTeteSemaine(semaine: semaine)
                    }
                }
            }
            .overlay {
                if model.historique.semaines.isEmpty {
                    ContentUnavailableView(
                        "Aucune journée",
                        systemImage: "calendar",
                        description: Text("Les journées pointées ou saisies apparaîtront ici.")
                    )
                }
            }
            .navigationTitle("Historique")
            .toolbar {
                Button("Ajouter une journée", systemImage: "plus") { choixDuJour = true }
            }
            .sheet(item: $edition) { edition in
                EditionJourView(
                    edition: edition,
                    enregistrer: { model.enregistrer($0) },
                    supprimer: { model.supprimer(edition.date) }
                )
            }
            .sheet(isPresented: $choixDuJour) {
                ChoixDuJour(jusquA: model.aujourdhui) { date in
                    choixDuJour = false
                    edition = EditionJour(model.jour(date))
                }
                .presentationDetents([.medium])
            }
            .alert(
                model.message ?? "",
                isPresented: Binding(get: { model.message != nil }, set: { if !$0 { model.message = nil } })
            ) {}
            .onAppear { model.rafraichir() }
        }
    }
}

extension EditionJour: Identifiable {
    var id: DateCivile { date }
}

private struct EnTeteSemaine: View {
    let semaine: Historique.Semaine

    var body: some View {
        HStack {
            Text("Semaine \(semaine.numero) · \(Affichage.semaine(lundi: semaine.lundi))")
            Spacer()
            if let ecart = semaine.ecart {
                Text(Affichage.ecart(ecart))
                    .monospacedDigit()
                    .foregroundStyle(couleur(ecart))
            }
        }
    }
}

private struct LigneJour: View {
    let jour: Historique.Jour

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 3) {
                Text(Affichage.dateListe(jour.date))
                detail
                    .font(.subheadline)
            }
            Spacer()
            if let ecart = jour.ecart {
                Text(Affichage.ecart(ecart))
                    .monospacedDigit()
                    .foregroundStyle(couleur(ecart))
            }
        }
        .contentShape(.rect)
    }

    @ViewBuilder
    private var detail: some View {
        switch jour.statut {
        case let .travail(absence):
            Text(absence.map { "\(Affichage.absence($0)) · \(heures)" } ?? heures)
                .foregroundStyle(.secondary).monospacedDigit()
        case let .absence(absence):
            Text(Affichage.absence(absence)).foregroundStyle(.secondary)
        case .enCours:
            Text("En cours · \(heures)").foregroundStyle(.secondary).monospacedDigit()
        case .sansDepart:
            Label("Sans départ · \(heures)", systemImage: "clock.badge.exclamationmark")
                .foregroundStyle(.orange)
        case .nonRenseigne:
            Label("Non renseigné", systemImage: "exclamationmark.circle")
                .foregroundStyle(.red)
        }
    }

    /// « 8h00–12h00 · 12h30–16h42 », en regroupant les heures deux à deux.
    private var heures: String {
        let h = jour.stocke.heures.map(Affichage.heure)
        return stride(from: 0, to: h.count, by: 2)
            .map { $0 + 1 < h.count ? "\(h[$0])–\(h[$0 + 1])" : "\(h[$0])–" }
            .joined(separator: " · ")
    }
}

private func couleur(_ ecart: Int) -> Color {
    ecart < 0 ? .red : ecart > 0 ? .green : .secondary
}

/// Le choix d'une date à saisir, aujourd'hui au plus tard.
private struct ChoixDuJour: View {
    let jusquA: DateCivile
    let choisir: (DateCivile) -> Void
    @State private var date = Date()

    var body: some View {
        NavigationStack {
            DatePicker(
                "Jour", selection: $date,
                in: ...SelecteurUTC.date(jusquA),
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .environment(\.timeZone, SelecteurUTC.calendrier.timeZone)
            .padding(.horizontal)
            .navigationTitle("Ajouter une journée")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button("Continuer") { choisir(SelecteurUTC.dateCivile(date)) }
            }
            .onAppear { date = SelecteurUTC.date(jusquA) }
        }
    }
}
