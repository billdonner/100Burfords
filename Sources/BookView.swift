import SwiftUI

struct BookView: View {
    @Environment(CartoonStore.self) var store
    @Environment(\.dismiss) var dismiss
    let startWeek: Int

    var cartoons: [Cartoon] { store.cartoons.filter(\.hasData) }

    @State private var currentIndex: Int = 0
    @State private var chromeVisible = true

    var body: some View {
        LandscapeWrapper(content: bookContent)
            .ignoresSafeArea()
    }

    var bookContent: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()

            TabView(selection: $currentIndex) {
                ForEach(Array(cartoons.enumerated()), id: \.element.id) { idx, cartoon in
                    CartoonPageView(cartoon: cartoon, chromeVisible: $chromeVisible)
                        .tag(idx)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            if chromeVisible {
                HStack(spacing: 12) {
                    Text("\(currentIndex + 1) / \(cartoons.count)")
                        .font(.caption.bold())
                        .foregroundStyle(.white.opacity(0.7))
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white.opacity(0.8))
                            .symbolRenderingMode(.hierarchical)
                    }
                }
                .padding(16)
                .transition(.opacity)
            }
        }
        .onAppear {
            currentIndex = cartoons.firstIndex(where: { $0.week == startWeek }) ?? 0
        }
    }
}

struct CartoonPageView: View {
    let cartoon: Cartoon
    @Binding var chromeVisible: Bool
    @State private var image: UIImage?
    @State private var showComments = false

    var body: some View {
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
            } else {
                ProgressView()
                    .tint(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            if chromeVisible {
                VStack(alignment: .leading, spacing: 2) {
                    if let title = cartoon.title {
                        Text(title)
                            .font(.callout.bold())
                            .foregroundStyle(.white)
                            .lineLimit(1)
                    }
                    HStack {
                        Text("Week \(cartoon.week)  •  \(cartoon.displayDate)")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.75))
                        Spacer()
                        if let count = cartoon.commentCount, count > 0 {
                            Button { showComments = true } label: {
                                Label("\(count)", systemImage: "bubble.right")
                                    .font(.caption2.bold())
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial.opacity(0.85))
                .transition(.opacity)
            }
        }
        .clipShape(Rectangle())
        .task {
            guard image == nil else { return }
            let loaded = await Task.detached(priority: .userInitiated) {
                cartoon.loadBundledImage()
            }.value
            image = loaded
        }
        .sheet(isPresented: $showComments) {
            CommentsView(week: cartoon.week, articleURL: cartoon.articleURL)
        }
    }
}
