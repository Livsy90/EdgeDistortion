import SwiftUI

public struct EdgeDistortionEffectContainer<Content: View>: UIViewRepresentable {

    public let content: Content
    private let bendSpan: CGFloat
    private let depthDistance: CGFloat
    private let maskCornerRadius: CGFloat

    public init(
        bendSpan: CGFloat = 170,
        depthDistance: CGFloat = 120,
        maskCornerRadius: CGFloat = 24,
        @ViewBuilder content: () -> Content
    ) {
        self.bendSpan = bendSpan
        self.depthDistance = depthDistance
        self.maskCornerRadius = maskCornerRadius
        self.content = content()
    }

    public func makeUIView(context: Context) -> SwiftUIEdgeDistortionContainerHost<Content> {
        SwiftUIEdgeDistortionContainerHost(
            rootView: content,
            bendSpan: bendSpan,
            depthDistance: depthDistance,
            maskCornerRadius: maskCornerRadius
        )
    }

    public func updateUIView(_ uiView: SwiftUIEdgeDistortionContainerHost<Content>, context: Context) {
        uiView.update(rootView: content)
    }
}

public final class SwiftUIEdgeDistortionContainerHost<Content: View>: UIView {

    private let bendSurface = EdgeDistortionWrapper()
    private let hostingController: UIHostingController<Content>
    

    init(
        rootView: Content,
        bendSpan: CGFloat,
        depthDistance: CGFloat,
        maskCornerRadius: CGFloat
    ) {
        hostingController = UIHostingController(rootView: rootView)
        super.init(frame: .zero)

        backgroundColor = .clear
        clipsToBounds = false

        bendSurface
            .setBendSpan(bendSpan)
            .setDepthDistance(depthDistance)
            .setMaskCornerRadius(maskCornerRadius)
        bendSurface.translatesAutoresizingMaskIntoConstraints = false
        addSubview(bendSurface)

        hostingController.view.backgroundColor = .clear
        hostingController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        bendSurface.sourceSurface.addSubview(hostingController.view)

        NSLayoutConstraint.activate([
            bendSurface.topAnchor.constraint(equalTo: topAnchor),
            bendSurface.leadingAnchor.constraint(equalTo: leadingAnchor),
            bendSurface.trailingAnchor.constraint(equalTo: trailingAnchor),
            bendSurface.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError()
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        hostingController.view.frame = bendSurface.sourceSurface.bounds
    }

    func update(rootView: Content) {
        hostingController.rootView = rootView
        setNeedsLayout()
    }
}
