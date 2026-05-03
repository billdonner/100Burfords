import SwiftUI

struct CommentsView: View {
    let week: Int
    let articleURL: URL?
    @Environment(\.dismiss) var dismiss
    @Environment(\.openURL) var openURL

    private var comments: [CartoonComment] {
        CommentsStore.shared.comments(forWeek: week)
    }

    var body: some View {
        NavigationStack {
            Group {
                if comments.isEmpty {
                    emptyState
                } else {
                    commentsList
                }
            }
            .navigationTitle("Reader Comments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .background(paperColor)
            .toolbarBackground(paperColor, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }

    var commentsList: some View {
        ScrollView {
            VStack(spacing: 0) {
                addCommentBanner
                ForEach(comments) { comment in
                    CommentRow(comment: comment)
                    Divider().padding(.leading, 16)
                }
            }
        }
        .background(paperColor)
    }

    var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "bubble.right")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            Text("No comments yet")
                .font(.headline)
            if let url = articleURL {
                Button {
                    openURL(url)
                    dismiss()
                } label: {
                    Label("Comment on West Side Rag", systemImage: "square.and.pencil")
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(brandOrange)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .fontWeight(.semibold)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    var addCommentBanner: some View {
        Group {
            if let url = articleURL {
                Button {
                    openURL(url)
                    dismiss()
                } label: {
                    Label("Add Your Comment on West Side Rag", systemImage: "square.and.pencil")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(brandOrange)
                        .foregroundStyle(.white)
                        .fontWeight(.semibold)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
    }
}

struct CommentRow: View {
    let comment: CartoonComment

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(comment.author)
                    .font(.caption.bold())
                    .foregroundStyle(brandOrange)
                Spacer()
                Text(comment.date)
                    .font(.caption2)
                    .foregroundStyle(Color(uiColor: .secondaryLabel))
            }
            Text(comment.text)
                .font(.callout)
                .foregroundStyle(Color(uiColor: .label))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(paperColor)
    }
}
