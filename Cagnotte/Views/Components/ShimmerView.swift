import SwiftUI

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [
                        Color.clear,
                        Color.white.opacity(0.4),
                        Color.clear
                    ],
                    startPoint: .init(x: phase - 0.5, y: 0.5),
                    endPoint: .init(x: phase + 0.5, y: 0.5)
                )
                .clipped()
            )
            .onAppear {
                withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                    phase = 2
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

struct ShimmerBox: View {
    var width: CGFloat? = nil
    var height: CGFloat = 16
    var cornerRadius: CGFloat = 8

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color.borderColor.opacity(0.3))
            .frame(width: width, height: height)
            .shimmer()
    }
}

struct ShimmerHomeLoading: View {
    var body: some View {
        VStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                ShimmerBox(width: 80, height: 14)
                ShimmerBox(width: 140, height: 22, cornerRadius: 10)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 2)
            ShimmerBox(height: 140, cornerRadius: 28)
            HStack(spacing: 12) {
                ShimmerBox(height: 80, cornerRadius: 20)
                ShimmerBox(height: 80, cornerRadius: 20)
            }
            ShimmerBox(height: 90, cornerRadius: 26)
            HStack(spacing: 12) {
                ShimmerBox(height: 64, cornerRadius: 18)
                ShimmerBox(height: 64, cornerRadius: 18)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 8)
    }
}

struct ShimmerReportsLoading: View {
    var body: some View {
        VStack(spacing: 14) {
            ShimmerBox(height: 48, cornerRadius: 16)
            HStack(spacing: 8) {
                ForEach(0..<4, id: \.self) { _ in
                    ShimmerBox(width: 60, height: 30, cornerRadius: 20)
                }
                Spacer()
            }
            VStack(spacing: 0) {
                ForEach(0..<4, id: \.self) { _ in
                    HStack(alignment: .top, spacing: 12) {
                        ShimmerBox(width: 52, height: 52, cornerRadius: 12)
                        VStack(alignment: .leading, spacing: 6) {
                            ShimmerBox(width: 100, height: 12)
                            ShimmerBox(height: 14, cornerRadius: 6)
                            ShimmerBox(width: 80, height: 11)
                        }
                    }
                    .padding(.vertical, 12)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.white)
            .cornerRadius(22)
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
        }
        .padding(.horizontal, 18)
    }
}

struct ShimmerExpensesLoading: View {
    var body: some View {
        VStack(spacing: 14) {
            ShimmerBox(width: 120, height: 22, cornerRadius: 10)
                .frame(maxWidth: .infinity, alignment: .leading)
            ShimmerBox(height: 100, cornerRadius: 22)
            ShimmerBox(height: 160, cornerRadius: 22)
            VStack(spacing: 0) {
                ForEach(0..<5, id: \.self) { _ in
                    HStack(spacing: 12) {
                        ShimmerBox(width: 40, height: 40, cornerRadius: 13)
                        VStack(alignment: .leading, spacing: 4) {
                            ShimmerBox(width: 100, height: 14)
                            ShimmerBox(width: 60, height: 11)
                        }
                        Spacer()
                        ShimmerBox(width: 50, height: 14)
                    }
                    .padding(.vertical, 10)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.white)
            .cornerRadius(22)
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 8)
    }
}

struct ShimmerProfileLoading: View {
    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 14) {
                ShimmerBox(width: 80, height: 80, cornerRadius: 26)
                VStack(alignment: .leading, spacing: 6) {
                    ShimmerBox(width: 120, height: 20, cornerRadius: 10)
                    ShimmerBox(width: 80, height: 14)
                }
                Spacer()
            }
            .padding(.top, 12)
            HStack(spacing: 12) {
                ShimmerBox(height: 80, cornerRadius: 20)
                ShimmerBox(height: 80, cornerRadius: 20)
            }
            ShimmerBox(height: 180, cornerRadius: 22)
            ShimmerBox(height: 120, cornerRadius: 22)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 8)
    }
}
