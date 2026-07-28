import SwiftUI
import UIKit
import OSLog

private let logger = Logger(subsystem: "com.billdonner.burfords", category: "Print")

/// A place a print job can be sent. AirPrint ships today; a mail-order
/// fulfillment provider (Printful/Prodigi/etc.) slots in here later behind
/// the same `PrintOptionsSheet` entry point — add a case, give it
/// `isAvailable` and a handler, and it appears in the menu automatically.
enum PrintDestination: String, CaseIterable, Identifiable {
    case airPrint
    case mailOrder

    var id: String { rawValue }

    var title: String {
        switch self {
        case .airPrint: return "Print"
        case .mailOrder: return "Order Prints by Mail"
        }
    }

    var subtitle: String {
        switch self {
        case .airPrint: return "Send to any AirPrint printer nearby"
        case .mailOrder: return "Coming soon"
        }
    }

    var systemImage: String {
        switch self {
        case .airPrint: return "printer"
        case .mailOrder: return "shippingbox"
        }
    }

    /// Only AirPrint is wired up today. Flip this on for a provider once its
    /// account / API / payment flow lands.
    var isAvailable: Bool { self == .airPrint }
}

enum PrintService {
    /// Present the system AirPrint sheet for a single image.
    @MainActor
    static func airPrint(_ image: UIImage, jobName: String) {
        let info = UIPrintInfo(dictionary: nil)
        info.jobName = jobName
        info.outputType = .photo
        info.orientation = image.size.width >= image.size.height ? .landscape : .portrait

        let controller = UIPrintInteractionController.shared
        controller.printInfo = info
        controller.printingItem = image
        controller.present(animated: true) { _, completed, error in
            if let error { logger.error("AirPrint failed: \(error.localizedDescription)") }
            else { logger.info("AirPrint \(completed ? "completed" : "cancelled") for \(jobName)") }
        }
    }
}

/// Renders a SwiftUI view to a high-resolution `UIImage` so what the user
/// sees on screen is exactly what prints (and shares).
@MainActor
func renderToImage<V: View>(_ view: V, scale: CGFloat = 3) -> UIImage? {
    let renderer = ImageRenderer(content: view)
    renderer.scale = scale
    renderer.isOpaque = true
    return renderer.uiImage
}

/// Reusable "how do you want this?" sheet. Used for cartoons and the Fan
/// Club card alike — hand it a finished `UIImage` and a job name.
struct PrintOptionsSheet: View {
    let image: UIImage
    let jobName: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
                    .padding(.top, 8)

                VStack(spacing: 12) {
                    ForEach(PrintDestination.allCases) { destination in
                        destinationRow(destination)
                    }

                    ShareLink(
                        item: Image(uiImage: image),
                        preview: SharePreview(jobName, image: Image(uiImage: image))
                    ) {
                        rowLabel(title: "Share", subtitle: "Save, message, or send to a print app",
                                 systemImage: "square.and.arrow.up", enabled: true)
                    }
                }

                Spacer()
            }
            .padding()
            .background(paperColor)
            .navigationTitle(jobName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    @ViewBuilder
    private func destinationRow(_ destination: PrintDestination) -> some View {
        Button {
            switch destination {
            case .airPrint:
                dismiss()
                PrintService.airPrint(image, jobName: jobName)
            case .mailOrder:
                break // not yet available
            }
        } label: {
            rowLabel(title: destination.title, subtitle: destination.subtitle,
                     systemImage: destination.systemImage, enabled: destination.isAvailable)
        }
        .disabled(!destination.isAvailable)
    }

    private func rowLabel(title: String, subtitle: String, systemImage: String, enabled: Bool) -> some View {
        HStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.title2)
                .frame(width: 32)
                .foregroundStyle(enabled ? brandOrange : Color.secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .foregroundStyle(enabled ? Color.primary : Color.secondary)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.secondary.opacity(enabled ? 0.10 : 0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
