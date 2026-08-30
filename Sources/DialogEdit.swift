import Foundation
import UIKit
import Vision

/// One rewritable dialog region in a panel. `rect` is normalized to the
/// image (top-left origin). `original` is what Vision read there; `text` is
/// the reader's replacement — empty means the art is left untouched.
struct BubbleOverride: Codable, Identifiable, Equatable {
    var id = UUID()
    var x: Double
    var y: Double
    var w: Double
    var h: Double
    var original: String
    var text: String = ""

    var rect: CGRect { CGRect(x: x, y: y, width: w, height: h) }
    var center: CGPoint { CGPoint(x: x + w / 2, y: y + h / 2) }
}

enum DialogDetector {
    /// Find the text blocks in a panel. Vision returns one box per line;
    /// nearby lines are merged into blocks so a multi-line speech balloon
    /// edits as one unit. Blocks come back top-to-bottom.
    static func detect(in image: UIImage) async -> [BubbleOverride] {
        guard let cg = image.cgImage else { return [] }
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = false
        let handler = VNImageRequestHandler(cgImage: cg, orientation: .up)
        let observations: [VNRecognizedTextObservation] = await Task.detached(priority: .userInitiated) {
            try? handler.perform([request])
            return request.results ?? []
        }.value

        // Convert to top-left-origin normalized rects with their text
        struct Line { var rect: CGRect; var text: String }
        var lines: [Line] = []
        for obs in observations {
            guard let candidate = obs.topCandidates(1).first,
                  candidate.string.trimmingCharacters(in: .whitespaces).count >= 2 else { continue }
            let b = obs.boundingBox
            lines.append(Line(rect: CGRect(x: b.minX, y: 1 - b.maxY, width: b.width, height: b.height),
                              text: candidate.string))
        }
        lines.sort { $0.rect.minY < $1.rect.minY }

        // Merge lines whose expanded boxes touch into blocks
        struct Block { var rect: CGRect; var texts: [String] }
        var blocks: [Block] = []
        for line in lines {
            let probe = line.rect.insetBy(dx: -line.rect.height * 0.6, dy: -line.rect.height * 0.6)
            if let i = blocks.firstIndex(where: { $0.rect.intersects(probe) }) {
                blocks[i].rect = blocks[i].rect.union(line.rect)
                blocks[i].texts.append(line.text)
            } else {
                blocks.append(Block(rect: line.rect, texts: [line.text]))
            }
        }

        return blocks.map {
            BubbleOverride(x: $0.rect.minX, y: $0.rect.minY,
                           w: $0.rect.width, h: $0.rect.height,
                           original: $0.texts.joined(separator: " "))
        }
    }
}

