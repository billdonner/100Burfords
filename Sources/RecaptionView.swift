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

    /// Derived from `uiFont(size:)` (DialogEdit.swift) — the single source of
    /// truth for each style's typeface, so preview and baked output always
    /// use the same font.
    func font(size: CGFloat) -> Font {
        Font(uiFont(size: size) as CTFont)
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

            if !caption.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(caption)
                    .font(style.font(size: width / 22 * textSize.multiplier))
                    .foregroundStyle(.black)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, width / 14)
                    .padding(.top, width / 34)
            }

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

/// Per-week persistence for reader captions. One JSON dict in UserDefaults
/// keyed by week number; an empty caption removes the entry.
enum CaptionArchive {
    struct Saved: Codable {
        var text: String
        var style: CaptionStyle.RawValue
        var size: CaptionTextSize.RawValue
        var bubbles: [BubbleOverride]? // only rewritten dialog regions
    }

    private static let key = "recaptions.v1"

    static func reset() { UserDefaults.standard.removeObject(forKey: key) }

    private static func all() -> [Int: Saved] {
        guard let data = UserDefaults.standard.data(forKey: key) else { return [:] }
        return (try? JSONDecoder().decode([Int: Saved].self, from: data)) ?? [:]
    }

    static func load(week: Int) -> Saved? { all()[week] }

