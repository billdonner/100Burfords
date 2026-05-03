import Foundation
import UIKit

@Observable
class CartoonStore {
    let cartoons: [Cartoon]
    private(set) var imageCache: [Int: UIImage] = [:]

    init() {
        guard
            let fileURL = Bundle.main.url(forResource: "cartoons", withExtension: "json"),
            let data = try? Data(contentsOf: fileURL),
            let decoded = try? JSONDecoder().decode([Cartoon].self, from: data)
        else {
            cartoons = []
            return
        }
        cartoons = decoded.sorted { $0.week < $1.week }

        let toLoad = decoded.filter(\.hasData)
        Task.detached(priority: .userInitiated) {
            var cache: [Int: UIImage] = [:]
            await withTaskGroup(of: (Int, UIImage?).self) { group in
                for cartoon in toLoad {
                    group.addTask {
                        (cartoon.week, cartoon.loadBundledImage())
                    }
                }
                for await (week, image) in group {
                    if let image { cache[week] = image }
                }
            }
            await MainActor.run { self.imageCache = cache }
        }
    }

    var knownCount: Int { cartoons.filter(\.hasData).count }
}