extension UIImage {
    /// Bake non-empty dialog rewrites into the artwork: each region is
    /// covered with its sampled background color, then the replacement text
    /// is typeset into the same spot in the chosen caption style.
    func applyingDialogOverrides(_ overrides: [BubbleOverride], style: CaptionStyle) -> UIImage {
        let active = overrides.filter { !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        guard !active.isEmpty else { return self }

        let fmt = UIGraphicsImageRendererFormat()
        fmt.scale = scale
        return UIGraphicsImageRenderer(size: size, format: fmt).image { _ in
            draw(at: .zero)
            for ov in active {
                let pad = ov.h * Double(size.height) * 0.18
                let r = CGRect(x: ov.x * size.width, y: ov.y * size.height,
                               w: ov.w * size.width, h: ov.h * size.height)
                    .insetBy(dx: -pad, dy: -pad)
                    .intersection(CGRect(origin: .zero, size: size))
                let bg = sampledBackgroundColor(in: r)
                bg.setFill()
                UIBezierPath(roundedRect: r, cornerRadius: r.height * 0.15).fill()
                drawFitted(text: ov.text, in: r.insetBy(dx: r.width * 0.02, dy: 0), style: style)
            }
        }
    }

    /// The dominant light color in a region — a speech balloon's white, a
    /// game tile's tan — found by averaging the brightest half of a
    /// downsampled crop (the dark half is the lettering being replaced).
    private func sampledBackgroundColor(in rect: CGRect) -> UIColor {
        guard let cg = cgImage else { return .white }
        let px = CGRect(x: rect.minX * CGFloat(cg.width) / size.width,
                        y: rect.minY * CGFloat(cg.height) / size.height,
                        width: rect.width * CGFloat(cg.width) / size.width,
                        height: rect.height * CGFloat(cg.height) / size.height)
        guard let crop = cg.cropping(to: px) else { return .white }

        let side = 24
        guard let ctx = CGContext(data: nil, width: side, height: side, bitsPerComponent: 8,
                                  bytesPerRow: side * 4, space: CGColorSpaceCreateDeviceRGB(),
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        else { return .white }
        ctx.interpolationQuality = .low
        ctx.draw(crop, in: CGRect(x: 0, y: 0, width: side, height: side))
        guard let data = ctx.data else { return .white }
        let buf = data.bindMemory(to: UInt8.self, capacity: side * side * 4)

        var pixels: [(lum: Int, r: Int, g: Int, b: Int)] = []
        for i in stride(from: 0, to: side * side * 4, by: 4) {
            let r = Int(buf[i]), g = Int(buf[i + 1]), b = Int(buf[i + 2])
            pixels.append((r + r + g + g + g + b, r, g, b))
        }
        pixels.sort { $0.lum > $1.lum }
        let top = pixels.prefix(max(1, pixels.count / 2))
        let n = CGFloat(top.count)
        return UIColor(red: CGFloat(top.reduce(0) { $0 + $1.r }) / n / 255,
                       green: CGFloat(top.reduce(0) { $0 + $1.g }) / n / 255,
                       blue: CGFloat(top.reduce(0) { $0 + $1.b }) / n / 255, alpha: 1)
    }

    /// Typeset text centered in a rect, shrinking until it fits.
    private func drawFitted(text: String, in rect: CGRect, style: CaptionStyle) {
        let para = NSMutableParagraphStyle()
        para.alignment = .center
        para.lineBreakMode = .byWordWrapping

        var fontSize = rect.height * 0.9
        let minSize = max(4, size.height * 0.008)
        var attrs: [NSAttributedString.Key: Any] = [:]
        var bounds = CGRect.zero
        while fontSize > minSize {
            attrs = [.font: style.uiFont(size: fontSize), .paragraphStyle: para,
                     .foregroundColor: UIColor.black]
            bounds = (text as NSString).boundingRect(
                with: CGSize(width: rect.width, height: .greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin], attributes: attrs, context: nil)
            if bounds.width <= rect.width && bounds.height <= rect.height { break }
            fontSize *= 0.92
        }
        let origin = CGPoint(x: rect.minX, y: rect.midY - bounds.height / 2)
        (text as NSString).draw(in: CGRect(origin: origin, size: CGSize(width: rect.width, height: bounds.height)),
                                withAttributes: attrs)
    }
}

private extension CGRect {
    init(x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat) {
        self.init(x: x, y: y, width: w, height: h)
    }
}

extension CaptionStyle {
    /// UIKit twin of `font(size:)` for CoreGraphics text drawing.
    func uiFont(size: CGFloat) -> UIFont {
        switch self {
        case .classic:
            let base = UIFont.systemFont(ofSize: size)
            if let d = base.fontDescriptor.withDesign(.serif)?
                .withSymbolicTraits(.traitItalic) {
                return UIFont(descriptor: d, size: size)
            }
            return base
        case .marker:
            return UIFont(name: "MarkerFelt-Wide", size: size) ?? .boldSystemFont(ofSize: size)
        case .typewriter:
            return UIFont(name: "AmericanTypewriter", size: size) ?? .systemFont(ofSize: size)
        case .bold:
            let base = UIFont.systemFont(ofSize: size, weight: .heavy)
            if let d = base.fontDescriptor.withDesign(.rounded) {
                return UIFont(descriptor: d, size: size)
            }
            return base
        }
    }
}