    /// Pass `bubbles: nil` to preserve whatever rewrites are already saved —
    /// used while detection is still running, so an early caption edit can't
    /// wipe the stored dialog rewrites.
    static func save(week: Int, text: String, style: CaptionStyle, size: CaptionTextSize,
                     bubbles: [BubbleOverride]?) {
        var dict = all()
        let rewritten = (bubbles ?? dict[week]?.bubbles ?? [])
            .filter { !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && rewritten.isEmpty {
            dict[week] = nil
        } else {
            dict[week] = Saved(text: text, style: style.rawValue, size: size.rawValue,
                               bubbles: rewritten.isEmpty ? nil : rewritten)
        }
        if let data = try? JSONEncoder().encode(dict) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}

/// Write your own caption for a panel, pick a style, then print or share the
/// result through the shared `PrintOptionsSheet`. The caption and its style
/// persist per panel, so it's there when you come back.
struct RecaptionView: View {
    let cartoon: Cartoon
    let image: UIImage
    @Environment(\.dismiss) private var dismiss
    @State private var caption: String
    @State private var style: CaptionStyle
    @State private var textSize: CaptionTextSize
    @State private var composedImage: UIImage?
    @State private var bubbles: [BubbleOverride] = []
    @State private var bubblesLoaded = false
    @State private var editedImage: UIImage?
    @State private var renderTask: Task<Void, Never>?
    @State private var persistTask: Task<Void, Never>?
    @FocusState private var captionFocused: Bool

    /// The artwork with any dialog rewrites baked in.
    private var panelImage: UIImage { editedImage ?? image }

    init(cartoon: Cartoon, image: UIImage) {
        self.cartoon = cartoon
        self.image = image
        let saved = CaptionArchive.load(week: cartoon.week)
        _caption = State(initialValue: saved?.text ?? "")
        _style = State(initialValue: saved.flatMap { CaptionStyle(rawValue: $0.style) } ?? .classic)
        _textSize = State(initialValue: saved.flatMap { CaptionTextSize(rawValue: $0.size) } ?? .medium)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    RecaptionedPanel(image: panelImage, caption: caption,
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

                    if !bubbles.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("REWRITE THE DIALOG")
                                .font(.caption2.bold()).foregroundStyle(.secondary).tracking(1)
                            Text("Leave a line blank to keep the original.")
                                .font(.caption2).foregroundStyle(.tertiary)
                            ForEach($bubbles) { $bubble in
                                TextField(bubble.original, text: $bubble.text, axis: .vertical)
                                    .lineLimit(1...3)
                                    .padding(10)
                                    .background(Color.secondary.opacity(
                                        bubble.text.isEmpty ? 0.06 : 0.14))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        }
                    }

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
                        // Bake from current state, not the (possibly stale)
                        // debounced preview image.
                        let baked = image.applyingDialogOverrides(bubbles, style: style)
                        composedImage = renderToImage(
                            RecaptionedPanel(image: baked, caption: caption,
                                             style: style, textSize: textSize,
                                             width: 600))
                    } label: {
                        Label("Print or Share", systemImage: "square.and.arrow.up")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                            .background(canCompose ? brandOrange : Color.secondary.opacity(0.3))
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    // Held until the rewritten artwork actually exists — see
                    // `canCompose`. `bubblesLoaded` alone is not enough.
                    .disabled(!canCompose)
                }
                .padding()
            }
            .background(paperColor)
            .onChange(of: caption) { schedulePersist() }
            .onChange(of: style) { schedulePersist(); rebuildEditedImage() }
            .onChange(of: textSize) { schedulePersist() }
            .onChange(of: bubbles) { schedulePersist(); rebuildEditedImage() }
            .onDisappear { persistTask?.cancel(); persist() }
            .task { await loadBubbles() }
            .navigationTitle("Re-Caption This Panel")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(item: $composedImage) { composed in
                PrintOptionsSheet(image: composed,
                                  jobName: cartoon.title ?? "Burford Week \(cartoon.week)")
            }
        }
    }

    /// Debounced: one archive write per typing pause instead of one per
    /// keystroke. `onDisappear` flushes immediately, so nothing is lost.
    private func schedulePersist() {
        persistTask?.cancel()
        persistTask = Task {
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }
            persist()
        }
    }

    /// Whether Print/Share can compose what the reader will actually get.
    ///
    /// `bubblesLoaded` is not sufficient: `loadBubbles()` sets it and *then*
    /// calls `rebuildEditedImage()`, which debounces 250ms and renders off the
    /// main thread. In that window `panelImage` is still `image` — the
    /// original — so a tap composes and shares the panel with the reader's
    /// saved dialog rewrites missing. Waiting for `editedImage` closes it;
    /// the render always assigns, even when there are no overrides, so this
    /// cannot hang on a panel that has none.
    private var canCompose: Bool { bubblesLoaded && editedImage != nil }

    private func persist() {
        CaptionArchive.save(week: cartoon.week, text: caption, style: style, size: textSize,
                            bubbles: bubblesLoaded ? bubbles : nil)
    }

    /// Detect the panel's dialog regions, then fold in any saved rewrites —
    /// matched by position, so a saved edit survives even if detection order
    /// shifts. A saved rewrite with no matching region gets its own row.
    private func loadBubbles() async {
        guard bubbles.isEmpty else { return }
        var detected = await DialogDetector.detect(in: image)
        if let saved = CaptionArchive.load(week: cartoon.week)?.bubbles {
            for sv in saved {
                if let i = detected.firstIndex(where: {
                    abs($0.center.x - sv.center.x) < 0.05 && abs($0.center.y - sv.center.y) < 0.05
                }) {
                    detected[i].text = sv.text
                } else {
                    detected.append(sv)
                }
            }
        }
        bubbles = detected
        bubblesLoaded = true
        rebuildEditedImage()
    }

    /// Cancel-and-replace with a short debounce: only the latest edit
    /// renders, and a superseded render can never clobber a newer preview.
    private func rebuildEditedImage() {
        renderTask?.cancel()
        let base = image, overrides = bubbles, s = style
        renderTask = Task {
            try? await Task.sleep(for: .milliseconds(250))
            guard !Task.isCancelled else { return }
            let result = await Task.detached(priority: .userInitiated) {
                base.applyingDialogOverrides(overrides, style: s)
            }.value
            guard !Task.isCancelled else { return }
            editedImage = result
        }
    }

    private var previewWidth: CGFloat {
        min(UIScreen.main.bounds.width - 32, 500)
    }
}
