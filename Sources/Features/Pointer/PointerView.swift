import SwiftUI

/// L'écran principal : le bouton, les pointages du jour, le réalisé en cours et
/// les soldes.
struct PointerView: View {
    @State var model: PointerModel
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        // Le réalisé en cours et la journée affichée suivent l'heure : on relit
        // chaque minute.
        TimelineView(.everyMinute) { contexte in
            ScrollView {
                VStack(spacing: 28) {
                    enTete
                    bouton
                    if !model.aujourdhui.heures.isEmpty {
                        pointagesDuJour
                    }
                    soldes
                    alertes
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
            .onChange(of: contexte.date) { model.rafraichir() }
        }
        .onAppear { model.rafraichir() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { model.rafraichir() }
        }
        .alert(
            model.message ?? "",
            isPresented: Binding(get: { model.message != nil }, set: { if !$0 { model.message = nil } })
        ) {}
        .sensoryFeedback(.success, trigger: model.aujourdhui.heures.count)
    }

    private var enTete: some View {
        VStack(spacing: 4) {
            Text(Affichage.dateLongue(model.aujourdhui.date))
                .font(.title2.weight(.semibold))
            Text("Réalisé aujourd'hui : \(Affichage.duree(model.realiseDuJour))")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
    }

    private var termine: Bool { model.aujourdhui.actionSuivante == nil }

    private var bouton: some View {
        VStack(spacing: 14) {
            Button(action: model.pointer) {
                VStack(spacing: 8) {
                    Image(systemName: termine ? "checkmark" : "hand.tap.fill")
                        .font(.system(size: 34, weight: .semibold))
                    Text(model.aujourdhui.actionSuivante ?? "Journée terminée")
                        .font(.title3.weight(.semibold))
                        .multilineTextAlignment(.center)
                }
                .foregroundStyle(termine ? AnyShapeStyle(.secondary) : AnyShapeStyle(.white))
                .padding(24)
                .frame(width: 210, height: 210)
                .background(termine ? AnyShapeStyle(.fill.secondary) : AnyShapeStyle(Color.accentColor.gradient), in: .circle)
                .shadow(color: .black.opacity(termine ? 0 : 0.15), radius: 12, y: 6)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Pointer : \(model.aujourdhui.actionSuivante ?? "journée terminée")")

            if !model.aujourdhui.heures.isEmpty {
                Button("Annuler le dernier pointage", systemImage: "arrow.uturn.backward", action: model.annulerDernierPointage)
                    .font(.subheadline)
            }
        }
    }

    private var pointagesDuJour: some View {
        Carte(titre: "Aujourd'hui") {
            ForEach(Array(zip(model.aujourdhui.nomsDesHeures, model.aujourdhui.heures)), id: \.0) { pointage in
                LabeledContent(pointage.0, value: Affichage.heure(pointage.1))
                    .monospacedDigit()
            }
        }
    }

    private var soldes: some View {
        HStack(spacing: 12) {
            Tuile(titre: "Cette semaine", valeur: model.bilan.ecartSemaine)
            Tuile(titre: "Solde cumulé", valeur: model.bilan.soldeCumule)
        }
    }

    @ViewBuilder
    private var alertes: some View {
        if model.bilan.horsTolerance {
            Alerte(
                icone: "exclamationmark.triangle.fill", couleur: .red,
                texte: "Solde hors tolérance : l'écart dépasse \(Affichage.duree(model.tolerance)), en plus ou en moins."
            )
        }
        ForEach(model.bilan.journeesIncompletes, id: \.self) { date in
            Alerte(
                icone: "clock.badge.exclamationmark", couleur: .orange,
                texte: "Le \(Affichage.dateCourte(date)) n'a pas de départ : la journée ne compte pas tant qu'elle n'est pas corrigée."
            )
        }
    }
}

private struct Carte<Contenu: View>: View {
    let titre: String
    @ViewBuilder let contenu: Contenu

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(titre)
                .font(.headline)
            contenu
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.fill.tertiary, in: .rect(cornerRadius: 16))
    }
}

private struct Tuile: View {
    let titre: String
    let valeur: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(titre)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(Affichage.ecart(valeur))
                .font(.title2.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(valeur < 0 ? Color.red : valeur > 0 ? Color.green : Color.primary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.fill.tertiary, in: .rect(cornerRadius: 16))
    }
}

private struct Alerte: View {
    let icone: String
    let couleur: Color
    let texte: String

    var body: some View {
        Label {
            Text(texte)
        } icon: {
            Image(systemName: icone)
                .foregroundStyle(couleur)
        }
        .font(.subheadline)
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(couleur.opacity(0.12), in: .rect(cornerRadius: 14))
    }
}
