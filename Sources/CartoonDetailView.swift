import SwiftUI

struct CartoonDetailView: View {
    let cartoon: Cartoon
    @Environment(CartoonStore.self) var store
    @Environment(\.openURL) var openURL
    @State private var showComments = false
    @State private var showFullScreen = false

    var cachedImage: UIImage? { store.imageCache[cartoon.week] ?? cartoon.loadBundledImage() }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                cartoonImageView
                    .padding(.bottom, 2)

                Text("Tap image for full-screen")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.bottom, 8)

                VStack(alignment: .leading, spacing: 14) {
                    Text(cartoon.title ?? "Week \(cartoon.week)")
                        .font(.title3.bold())

                    HStack(spacing: 16) {
                        Label("Week \(cartoon.week) of 100", systemImage: "number")
                        Label(cartoon.displayDate, systemImage: "calendar")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)

                    if let count = cartoon.commentCount, count > 0 {
                        Button { showComments = true } label: {
                            Label("\(count) reader comments — tap to read", systemImage: "bubble.right")
                                .font(.caption)
                                .foregroundStyle(brandOrange)
                        }
                    }

                    Divider()

                    if let url = cartoon.articleURL {
                        Button { openURL(url) } label: {
                            Label("Comment on West Side Rag", systemImage: "square.and.pencil")
                                .font(.subheadline)
                                .foregroundStyle(brandOrange)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(brandOrange.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }

                        ShareLink(
                            item: url,
                            subject: Text("100Burfords"),
                            message: Text(cartoon.title ?? "Week \(cartoon.week)")
                        ) {
                            Label("Share This Cartoon", systemImage: "square.and.arrow.up")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.secondary.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .foregroundStyle(.primary)
                        }
                    }

                    Divider()

                    Text("© Gary B. Martin • www.martoons.com\nPublished weekly in West Side Rag")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, 8)
                }
                .padding()
            }
        }
        .background(paperColor)
        .navigationTitle("100Burfords")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showComments) {
            CommentsView(week: cartoon.week, articleURL: cartoon.articleURL)
        }
        .fullScreenCover(isPresented: $showFullScreen) {
            LandscapeImageView(cartoon: cartoon, image: cachedImage)
                .environment(store)
        }
    }

    @ViewBuilder
    var cartoonImageView: some View {
        if let uiImage = cachedImage {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .onTapGesture { showFullScreen = true }
        } else {
            AsyncImage(url: cartoon.thumbnailURL) { phase in
                switch phase {
                case .success(let img):
                    img.resizable().aspectRatio(contentMode: .fit)
                        .onTapGesture { showFullScreen = true }
                case .failure:
                    Color.gray.opacity(0.12).frame(height: 280)
                        .overlay(Image(systemName: "photo").font(.largeTitle).foregroundStyle(.secondary))
                default:
                    Color.gray.opacity(0.07).frame(height: 280)
                        .overlay(ProgressView())
                }
            }
        }
    }
}

struct LandscapeImageView: View {
    let cartoon: Cartoon
    let image: UIImage?
    @Environment(CartoonStore.self) var store
    @Environment(\.dismiss) var dismiss
    @State private var showComments = false
    @State private var chromeVisible = true

    var body: some View {
        LandscapeWrapper(content: landscapeContent)
            .ignoresSafeArea()
    }

    var landscapeContent: some View {
        ZStack(alignment: .bottom) {
            Color.black.ignoresSafeArea()

            if let img = image {
                Image(uiImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            chromeVisible.toggle()
                        }
                    }
            }

            if chromeVisible {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        if let title = cartoon.title {
                            Text(title)
                                .font(.callout.bold())
                                .foregroundStyle(.white)
                        }
                        Text("Week \(cartoon.week)  •  \(cartoon.displayDate)")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    Spacer()
                    if let count = cartoon.commentCount, count > 0 {
                        Button { showComments = true } label: {
                            Label("\(count)", systemImage: "bubble.right")
                                .font(.caption.bold())
                                .foregroundStyle(.white)
                        }
                    }
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white.opacity(0.8))
                            .symbolRenderingMode(.hierarchical)
                    }
                    .padding(.leading, 8)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial.opacity(0.85))
                .transition(.opacity)
            }
        }
        .sheet(isPresented: $showComments) {
            CommentsView(week: cartoon.week, articleURL: cartoon.articleURL)
        }
    }
}
