import SwiftUI

struct SwiftUIEdgeDistortionImageScrollView: View {

    private let imageNames = [
        "image90",
        "biker90s",
        "skate90s",
        "pontiac90s",
        "roller90s"
    ]
    private let repeatCount = 24
    @State private var currentIndex = 0

    var body: some View {
        GeometryReader { _ in
            ZStack {
                Color.black

                RadialGradient(stops: [
                    .init(color: .purple.opacity(0.2), location: 0),
                    .init(color: .black, location: 1)
                ], center: .center, startRadius: 10, endRadius: 1000)

                ScrollViewReader { proxy in
                    EdgeDistortionEffectContainer {
                        ZStack {
                            ScrollView(.vertical, showsIndicators: true) {
                                LazyVStack(spacing: 0) {
                                    ForEach(0..<repeatCount, id: \.self) { index in
                                        Image(imageNames[index % imageNames.count], bundle: .module)
                                            .resizable()
                                            .scaledToFit()
                                            .background(Color.white.opacity(0.18))
                                            .id(index)
                                    }
                                }
                            }
                        }
                        .background(Color.clear)
                    }
                    .frame(height: 320)
                    .overlay(alignment: .top) {
                        Image(.oldTv)
                            .resizable()
                            .frame(height: 400)
                            .allowsHitTesting(false)
                            .overlay(alignment: .bottomTrailing) {
                                paginationButtons(proxy: proxy)
                                    .padding(.bottom, 20)
                                    .padding(.trailing, 30)
                            }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .ignoresSafeArea()
    }

    private func paginationButtons(proxy: ScrollViewProxy) -> some View {
        VStack(spacing: 0) {
            Button {
                scroll(to: currentIndex - 1, proxy: proxy)
            } label: {
                Image(systemName: "chevron.up")
                    .frame(width: 33, height: 22)
                    .foregroundStyle(.white.opacity(0.01))
            }
            .disabled(currentIndex == 0)
            .buttonStyle(.plain)

            Button {
                scroll(to: currentIndex + 1, proxy: proxy)
            } label: {
                Image(systemName: "chevron.down")
                    .frame(width: 33, height: 22)
                    .foregroundStyle(.white.opacity(0.01))
            }
            .disabled(currentIndex == repeatCount - 1)
            .buttonStyle(.plain)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.white.opacity(0.01))
        .background(.white.opacity(0.01))
        .opacity(0.9)
    }

    private func scroll(to index: Int, proxy: ScrollViewProxy) {
        let nextIndex = min(max(index, 0), repeatCount - 1)
        currentIndex = nextIndex
        withAnimation(.easeInOut(duration: 1.5)) {
            proxy.scrollTo(nextIndex, anchor: .center)
        }
    }
}

#Preview {
    SwiftUIEdgeDistortionImageScrollView()
}
