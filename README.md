# EdgeDistortion

EdgeDistortion is an iOS Swift package for rendering SwiftUI or UIKit content through a portal-backed edge distortion effect. It uses a source surface, portal views, and a UIKit wrapper to mirror content into curved top and bottom edge slices.

https://github.com/user-attachments/assets/c0bb3a90-28c7-42e7-b2a9-91311c1c66d4

## Warning

This package uses private UIKit API. Internally it looks up `_UIPortalView` and configures private key-value properties such as `sourceView`, `hidesSourceView`, `matchesPosition`, and `matchesTransform`.

Apps that use this package may be rejected during App Store review. Treat it as experimental code for prototypes, internal tools, demos, or research unless you are comfortable with that risk.

## Requirements

- iOS 15+
- Swift 6.3+
- Swift Package Manager

## Installation

Add the package to your app with Swift Package Manager and import the library:

```swift
import EdgeDistortion
```

## Public Components

### EdgeDistortionEffectContainer

`EdgeDistortionEffectContainer` is the main SwiftUI entry point. It wraps arbitrary SwiftUI content in a `UIViewRepresentable` and applies the edge distortion effect.

```swift
import SwiftUI
import EdgeDistortion

struct GalleryView: View {
    var body: some View {
        EdgeDistortionEffectContainer(
            bendSpan: 170,
            depthDistance: 120,
            maskCornerRadius: 24
        ) {
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(0..<20, id: \.self) { index in
                        Image("photo-\(index)")
                            .resizable()
                            .scaledToFit()
                    }
                }
            }
        }
        .frame(height: 320)
    }
}
```

The initializer parameters are optional:

- `bendSpan`: height of the distorted edge region.
- `depthDistance`: perspective depth used by the 3D transform.
- `maskCornerRadius`: corner radius applied to the visible crop.

### EdgeDistortionWrapper

`EdgeDistortionWrapper` is the UIKit container that owns the distortion effect. Add your UIKit content to `sourceSurface`.

```swift
import UIKit
import EdgeDistortion

final class DistortionViewController: UIViewController {
    private let distortionView = EdgeDistortionWrapper()
    private let imageView = UIImageView(image: UIImage(named: "photo"))

    override func viewDidLoad() {
        super.viewDidLoad()

        distortionView.translatesAutoresizingMaskIntoConstraints = false
        distortionView
            .setBendSpan(170)
            .setDepthDistance(120)
            .setMaskCornerRadius(24)

        view.addSubview(distortionView)
        NSLayoutConstraint.activate([
            distortionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            distortionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            distortionView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            distortionView.heightAnchor.constraint(equalToConstant: 320)
        ])

        imageView.frame = distortionView.sourceSurface.bounds
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        imageView.contentMode = .scaleAspectFill
        distortionView.sourceSurface.addSubview(imageView)
    }
}
```

### PortalViewSourceSurface

`PortalViewSourceSurface` is a `UIView` subclass that acts as the source for one or more portal views. It keeps portal connections and reattaches them when the source moves into a window.

```swift
let sourceSurface = PortalViewSourceSurface()
let label = UILabel()
label.text = "Source content"
sourceSurface.addSubview(label)
```

### PortalView

`PortalView` is the low-level wrapper around the private portal view. Use it when you want to manually mirror a `PortalViewSourceSurface` into another view hierarchy.

```swift
let sourceSurface = PortalViewSourceSurface()
let portal = PortalView(tracksOriginalFrame: false)

if let portal {
    containerView.addSubview(portal.renderedView)
    portal.renderedView.frame = containerView.bounds
    portal.renderedView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

    sourceSurface.connect(portal, hidesOriginal: false)
}
```

Useful methods:

- `attach(to:hidesOriginal:)`: attaches the portal to a source surface.
- `refresh(hidesOriginal:)`: reapplies the current source connection.
- `detach()`: clears the portal source.

## Notes

`PortalView.init(tracksOriginalFrame:)` is failable because the implementation depends on private UIKit behavior. Always handle the `nil` case if you use `PortalView` directly.
