import SwiftUI

/// Les sélecteurs système travaillent en `Date`. On les fait tourner sur un
/// calendrier fixe en UTC, pour que l'heure choisie ne dépende d'aucun fuseau :
/// la conversion ne sort jamais de cet écran.
enum SelecteurUTC {
    static let calendrier: Calendar = {
        var calendrier = Calendar(identifier: .gregorian)
        calendrier.timeZone = TimeZone(identifier: "UTC")!
        return calendrier
    }()

    static func date(_ minutes: Int) -> Date {
        calendrier.date(from: DateComponents(year: 2001, month: 1, day: 1, hour: minutes / 60, minute: minutes % 60))!
    }

    static func minutes(_ date: Date) -> Int {
        let c = calendrier.dateComponents([.hour, .minute], from: date)
        return c.hour! * 60 + c.minute!
    }

    static func date(_ jour: DateCivile) -> Date {
        calendrier.date(from: DateComponents(year: jour.annee, month: jour.mois, day: jour.jour, hour: 12))!
    }

    static func dateCivile(_ date: Date) -> DateCivile {
        let c = calendrier.dateComponents([.year, .month, .day], from: date)
        return DateCivile(annee: c.year!, mois: c.month!, jour: c.day!)!
    }
}

/// Une heure facultative sur une ligne : un sélecteur compact quand elle est
/// renseignée, un bouton pour l'ajouter sinon.
struct ChampHeure: View {
    let titre: String
    @Binding var minutes: Int?
    /// Heure proposée quand on ajoute le champ.
    let parDefaut: Int

    var body: some View {
        HStack {
            Text(titre)
            Spacer()
            if let valeur = minutes {
                DatePicker(
                    titre,
                    selection: Binding(get: { SelecteurUTC.date(valeur) }, set: { minutes = SelecteurUTC.minutes($0) }),
                    displayedComponents: .hourAndMinute
                )
                .labelsHidden()
                .environment(\.timeZone, SelecteurUTC.calendrier.timeZone)
                .environment(\.locale, Locale(identifier: "fr_CH"))
                Button("Retirer \(titre.lowercased())", systemImage: "xmark.circle.fill") { minutes = nil }
                    .labelStyle(.iconOnly)
                    .foregroundStyle(.secondary)
                    .buttonStyle(.borderless)
            } else {
                Button("Ajouter") { minutes = parDefaut }
                    .buttonStyle(.borderless)
                    .accessibilityLabel("Ajouter \(titre.lowercased())")
            }
        }
    }
}
