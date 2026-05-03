import SwiftUI

struct LaunchView: View {
    @Binding var isShowing: Bool

    var body: some View {
        ZStack {
            Color(red: 0.55, green: 0.07, blue: 0.07)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                Image("LaunchBurford")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 320)
                    .clipShape(RoundedRectangle(cornerRadius: 32))
                    .shadow(color: .black.opacity(0.5), radius: 20, y: 8)

                Spacer().frame(height: 32)

                Text("100 Burfords")
                    .font(.system(size: 42, weight: .black, design: .serif))
                    .tracking(1)
                    .foregroundStyle(Color(red: 0.98, green: 0.955, blue: 0.88))

                Text("Martoonerville")
                    .font(.system(.title3, design: .serif).italic())
                    .foregroundStyle(Color(red: 0.98, green: 0.955, blue: 0.88).opacity(0.8))
                    .padding(.top, 2)

                Spacer().frame(height: 60)

                Text("The art of Gary B. Martin")
                    .font(.caption.bold())
                    .foregroundStyle(.white.opacity(0.7))

                Spacer()

                Text("West Side Rag  •  New York City")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.35))
                    .padding(.bottom, 40)
            }
            .padding(.horizontal, 32)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                withAnimation(.easeOut(duration: 0.7)) {
                    isShowing = false
                }
            }
        }
    }
}
