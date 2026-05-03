import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    heroSection
                    Divider()
                    historySection
                    Divider()
                    creditsSection
                    Divider()
                    provenanceSection
                    Divider()
                    legalSection
                }
                .padding()
                .padding(.bottom, 32)
            }
            .background(paperColor)
            .navigationTitle("About 100 Burfords")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    var heroSection: some View {
        VStack(spacing: 10) {
            Image("LaunchBurford")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: 200)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(radius: 8, y: 4)
                .frame(maxWidth: .infinity)

            Text("100 Burfords")
                .font(.system(size: 30, weight: .black, design: .serif))
                .tracking(1)
                .foregroundStyle(brandOrange)
                .frame(maxWidth: .infinity)

            Text("Martoonerville by Gary R. Martin")
                .font(.system(.subheadline, design: .serif).italic())
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
    }

    var historySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "The Story", icon: "book.closed")

            Text("""
                It started with a single cartoon and a name tag: "Hello, I'm doing the best I can."

                Every week since June 2024, Gary R. Martin has published a new Burford in the West Side Rag — New York City's beloved neighborhood newspaper covering the Upper West Side. The Burfords are the salt of the earth, ordinary New Yorkers captured with affection, wit, and the kind of gentle humanity that makes you smile on the subway.

                One hundred strips. One hundred Burfords. A love letter to a neighborhood and its people.
                """)
                .font(.callout)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    var creditsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Credits & Tribute", icon: "star.fill")

            VStack(alignment: .leading, spacing: 12) {
                CreditRow(name: "Gary R. Martin", role: "Creator, Cartoonist", detail: "www.martoons.com")
                CreditRow(name: "West Side Rag", role: "Publisher", detail: "westsiderag.com")
                CreditRow(name: "The Burfords", role: "Stars", detail: "Upper West Side, NYC")
                CreditRow(name: "WSR Readers", role: "The Community", detail: "2,787+ comments and counting")
            }

            Text("This app is an unofficial fan tribute. All cartoons are © Gary R. Martin, published with appreciation and respect for his remarkable body of work.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 4)
        }
    }

    var provenanceSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Provenance", icon: "newspaper")

            Text("""
                The cartoons in this collection were published weekly in the West Side Rag beginning in June 2024. Gary Martin, a long-time Upper West Side cartoonist and the creator of Martoonerville, conceived the Burfords as an ongoing portrait of the neighborhood's residents — each strip a miniature character study, named "Burford" as an everyman stand-in for all of us.

                The reader comments included in this app were gathered from the West Side Rag's website, where each cartoon generates a lively conversation among devoted readers who see themselves — and their neighbors — in every panel.
                """)
                .font(.callout)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    var legalSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "Legal & Copyright", icon: "c.circle")

            Text("All cartoon artwork © Gary R. Martin. Published by West Side Rag, New York City. This app is an unofficial tribute and is not affiliated with or endorsed by Gary R. Martin or the West Side Rag.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
            let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
            Text("App version \(version) (\(build))")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .padding(.top, 4)
        }
    }
}

private struct SectionHeader: View {
    let title: String
    let icon: String

    var body: some View {
        Label(title, systemImage: icon)
            .font(.headline)
            .foregroundStyle(brandOrange)
    }
}

private struct CreditRow: View {
    let name: String
    let role: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(name)
                .font(.callout.bold())
                .foregroundStyle(.primary)
            Text(role)
                .font(.caption)
                .foregroundStyle(brandOrange)
            Text(detail)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}
