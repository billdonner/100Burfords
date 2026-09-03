import SwiftUI
import UIKit
import OSLog

private let logger = Logger(subsystem: "com.billdonner.burfords", category: "PrintExport")

extension PrintService {
    /// Lay `image` on a US Letter page exactly as the AirPrint photo job
    /// would: landscape for wide images, half-inch margins, scaled to fit,
    /// centered. Returns the PDF bytes so callers can print, share, or test.
    static func letterPDF(for image: UIImage, jobName: String) -> Data {
        let landscape = image.size.width >= image.size.height
        let page = landscape ? CGRect(x: 0, y: 0, width: 792, height: 612)
                             : CGRect(x: 0, y: 0, width: 612, height: 792)
        let margin: CGFloat = 36
        let printable = page.insetBy(dx: margin, dy: margin)
        let scale = min(printable.width / image.size.width, printable.height / image.size.height)
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let origin = CGPoint(x: printable.midX - size.width / 2, y: printable.midY - size.height / 2)

        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = [
            kCGPDFContextTitle as String: jobName,
            kCGPDFContextCreator as String: "100 Burfords",
        ]
        return UIGraphicsPDFRenderer(bounds: page, format: format).pdfData { ctx in
            ctx.beginPage()
            image.draw(in: CGRect(origin: origin, size: size))
        }
    }
}

/// Test hook: launch with `--export-print-pdfs` and every print job the app
/// can produce (each cartoon, the Fan Club card, a re-captioned panel) is
/// written as a PDF to Documents/PrintExport, alongside a manifest. Lets a
/// reviewer check the print pipeline against the original artwork without
/// a printer.
enum PrintExport {
    static let argument = "--export-print-pdfs"

    @MainActor
    static func runIfRequested(store: CartoonStore) {
        guard ProcessInfo.processInfo.arguments.contains(argument) else { return }
        let dir = URL.documentsDirectory.appending(path: "PrintExport")
        try? FileManager.default.removeItem(at: dir)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        var manifest: [[String: Any]] = []
        func write(_ image: UIImage?, name: String, jobName: String, source: String) {
            guard let image else { logger.error("No image for \(name)"); return }
            let data = PrintService.letterPDF(for: image, jobName: jobName)
            let url = dir.appending(path: "\(name).pdf")
            do { try data.write(to: url) } catch { logger.error("Write failed \(name): \(error.localizedDescription)"); return }
            manifest.append(["file": "\(name).pdf", "job": jobName, "source": source,
                             "imageWidth": Int(image.size.width * image.scale),
                             "imageHeight": Int(image.size.height * image.scale),
                             "bytes": data.count])
        }

        for cartoon in store.cartoons where cartoon.hasData {
            write(cartoon.loadBundledImage(), name: cartoon.localImageName,
                  jobName: cartoon.title ?? "Burford Week \(cartoon.week)",
                  source: "CartoonImages/\(cartoon.localImageName).jpg")
        }

        let card = FanClubCardCanvas(name: "Ada Lovelace").frame(width: 1125, height: 675)
        write(renderToImage(card, scale: 2), name: "fan_club_card",
              jobName: "Burford Fan Club Card", source: "Assets/BurfordFanClubCard")

        if let sample = store.cartoons.last(where: \.hasData), let image = sample.loadBundledImage() {
            let panel = RecaptionedPanel(image: image, caption: "Print test caption — week \(sample.week)",
                                         style: .classic, textSize: .medium, width: 600)
            write(renderToImage(panel), name: "recaption_week_\(sample.week)",
                  jobName: sample.title ?? "Burford Week \(sample.week)",
                  source: "CartoonImages/\(sample.localImageName).jpg + caption strip")
        }

        if let json = try? JSONSerialization.data(withJSONObject: manifest, options: [.prettyPrinted, .sortedKeys]) {
            try? json.write(to: dir.appending(path: "manifest.json"))
        }
        logger.info("PrintExport wrote \(manifest.count) PDFs to \(dir.path)")
        print("🖨️ PrintExport wrote \(manifest.count) PDFs to \(dir.path)")
    }
}
