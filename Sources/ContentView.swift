import SwiftUI

let paperColor = Color(red: 0.98, green: 0.955, blue: 0.88)
let brandOrange = Color(red: 0.85, green: 0.42, blue: 0.10)

struct ContentView: View {
    @State private var store = CartoonStore()
    @State private var showBook = false

    let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    headerView
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(store.cartoons) { cartoon in
                            if cartoon.hasData {
                                NavigationLink(destination: CartoonDetailView(cartoon: cartoon)
                                    .environment(store)) {
                                    CartoonCard(cartoon: cartoon, store: store)
                                }
                                .buttonStyle(.plain)
                            } else {
                                MissingCard(cartoon: cartoon)
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 32)
                }
            }
            .background(paperColor)
            .navigationBarHidden(true)
        }
        .fullScreenCover(isPresented: $showBook) {
            BookView(startWeek: 1)
                .environment(store)
        }
    }

    var headerView: some View {
        VStack(spacing: 6) {
            Text("100Burfords")
                .font(.system(size: 34, weight: .black, design: .serif))
                .tracking(1)
                .foregroundStyle(brandOrange)
            Text("Martoonerville by Gary R. Martin")
                .font(.system(.subheadline, design: .serif))
                .foregroundStyle(.secondary)
            Text("West Side Rag  •  \(store.knownCount) of 100 cartoons")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .padding(.bottom, 4)

            Button {
                showBook = true
            } label: {
                Label("Read Like a Book", systemImage: "book.pages")
                    .font(.caption.bold())
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(brandOrange)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
            .padding(.bottom, 4)

            Divider()
        }
        .padding(.top, 20)
        .padding(.bottom, 12)
        .padding(.horizontal)
    }
}

struct CartoonCard: View {
    let cartoon: Cartoon
    let store: CartoonStore

    var cachedImage: UIImage? { store.imageCache[cartoon.week] ?? cartoon.loadBundledImage() }

    var body: some View {
        ZStack(alignment: .bottom) {
            cartoonImage
            cardOverlay
        }
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.black.opacity(0.08), lineWidth: 0.5)
        )
    }

    @ViewBuilder
    var cartoonImage: some View {
        if let uiImage = cachedImage {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(minHeight: 150)
                .clipped()
        } else {
            AsyncImage(url: cartoon.thumbnailURL) { phase in
                switch phase {
                case .success(let img):
                    img.resizable().aspectRatio(contentMode: .fill)
                case .failure:
                    grayPlaceholder
                        .overlay(Image(systemName: "photo").foregroundStyle(.secondary))
                default:
                    grayPlaceholder
                        .overlay(ProgressView().tint(.secondary))
                }
            }
            .frame(minHeight: 150)
            .clipped()
        }
    }

    var cardOverlay: some View {
        VStack(alignment: .leading, spacing: 2) {
            if let title = cartoon.title {
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
            }
            HStack {
                Text("#\(cartoon.week)")
                    .font(.caption2.bold())
                    .foregroundStyle(brandOrange)
                Spacer()
                if let count = cartoon.commentCount, count > 0 {
                    Label("\(count)", systemImage: "bubble.right")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial)
    }

    var grayPlaceholder: some View {
        Color.gray.opacity(0.12).frame(minHeight: 150)
    }
}

struct MissingCard: View {
    let cartoon: Cartoon

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.gray.opacity(0.07))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [4]))
                        .foregroundStyle(Color.gray.opacity(0.25))
                )
            VStack(spacing: 6) {
                Image(systemName: "newspaper")
                    .font(.title)
                    .foregroundStyle(Color.gray.opacity(0.28))
                Text("Week \(cartoon.week)")
                    .font(.caption.bold())
                    .foregroundStyle(Color.gray.opacity(0.45))
                Text(cartoon.displayDate)
                    .font(.caption2)
                    .foregroundStyle(Color.gray.opacity(0.38))
                Text("skipped")
                    .font(.caption2.italic())
                    .foregroundStyle(Color.gray.opacity(0.35))
            }
        }
        .frame(minHeight: 150)
    }
}
