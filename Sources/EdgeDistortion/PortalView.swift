import UIKit

@MainActor
public final class PortalView {

    public let renderedView: UIView
    private weak var attachedSurface: UIView?

    public init(tracksOriginalFrame: Bool) {
        let duplicate = UIView.makeSystemReplicaView()
        PortalView.configure(
            duplicate,
            followsGeometry: tracksOriginalFrame,
            hidesTouches: true
        )
        renderedView = duplicate
    }

    public func attach(to surface: PortalViewSourceSurface, hidesOriginal: Bool = false) {
        renderedView.setValue(surface, forKey: "sourceView")
        renderedView.setValue(hidesOriginal, forKey: "hidesSourceView")
        attachedSurface = surface
        refreshStackingPosition()
    }

    public func refresh(hidesOriginal: Bool = false) {
        guard let surface = attachedSurface as? PortalViewSourceSurface else { return }
        attach(to: surface, hidesOriginal: hidesOriginal)
    }

    public func detach() {
        renderedView.setValue(nil, forKey: "sourceView")
        attachedSurface = nil
    }

    private static func configure(_ replica: UIView, followsGeometry: Bool, hidesTouches: Bool) {
        replica.setValue(followsGeometry, forKey: "matchesPosition")
        replica.setValue(followsGeometry, forKey: "matchesTransform")
        replica.setValue(false, forKey: "matchesAlpha")
        replica.setValue(!hidesTouches, forKey: "allowsHitTesting")
        replica.setValue(false, forKey: "forwardsClientHitTestingToSourceView")
    }

    private func refreshStackingPosition() {
        if let container = renderedView.superview,
           let slot = container.subviews.firstIndex(of: renderedView) {
            container.insertSubview(renderedView, at: slot)
            return
        }

        guard let parentLayer = renderedView.layer.superlayer,
              let layerSlot = parentLayer.sublayers?.firstIndex(of: renderedView.layer) else {
            return
        }
        parentLayer.insertSublayer(renderedView.layer, at: UInt32(layerSlot))
    }
}

private extension UIView {
    static func makeSystemReplicaView() -> UIView {
        let replica = systemReplicaViewClass.init()
        replica.setValue(false, forKey: "allowsHitTesting")
        replica.setValue(false, forKey: "forwardsClientHitTestingToSourceView")
        replica.setValue(false, forKey: "matchesAlpha")
        replica.setValue(true, forKey: "matchesPosition")
        replica.setValue(true, forKey: "matchesTransform")
        return replica
    }

    private static var systemReplicaViewClass: UIView.Type {
        NSClassFromString("_UIPortalView") as? UIView.Type ?? UIView.self
    }
}
