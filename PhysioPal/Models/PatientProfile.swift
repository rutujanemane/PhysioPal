import Foundation

struct PatientProfile {
    let name: String
    let age: Int
    let condition: String
    let avatarSystemImage: String
    let startDate: Date

    static let mock = PatientProfile(
        name: "Margaret",
        age: 72,
        condition: "Post knee replacement — Week 4 recovery",
        avatarSystemImage: "person.crop.circle.fill",
        startDate: Calendar.current.date(byAdding: .weekOfYear, value: -4, to: Date())!
    )

    var weeksSinceStart: Int {
        let days = Calendar.current.dateComponents([.day], from: startDate, to: Date()).day ?? 0
        return max(1, days / 7)
    }
}
