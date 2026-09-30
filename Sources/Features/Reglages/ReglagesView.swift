import SwiftUI
import UniformTypeIdentifiers

/// Les réglages du calcul, l'export et l'import de `releve.md`.
struct ReglagesView: View {
    @State var model: ReglagesModel
    @State private var dureeOuverte: String?
    @State private var choixDuFichier = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    ChampDuree(titre: "Durée de la journée", minutes: $model.reglages.dureeJournee, ouvert: $dureeOuverte)
                    ChampDuree(titre: "Pause minimum", minutes: $model.reglages.pauseMinimum, ouvert: $dureeOuverte)
                    ChampDuree(titre: "Seuil de pause", minutes: $model.reglages.seuilPause, ouvert: $dureeOuverte)
                    ChampDuree(titre: "Tolérance", minutes: $model.reglages.tolerance, ouvert: $dureeOuverte)
                } header: {
                    Text("Calcul")
                } footer: {
                    Text("""
                    Une journée sans pause perd la pause minimum, sauf si la présence reste sous le seuil de pause. \
                    La tolérance borne le solde cumulé, en plus ou en moins. \
                    Ces réglages valent pour tout l'historique : les modifier recalcule tous les soldes passés.
                    """)
                }

                Section {
                    if let export = model.export {
                        ShareLink(item: FichierReleve(contenu: export), preview: SharePreview("releve.md")) {
                            Label("Exporter releve.md", systemImage: "square.and.arrow.up")
                        }
                    } else {
                        Label("Exporter releve.md", systemImage: "square.and.arrow.up")
                            .foregroundStyle(.secondary)
                    }
                    Button("Importer un releve.md", systemImage: "square.and.arrow.down") { choixDuFichier = true }
                } header: {
                    Text("Échange avec la CLI")
                } footer: {
                    if model.journeesIncompletes.isEmpty {
                        Text("L'import remplace tout l'historique et les réglages par ceux du fichier.")
                    } else {
                        Text(messageExportBloque(model.journeesIncompletes))
                            .foregroundStyle(.orange)
                    }
                }
            }
            .navigationTitle("Réglages")
            .fileImporter(isPresented: $choixDuFichier, allowedContentTypes: typesReleve) { resultat in
                lire(resultat)
            }
            .confirmationDialog(
                "Remplacer tout l'historique ?",
                isPresented: Binding(get: { model.importEnAttente != nil }, set: { if !$0 { model.importEnAttente = nil } }),
                titleVisibility: .visible
            ) {
                Button("Remplacer", role: .destructive) { model.confirmerImport() }
            } message: {
                let nombre = model.importEnAttente?.journees.count ?? 0
                Text("Les \(nombre) journées du fichier et ses réglages remplaceront ceux de l'app. Exportez d'abord si vous voulez garder une copie.")
            }
            .sheet(isPresented: Binding(get: { model.erreursImport != nil }, set: { if !$0 { model.erreursImport = nil } })) {
                ErreursImport(erreurs: model.erreursImport ?? [])
            }
            .alert(
                model.message ?? "",
                isPresented: Binding(get: { model.message != nil }, set: { if !$0 { model.message = nil } })
            ) {}
            .onAppear { model.rafraichir() }
        }
    }

    /// « Export impossible : le 29 septembre n'a pas de départ, corrigez-le dans
    /// l'historique. »
    private func messageExportBloque(_ dates: [DateCivile]) -> String {
        let liste = dates.map { "le \(Affichage.dateCourte($0))" }.formatted(.list(type: .and))
        return dates.count > 1
            ? "Export impossible : \(liste) n'ont pas de départ, corrigez-les dans l'historique."
            : "Export impossible : \(liste) n'a pas de départ, corrigez-le dans l'historique."
    }

    private func lire(_ resultat: Result<URL, any Error>) {
        do {
            let url = try resultat.get()
            let acces = url.startAccessingSecurityScopedResource()
            defer { if acces { url.stopAccessingSecurityScopedResource() } }
            model.lire(try String(contentsOf: url, encoding: .utf8))
        } catch {
            model.message = "Lecture du fichier impossible : \(error.localizedDescription)"
        }
    }
}

/// Un `.md` n'a pas toujours de type déclaré sur l'appareil : on accepte aussi
/// le texte brut.
private let typesReleve: [UTType] = [UTType(filenameExtension: "md"), .plainText].compactMap(\.self)

/// Le `releve.md` exporté, partagé comme un fichier et non comme du texte.
private struct FichierReleve: Transferable {
    let contenu: String

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .plainText) { fichier in
            let url = FileManager.default.temporaryDirectory.appending(path: "releve.md")
            try fichier.contenu.write(to: url, atomically: true, encoding: .utf8)
            return SentTransferredFile(url)
        }
    }
}

/// Une durée en heures et minutes, qui s'ouvre sur deux roues au toucher.
private struct ChampDuree: View {
    let titre: String
    @Binding var minutes: Int
    @Binding var ouvert: String?

    var body: some View {
        Button {
            withAnimation { ouvert = ouvert == titre ? nil : titre }
        } label: {
            LabeledContent(titre) {
                Text(Affichage.duree(minutes))
                    .monospacedDigit()
                    .foregroundStyle(ouvert == titre ? Color.accentColor : .secondary)
            }
        }
        .tint(.primary)

        if ouvert == titre {
            HStack(spacing: 0) {
                Picker("Heures", selection: Binding(get: { minutes / 60 }, set: { minutes = $0 * 60 + minutes % 60 })) {
                    ForEach(0..<100) { Text("\($0) h").tag($0) }
                }
                Picker("Minutes", selection: Binding(get: { minutes % 60 }, set: { minutes = minutes / 60 * 60 + $0 })) {
                    ForEach(0..<60) { Text("\($0) min").tag($0) }
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 150)
        }
    }
}

/// Les erreurs d'un fichier refusé, avec leur numéro de ligne, comme la CLI.
private struct ErreursImport: View {
    let erreurs: [ErreurReleve]
    @Environment(\.dismiss) private var fermer

    var body: some View {
        NavigationStack {
            List(Array(erreurs.enumerated()), id: \.offset) { _, erreur in
                VStack(alignment: .leading, spacing: 4) {
                    Text("Ligne \(erreur.ligne)")
                        .font(.subheadline.weight(.semibold))
                    Text(erreur.message)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Fichier refusé")
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .top) {
                Text("Aucune donnée n'a été modifiée. Corrigez le fichier puis importez-le de nouveau.")
                    .font(.subheadline)
                    .padding(.horizontal)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .toolbar {
                Button("Fermer") { fermer() }
            }
        }
    }
}
