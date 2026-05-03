import Foundation

struct Cartoon: Identifiable, Codable {
    let week: Int
    let date: String
    let title: String?
    let url: String?
    let imageURL: String?
    let commentCount: Int?

    var id: Int { week }
    var hasData: Bool { url != nil }

    var displayDate: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        guard let d = fmt.date(from: date) else { return date }
        fmt.dateStyle = .medium
        fmt.timeStyle = .none
        return fmt.string(from: d)
    }

    var articleURL: URL? { url.flatMap { URL(string: $0) } }
    var thumbnailURL: URL? { imageURL.flatMap { URL(string: $0) } }
}
