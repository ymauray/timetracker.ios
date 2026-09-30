import Testing

@testable import Pointage

struct SelecteursTests {
    @Test func lesMinutesVontDeCinqEnCinq() {
        #expect(PasDeMinutes.choix(incluant: 30) == [0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55])
    }

    /// 8h12, la journée par défaut, ou 8h03 pointé au bouton : la valeur reste
    /// proposée, à sa place, sans être arrondie.
    @Test func uneValeurHorsPasResteProposee() {
        #expect(PasDeMinutes.choix(incluant: 12) == [0, 5, 10, 12, 15, 20, 25, 30, 35, 40, 45, 50, 55])
        #expect(PasDeMinutes.choix(incluant: 3).prefix(3) == [0, 3, 5])
    }
}
