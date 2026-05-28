import UIKit

final class DistortionView: UIView {

    let replica: PortalView

    var showsBorder: Bool = false {
        didSet { layer.borderWidth = showsBorder ? 0.5 : 0 }
    }

    init?(sourceView: PortalViewSourceSurface, anchorPoint: CGPoint = CGPoint(x: 0.5, y: 0)) {
        guard let replica = PortalView(tracksOriginalFrame: false) else { return nil }
        self.replica = replica
        super.init(frame: .zero)
        clipsToBounds = true
        layer.borderColor = UIColor.yellow.cgColor
        layer.anchorPoint = anchorPoint
        addSubview(replica.renderedView)
        sourceView.connect(replica)
    }

    required init?(coder: NSCoder) { fatalError() }

    func update(containerSize: CGSize, rect: CGRect) {
        replica.renderedView.frame = CGRect(
            origin: CGPoint(x: -rect.minX, y: -rect.minY),
            size: containerSize
        )
    }
}
