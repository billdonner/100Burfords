import Foundation

@Observable
class CartoonStore {
    let cartoons: [Cartoon]

    init() {
        guard
            let fileURL = Bundle.main.url(forResource: "cartoons", withExtension: "json"),
            let data = try? Data(contentsOf: fileURL),
            let decoded = try? JSONDecoder().decode([Cartoon].self, from: data)
        else {
            cartoons = []
            return
        }
        cartoons = decoded.sorted { $0.week > $1.week }
    }

    var knownCount: Int { cartoons.filter(\.hasData).count }
}
