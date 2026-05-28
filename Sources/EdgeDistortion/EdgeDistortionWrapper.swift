import UIKit

@MainActor
public final class EdgeDistortionWrapper: UIView {

    public let sourceSurface = PortalViewSourceSurface()

    private var bendSpan: CGFloat = 140
    private var depthDistance: CGFloat = 100
    private var maskCornerRadius: CGFloat = 24
    
    private let bendsAreActive = true
    private let sliceTotal = 8
    private let viewportClip = UIView()
    private let centerMirror: PortalView?
    private let upperRail = UIView()
    private let lowerRail = UIView()
    private var upperMirrors: [DistortionView] = []
    private var lowerMirrors: [DistortionView] = []

    public init() {
        centerMirror = PortalView(tracksOriginalFrame: false)
        super.init(frame: .zero)

        clipsToBounds = false
        viewportClip.clipsToBounds = true

        addSubview(sourceSurface)

        if let mirror = centerMirror {
            viewportClip.addSubview(mirror.renderedView)
            sourceSurface.connect(mirror, hidesOriginal: true)
        }

        for layerHost in [viewportClip, upperRail, lowerRail] {
            layerHost.isUserInteractionEnabled = false
            addSubview(layerHost)
        }

        assembleMirrorSlices()
    }

    required init?(coder: NSCoder) { fatalError() }

    @discardableResult
    public func setBendSpan(_ value: CGFloat) -> Self {
        bendSpan = value
        setNeedsLayout()
        return self
    }

    @discardableResult
    public func setDepthDistance(_ value: CGFloat) -> Self {
        depthDistance = value
        setNeedsLayout()
        return self
    }

    @discardableResult
    public func setMaskCornerRadius(_ value: CGFloat) -> Self {
        maskCornerRadius = value
        setNeedsLayout()
        return self
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        sourceSurface.frame = bounds
        refreshGeometry()
    }

    // MARK: - Mirrors

    private func assembleMirrorSlices() {
        for mirror in upperMirrors + lowerMirrors {
            mirror.removeFromSuperview()
        }

        let safeCount = max(sliceTotal, 0)
        upperMirrors = (0..<safeCount).compactMap { _ in
            DistortionView(sourceView: sourceSurface, anchorPoint: CGPoint(x: 0.5, y: 1))
        }
        lowerMirrors = (0..<safeCount).compactMap { _ in
            DistortionView(sourceView: sourceSurface, anchorPoint: CGPoint(x: 0.5, y: 0))
        }

        upperMirrors.forEach(upperRail.addSubview)
        lowerMirrors.forEach(lowerRail.addSubview)

        setNeedsLayout()
    }

    // MARK: - Geometry

    private struct ArcStrip {
        let tilt: CGFloat
        let height: CGFloat
        let unitStart: CGPoint
    }

    private func quarterCircleStrips(radius: CGFloat) -> [ArcStrip] {
        guard sliceTotal > 0 else { return [] }

        let increment = (.pi * 0.5) / CGFloat(sliceTotal)
        return (0..<sliceTotal).map { index in
            let leadingAngle = .pi * 0.5 - CGFloat(index) * increment
            let trailingAngle = leadingAngle - increment

            let leadingUnit = CGPoint(x: cos(leadingAngle), y: sin(leadingAngle))
            let trailingUnit = CGPoint(x: cos(trailingAngle), y: sin(trailingAngle))
            let run = trailingUnit.x - leadingUnit.x
            let rise = trailingUnit.y - leadingUnit.y
            let chord = sqrt(run * run + rise * rise)

            return ArcStrip(
                tilt: atan2(rise, run),
                height: chord * radius,
                unitStart: leadingUnit
            )
        }
    }

    private func place(
        mirrors: [DistortionView],
        along strips: [ArcStrip],
        canvas: CGSize,
        radius: CGFloat,
        onLowerEdge: Bool
    ) {
        let direction: CGFloat = onLowerEdge ? 1 : -1
        var traveled: CGFloat = 0

        for pair in zip(mirrors, strips) {
            let mirror = pair.0
            let strip = pair.1

            var projection = CATransform3DIdentity
            projection.m34 = 1 / depthDistance
            projection = CATransform3DTranslate(
                projection,
                0,
                direction * strip.unitStart.x * radius,
                (1 - strip.unitStart.y) * radius
            )
            projection = CATransform3DRotate(projection, -direction * strip.tilt, 1, 0, 0)

            let sourceY = onLowerEdge
                ? canvas.height - radius + traveled
                : radius - traveled - strip.height

            mirror.center = CGPoint(x: canvas.width * 0.5, y: onLowerEdge ? 0 : radius * 2)
            mirror.bounds = CGRect(x: 0, y: 0, width: canvas.width, height: strip.height)
            mirror.layer.transform = projection
            mirror.update(
                containerSize: canvas,
                rect: CGRect(x: 0, y: sourceY, width: canvas.width, height: strip.height)
            )

            traveled += strip.height
        }
    }

    private func refreshGeometry() {
        let canvas = bounds.size
        guard canvas.width > 0, canvas.height > 0 else { return }

        viewportClip.layer.mask = nil

        guard bendsAreActive else {
            viewportClip.frame = bounds
            centerMirror?.renderedView.frame = bounds
            installRoundedCrop(from: 0, through: canvas.height, width: canvas.width)
            upperRail.isHidden = true
            lowerRail.isHidden = true
            return
        }

        let radius = bendSpan / 2
        let doubledRadius = radius + radius

        viewportClip.frame = CGRect(x: 0, y: radius, width: canvas.width, height: canvas.height - doubledRadius)
        centerMirror?.renderedView.frame = CGRect(x: 0, y: -radius, width: canvas.width, height: canvas.height)

        upperRail.isHidden = false
        lowerRail.isHidden = false
        upperRail.frame = CGRect(x: 0, y: -radius, width: canvas.width, height: doubledRadius)
        lowerRail.frame = CGRect(x: 0, y: canvas.height - radius, width: canvas.width, height: doubledRadius)

        let strips = quarterCircleStrips(radius: radius)
        place(mirrors: upperMirrors, along: strips, canvas: canvas, radius: radius, onLowerEdge: false)
        place(mirrors: lowerMirrors, along: strips, canvas: canvas, radius: radius, onLowerEdge: true)

        let compressedRadius = radius * depthDistance / (depthDistance + radius)
        let cropInset: CGFloat = 3
        installRoundedCrop(
            from: radius - compressedRadius + cropInset,
            through: canvas.height - radius + compressedRadius - cropInset,
            width: canvas.width
        )

    }

    private func installRoundedCrop(from top: CGFloat, through bottom: CGFloat, width: CGFloat) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)

        let cropHeight = bottom - top
        let roundedLayer = layer.mask as? CAShapeLayer ?? CAShapeLayer()
        roundedLayer.frame = CGRect(x: 0, y: top, width: width, height: cropHeight)
        roundedLayer.path = UIBezierPath(
            roundedRect: CGRect(x: 0, y: 0, width: width, height: cropHeight),
            cornerRadius: maskCornerRadius
        ).cgPath
        layer.mask = roundedLayer

        CATransaction.commit()
    }
}

