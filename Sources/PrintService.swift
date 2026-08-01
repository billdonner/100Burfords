import SwiftUI
import UIKit
import OSLog

private let logger = Logger(subsystem: "com.billdonner.burfords", category: "Print")

/// A place a print job can be sent. AirPrint ships today; a mail-order
/// fulfillment provider (Printful/Prodigi/etc.) slots in here later behind
/// the same `PrintOptionsSheet` entry point — add a case, give it
/// `isAvailable` and a handler, and it appears in the menu automatically.
enum PrintDestination {
    case airPrint
    case mailOrder

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

/// A third-party print shop the user can order a physical card from. Today
/// this is a hand-off (save the image, open the partner's site); once a
/// fulfillment API (e.g. InstantCard, Prodigi) is wired up, an `apiOrder`
/// closure slots in alongside `url` behind the same row.
struct PrintPartner: Identifiable {
    let id = UUID()
    let name: String
    let detail: String
    let url: URL
}

/// Everything the mail-order hand-off needs. Nil means "not offered here"
/// (e.g. cartoons), and the row shows a disabled "Coming soon".
struct MailOrderOptions {
    let blurb: String
    let partners: [PrintPartner]

    /// Ready-made options for the Fan Club membership card.
    static let fanClubCard = MailOrderOptions(
        blurb: "Order a real membership card, mailed to you. Save your card image below, then pick a print partner and upload it. These are independent print shops — you order and pay directly on their site.",
        partners: [
            PrintPartner(
                name: "IDCards.com — Plastic PVC",
                detail: "Rigid laminated plastic card · order just one · ~$15",
                url: URL(string: "https://idcards.com/small-batch-custom-pvc-cards/")!),
            PrintPartner(
                name: "UPrinting — Silk Laminated",
                detail: "16pt soft-touch laminated stock · from 25 cards",
                url: URL(string: "https://www.uprinting.com/silk-business-cards.html")!),
            PrintPartner(
                name: "MOO — Super Soft-Touch",
                detail: "Thick 18pt velvety laminate · from 50 cards",
                url: URL(string: "https://www.moo.com/us/business-cards/super")!),
        ]
    )
}

/// Reusable "how do you want this?" sheet. Used for cartoons and the Fan
/// Club card alike — hand it a finished `UIImage` and a job name. Pass
/// `mailOrder` to light up the "Order by Mail" hand-off.
struct PrintOptionsSheet: View {
    let image: UIImage
    let jobName: String
    var mailOrder: MailOrderOptions? = nil
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
                    Button {
                        dismiss()
                        PrintService.airPrint(image, jobName: jobName)
                    } label: {
                        rowLabel(title: PrintDestination.airPrint.title,
                                 subtitle: PrintDestination.airPrint.subtitle,
                                 systemImage: PrintDestination.airPrint.systemImage, enabled: true)
                    }

                    if let mailOrder {
                        NavigationLink {
                            MailOrderView(image: image, jobName: jobName, options: mailOrder)
                        } label: {
                            rowLabel(title: PrintDestination.mailOrder.title,
                                     subtitle: "Laminated & plastic cards, shipped to you",
                                     systemImage: PrintDestination.mailOrder.systemImage,
                                     enabled: true, showsChevron: true)
                        }
                    } else {
                        rowLabel(title: PrintDestination.mailOrder.title,
                                 subtitle: PrintDestination.mailOrder.subtitle,
                                 systemImage: PrintDestination.mailOrder.systemImage, enabled: false)
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
}

/// The mail-order hand-off: preview, "save the image" affordance, and the
/// list of print partners to open.
struct MailOrderView: View {
    let image: UIImage
    let jobName: String
    let options: MailOrderOptions
    @Environment(\.openURL) private var openURL

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
                    .padding(.top, 8)

                Text(options.blurb)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                ShareLink(
                    item: Image(uiImage: image),
                    preview: SharePreview(jobName, image: Image(uiImage: image))
                ) {
                    Label("Save Card Image", systemImage: "square.and.arrow.down")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(brandOrange)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("PRINT PARTNERS")
                        .font(.caption2.bold()).foregroundStyle(.secondary).tracking(1)
                    ForEach(options.partners) { partner in
                        Button { openURL(partner.url) } label: {
                            rowLabel(title: partner.name, subtitle: partner.detail,
                                     systemImage: "arrow.up.forward.square", enabled: true,
                                     showsChevron: true)
                        }
                    }
                }

                Text("Print partners are independent companies. 100Burfords isn't affiliated with them and doesn't process your order or payment.")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .padding(.top, 4)
            }
            .padding()
        }
        .background(paperColor)
        .navigationTitle("Order by Mail")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// Shared row used across the print sheet and mail-order list.
@ViewBuilder
private func rowLabel(title: String, subtitle: String, systemImage: String,
                      enabled: Bool, showsChevron: Bool = false) -> some View {
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
        if showsChevron {
            Image(systemName: "chevron.right").font(.caption.bold()).foregroundStyle(.tertiary)
        }
    }
    .foregroundStyle(enabled ? Color.primary : Color.secondary)
    .padding(.horizontal, 14)
    .padding(.vertical, 12)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Color.secondary.opacity(enabled ? 0.10 : 0.05))
    .clipShape(RoundedRectangle(cornerRadius: 12))
}
