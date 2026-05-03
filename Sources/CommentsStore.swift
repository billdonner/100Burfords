import Foundation

final class CommentsStore {
    static let shared = CommentsStore()
    private let allComments: [String: [CartoonComment]]

    private init() {
        guard
            let url = Bundle.main.url(forResource: "comments", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let decoded = try? JSONDecoder().decode([String: [CartoonComment]].self, from: data)
        else {
            allComments = [:]
            return
        }
        allComments = decoded
    }

    func comments(forWeek week: Int) -> [CartoonComment] {
        allComments["\(week)"] ?? []
    }
}
