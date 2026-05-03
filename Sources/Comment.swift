import Foundation

struct CartoonComment: Identifiable, Codable {
    let id: Int
    let author: String
    let text: String
    let date: String
}
