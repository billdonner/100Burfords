import SwiftUI

/// The composited card: artwork + the member's name written on the
/// signature line. Layout is fully fractional so it renders identically
/// on screen and through `ImageRenderer` at print resolution.
struct FanClubCardCanvas: View {
    let name: String

    // Signature-line placement, as fractions of the card. The line sits
    // above "MEMBER IN GOOD STANDING"; the name rests just on top of it.
    private static let aspect: CGFloat = 1125.0 / 675.0
    private static let nameCenter = CGPoint(x: 0.497, y: 0.545)
    private static let nameWidthFraction: CGFloat = 0.52

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                Image("BurfordFanClubCard")
                    .resizable()
                    .aspectRatio(contentMode: .fit)

                if !name.isEmpty {
                    Text(name)
                        .font(.custom("Snell Roundhand", size: h * 0.085).weight(.bold))
                        .foregroundStyle(.black)
                        .lineLimit(1)
                        .minimumScaleFactor(0.4)
                        .frame(width: w * Self.nameWidthFraction)
                        .position(x: w * Self.nameCenter.x, y: h * Self.nameCenter.y)
                }
            }
        }
        .aspectRatio(Self.aspect, contentMode: .fit)
    }
}

struct FanClubCardView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var printImage: UIImage?
    @FocusState private var nameFocused: Bool

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    FanClubCardCanvas(name: trimmedName)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: .black.opacity(0.18), radius: 6, y: 3)
                        .padding(.horizontal)
                        .padding(.top, 8)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("YOUR NAME")
                            .font(.caption2.bold())
                            .foregroundStyle(.secondary)
                            .tracking(1)
                        TextField("Sign the card", text: $name)
                            .textInputAutocapitalization(.words)
                            .submitLabel(.done)
                            .focused($nameFocused)
                            .padding(12)
                            .background(Color.secondary.opacity(0.10))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .padding(.horizontal)

                    Button {
                        nameFocused = false
                        printImage = renderCard()
                    } label: {
                        Label("Print or Share Card", systemImage: "printer")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(brandOrange)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal)

                    Text("Standard business-card stock prints at 3.5″ × 2″.\nFits a standard photo print too.")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 8)
                }
            }
            .background(paperColor)
            .navigationTitle("Fan Club Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(item: $printImage) { image in
                PrintOptionsSheet(image: image, jobName: "Burford Fan Club Card")
            }
        }
    }

    @MainActor
    private func renderCard() -> UIImage? {
        let canvas = FanClubCardCanvas(name: trimmedName)
            .frame(width: 1125, height: 675)
        return renderToImage(canvas, scale: 2)
    }
}

/// Lets `UIImage` drive a `.sheet(item:)`.
extension UIImage: @retroactive Identifiable {
    public var id: Int { hash }
}
