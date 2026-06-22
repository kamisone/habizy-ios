import SwiftUI

struct ImageCarousel: View {
    let imageUrls: [String]
    var height: CGFloat = 200
    var cornerRadius: CGFloat = 18

    @State private var currentPage = 0
    @State private var fullScreenIndex: Int? = nil

    var body: some View {
        if imageUrls.isEmpty { EmptyView() } else {
            ZStack(alignment: .bottom) {
                TabView(selection: $currentPage) {
                    ForEach(Array(imageUrls.enumerated()), id: \.offset) { index, urlStr in
                        if let url = URL(string: urlStr) {
                            AsyncImage(url: url) { phase in
                                if case .success(let img) = phase {
                                    img.resizable().scaledToFill()
                                        .frame(maxWidth: .infinity).frame(height: height).clipped()
                                } else if case .failure = phase {
                                    placeholder
                                } else {
                                    placeholder.overlay(ProgressView().tint(.gray))
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture { fullScreenIndex = index }
                            .tag(index)
                        }
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: imageUrls.count > 1 ? .always : .never))
                .frame(height: height)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            }
            .fullScreenCover(item: $fullScreenIndex) { index in
                FullScreenImageViewer(imageUrls: imageUrls, initialIndex: index)
            }
        }
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color.lightCardBg).frame(height: height)
    }
}

// Make Int identifiable for fullScreenCover
extension Int: @retroactive Identifiable {
    public var id: Int { self }
}

struct FullScreenImageViewer: View {
    let imageUrls: [String]
    let initialIndex: Int
    @Environment(\.dismiss) private var dismiss
    @State private var currentPage: Int = 0

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            TabView(selection: $currentPage) {
                ForEach(Array(imageUrls.enumerated()), id: \.offset) { index, urlStr in
                    if let url = URL(string: urlStr) {
                        ZoomableImageView(url: url)
                            .tag(index)
                    }
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            VStack {
                HStack {
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .padding(16)
                }
                Spacer()
                if imageUrls.count > 1 {
                    Text("\(currentPage + 1) / \(imageUrls.count)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(12)
                        .padding(.bottom, 24)
                }
            }
        }
        .onAppear { currentPage = initialIndex }
    }
}

private struct ZoomableImageView: View {
    let url: URL
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        GeometryReader { geo in
            AsyncImage(url: url) { phase in
                if case .success(let img) = phase {
                    img.resizable().scaledToFit()
                        .scaleEffect(scale)
                        .offset(offset)
                        .gesture(magnificationGesture(in: geo.size))
                        .gesture(dragGesture(in: geo.size))
                        .onTapGesture(count: 2) { resetOrZoom() }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ProgressView().tint(.white)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
    }

    private func magnificationGesture(in size: CGSize) -> some Gesture {
        MagnifyGesture()
            .onChanged { value in
                let newScale = (lastScale * value.magnification).clamped(to: 1...5)
                scale = newScale
            }
            .onEnded { _ in
                if scale < 1 {
                    withAnimation(.spring()) { scale = 1; offset = .zero }
                }
                lastScale = scale
                lastOffset = offset
            }
    }

    private func dragGesture(in size: CGSize) -> some Gesture {
        DragGesture()
            .onChanged { value in
                guard scale > 1 else { return }
                let maxX = (size.width * (scale - 1)) / 2
                let maxY = (size.height * (scale - 1)) / 2
                offset = CGSize(
                    width: (lastOffset.width + value.translation.width).clamped(to: -maxX...maxX),
                    height: (lastOffset.height + value.translation.height).clamped(to: -maxY...maxY)
                )
            }
            .onEnded { _ in lastOffset = offset }
    }

    private func resetOrZoom() {
        withAnimation(.spring()) {
            if scale > 1 {
                scale = 1; lastScale = 1
                offset = .zero; lastOffset = .zero
            } else {
                scale = 3; lastScale = 3
            }
        }
    }
}

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
