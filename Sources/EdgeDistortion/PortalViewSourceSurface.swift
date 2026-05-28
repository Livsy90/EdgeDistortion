import UIKit

public final class PortalViewSourceSurface: UIView {
    private var subscriptions: [Subscription] = []
    
    public init() {
        super.init(frame: .zero)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func didMoveToWindow() {
        super.didMoveToWindow()
        guard window != nil else { return }
        
        for subscription in subscriptions {
            subscription.replica?.attach(to: self, hidesOriginal: subscription.hidesOriginal)
        }
    }

    public func connect(_ replica: PortalView, hidesOriginal: Bool = false) {
        subscriptions.append(Subscription(replica: replica, hidesOriginal: hidesOriginal))
        guard window != nil else { return }
        replica.attach(to: self, hidesOriginal: hidesOriginal)
    }

    public func disconnect(_ replica: PortalView) {
        subscriptions.removeAll { $0.replica === replica }
        replica.detach()
    }
}

private final class Subscription {
    weak var replica: PortalView?
    let hidesOriginal: Bool

    init(replica: PortalView, hidesOriginal: Bool) {
        self.replica = replica
        self.hidesOriginal = hidesOriginal
    }
}
