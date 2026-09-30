import SwiftUI

/// Le calendrier système travaille en `Date`. On le fait tourner en UTC, pour
/// que le jour choisi ne dépende d'aucun fuseau : la conversion ne sort jamais
/// de cet écran.
enum SelecteurUTC {
    static let calendrier: Calendar = {
        var calendrier = Calendar(identifier: .gregorian)
        calendrier.timeZone = TimeZone(identifier: "UTC")!
        return calendrier
    }()

    static func date(_ jour: DateCivile) -> Date {
        calendrier.date(from: DateComponents(year: jour.annee, month: jour.mois, day: jour.jour, hour: 12))!
    }

    static func dateCivile(_ date: Date) -> DateCivile {
        let c = calendrier.dateComponents([.year, .month, .day], from: date)
        return DateCivile(annee: c.year!, mois: c.month!, jour: c.day!)!
    }
}

/// Les minutes proposées par les sélecteurs : de 5 en 5, ça suffit. Une valeur
/// qui tombe entre deux (pointée au bouton, importée, ou la journée de 8h12 par
/// défaut) reste affichée telle quelle, sans être arrondie.
enum PasDeMinutes {
    static let pas = 5

    static func choix(incluant minute: Int) -> [Int] {
        let pas = Array(stride(from: 0, to: 60, by: pas))
        return pas.contains(minute) ? pas : (pas + [minute]).sorted()
    }
}

/// Deux roues : les heures, puis les minutes de 5 en 5.
struct RouesHeuresMinutes: View {
    @Binding var minutes: Int
    let heures: Range<Int>
    let libelleHeures: (Int) -> String
    let libelleMinutes: (Int) -> String

    var body: some View {
        HStack(spacing: 0) {
            Picker("Heures", selection: Binding(get: { minutes / 60 }, set: { minutes = $0 * 60 + minutes % 60 })) {
                ForEach(heures, id: \.self) { Text(libelleHeures($0)).tag($0) }
            }
            Picker("Minutes", selection: Binding(get: { minutes % 60 }, set: { minutes = minutes / 60 * 60 + $0 })) {
                ForEach(PasDeMinutes.choix(incluant: minutes % 60), id: \.self) { Text(libelleMinutes($0)).tag($0) }
            }
        }
        .pickerStyle(.wheel)
        .frame(height: 150)
    }
}

/// Une heure facultative sur une ligne : sa valeur, qui déplie les roues au
/// toucher, ou un bouton pour l'ajouter. Un seul champ est ouvert à la fois.
struct ChampHeure: View {
    let titre: String
    @Binding var minutes: Int?
    /// Heure proposée quand on ajoute le champ.
    let parDefaut: Int
    @Binding var ouvert: String?

    var body: some View {
        HStack {
            Text(titre)
            Spacer()
            if let valeur = minutes {
                Button(Affichage.heure(valeur)) {
                    withAnimation { ouvert = ouvert == titre ? nil : titre }
                }
                .monospacedDigit()
                .foregroundStyle(ouvert == titre ? Color.accentColor : .secondary)
                .accessibilityLabel("\(titre) : \(Affichage.heure(valeur))")
                Button("Retirer \(titre.lowercased())", systemImage: "xmark.circle.fill") {
                    minutes = nil
                    if ouvert == titre { ouvert = nil }
                }
                .labelStyle(.iconOnly)
                .foregroundStyle(.secondary)
            } else {
                Button("Ajouter") {
                    minutes = parDefaut
                    withAnimation { ouvert = titre }
                }
                .accessibilityLabel("Ajouter \(titre.lowercased())")
            }
        }
        .buttonStyle(.borderless)

        if ouvert == titre, let valeur = minutes {
            RouesHeuresMinutes(
                minutes: Binding(get: { valeur }, set: { minutes = $0 }),
                heures: 0..<24,
                libelleHeures: { "\($0) h" },
                libelleMinutes: { $0 < 10 ? "0\($0)" : "\($0)" }
            )
        }
    }
}
