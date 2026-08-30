import SwiftUI
import UIKit

/// The limited menu of caption looks. Each style is a font treatment for the
/// caption strip under the panel — add a case and it appears in the picker.
enum CaptionStyle: String, CaseIterable, Identifiable {
    case classic = "Classic"
    case marker = "Marker"
    case typewriter = "Typewriter"
    case bold = "Bold"

    var id: String { rawValue }

    func font(size: CGFloat) -> Font {
        switch self {
        case .classic: return .system(size: size, design: .serif).italic()
        case .marker: return .custom("MarkerFelt-Wide", size: size)
        case .typewriter: return .custom("AmericanTypewriter", size: size)
        case .bold: return .system(size: size, weight: .heavy, design: .rounded)
        }
    }
}

enum CaptionTextSize: String, CaseIterable, Identifiable {
    case small = "Small"
    case medium = "Medium"
    case large = "Large"

    var id: String { rawValue }

    var multiplier: CGFloat {
        switch self {
        case .small: return 0.8
        case .medium: return 1.0
        case .large: return 1.25
        }
    }
}

/// The finished artwork: panel on top, reader's caption on a white strip
/// below. Rendered both on screen (preview) and via `renderToImage` for
/// print/share, so what you see is exactly what prints.
struct RecaptionedPanel: View {
    let image: UIImage
    let caption: String
    let style: CaptionStyle
    let textSize: CaptionTextSize
    let width: CGFloat

    var body: some View {
        VStack(spacing: 0) {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)

            Text(caption.isEmpty ? " " : caption)
                .font(style.font(size: width / 22 * textSize.multiplier))
                .foregroundStyle(.black)
                .multilineTextAlignment(.center)
                .padding(.horizontal, width / 14)
                .padding(.top, width / 34)

            Text("Panel © Gary B. Martin • Caption by a 100Burfords reader")
                .font(.system(size: width / 52))
                .foregroundStyle(.gray)
                .padding(.top, width / 40)
                .padding(.bottom, width / 34)
        }
        .frame(width: width)
        .background(Color.white)
    }
}

/// Write your own caption for a panel, pick a style, then print or share the
/// result through the shared `PrintOptionsSheet`.
struct RecaptionView: View {
    let cartoon: Cartoon
    let image: UIImage
    @Environment(\.dismiss) private var dismiss
    @State private var caption = ""
    @State private var style: CaptionStyle = .classic
    @State private var textSize: CaptionTextSize = .medium
    @State private var composedImage: UIImage?
    @FocusState private var captionFocused: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    RecaptionedPanel(image: image, caption: caption,
                                     style: style, textSize: textSize,
                                     width: previewWidth)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 8)

                    TextField("Write your caption…", text: $caption, axis: .vertical)
                        .lineLimit(2...4)
                        .focused($captionFocused)
                        .padding(12)
                        .background(Color.secondary.opacity(0.10))
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    VStack(alignment: .leading, spacing: 6) {
                        Text("CAPTION STYLE")
                            .font(.caption2.bold()).foregroundStyle(.secondary).tracking(1)
                        HStack(spacing: 10) {
                            ForEach(CaptionStyle.allCases) { s in
                                Button { style = s } label: {
                                    VStack(spacing: 4) {
                                        Text("Aa").font(s.font(size: 22))
                                        Text(s.rawValue).font(.caption2)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(Color.secondary.opacity(style == s ? 0.22 : 0.08))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .overlay(RoundedRectangle(cornerRadius: 10)
                                        .stroke(style == s ? brandOrange : .clear, lineWidth: 2))
                                }
                                .foregroundStyle(.primary)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("TEXT SIZE")
                            .font(.caption2.bold()).foregroundStyle(.secondary).tracking(1)
                        Picker("Text Size", selection: $textSize) {
                            ForEach(CaptionTextSize.allCases) { Text($0.rawValue).tag($0) }
                        }
                        .pickerStyle(.segmented)
                    }

                    Button {
                        captionFocused = false
                        composedImage = renderToImage(
                            RecaptionedPanel(image: image, caption: caption,
                                             style: style, textSize: textSize,
                                             width: 600))
                    } label: {
                        Label("Print or Share", systemImage: "square.and.arrow.up")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                            .background(caption.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                        ? Color.secondary.opacity(0.3) : brandOrange)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(caption.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding()
            }
            .background(paperColor)
            .navigationTitle("Re-Caption This Panel")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(item: $composedImage) { composed in
                PrintOptionsSheet(image: composed,
                                  jobName: "My Burford Caption — Week \(cartoon.week)")
            }
        }
    }

    private var previewWidth: CGFloat {
        min(UIScreen.main.bounds.width - 32, 500)
    }
}
