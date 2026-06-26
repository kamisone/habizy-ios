import SwiftUI

struct SplashView: View {
    @State private var scale: CGFloat = 0.82
    @State private var opacity: Double = 0

    var body: some View {
        ZStack {
            Color(red: 0xFB / 255.0, green: 0xF7 / 255.0, blue: 0xF0 / 255.0).ignoresSafeArea()

            Image("logo_habizy")
                .resizable()
                .scaledToFit()
                .frame(width: 200)
                .scaleEffect(scale)
                .opacity(opacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }
}
