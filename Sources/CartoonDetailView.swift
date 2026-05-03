import SwiftUI

struct CartoonDetailView: View {
    let cartoon: Cartoon
    @Environment(\.openURL) var openURL
    @State private var showComments = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                cartoonImageView
                    .padding(.bottom, 2)

                Text("Tap image to read comments")
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
                        Button {
                            openURL(url)
                        } label: {
                            Label("Leave a Comment on West Side Rag", systemImage: "bubble.right.fill")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(brandOrange)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .fontWeight(.semibold)
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

                    Text("© Gary R. Martin • www.martoons.com\nPublished weekly in West Side Rag")
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
    }

    @ViewBuilder
    var cartoonImageView: some View {
        if let uiImage = cartoon.bundledImage {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .onTapGesture { showComments = true }
        } else {
            AsyncImage(url: cartoon.thumbnailURL) { phase in
                switch phase {
                case .success(let img):
                    img.resizable().aspectRatio(contentMode: .fit)
                        .onTapGesture { showComments = true }
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
