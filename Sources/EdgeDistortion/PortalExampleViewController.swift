import UIKit
import SwiftUI

final class PortalViewExampleViewController: UIViewController {
    private let sourceView = PortalViewSourceSurface()
    private let sourceImageView = UIImageView(image: UIImage(named: "roller90s", in: .module, compatibleWith: nil) ?? UIImage(systemName: "photo"))
    private let duplicateContainer = UIView()
    private let replica: PortalView?

    init() {
        replica = PortalView(tracksOriginalFrame: false)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        replica = PortalView(tracksOriginalFrame: false)
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        setupSourceImage()
        setupPortalDuplicate()
        setupLayout()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startSourceAnimation()
    }

    private func setupSourceImage() {
        sourceView.translatesAutoresizingMaskIntoConstraints = false
        sourceView.clipsToBounds = true
        sourceView.backgroundColor = .secondarySystemBackground
        sourceView.layer.cornerRadius = 24
        sourceView.layer.borderWidth = 1
        sourceView.layer.borderColor = UIColor.separator.cgColor
        view.addSubview(sourceView)

        sourceImageView.translatesAutoresizingMaskIntoConstraints = false
        sourceImageView.contentMode = .scaleAspectFill
        sourceImageView.tintColor = .secondaryLabel
        sourceImageView.clipsToBounds = true
        sourceView.addSubview(sourceImageView)

        NSLayoutConstraint.activate([
            sourceImageView.topAnchor.constraint(equalTo: sourceView.topAnchor),
            sourceImageView.leadingAnchor.constraint(equalTo: sourceView.leadingAnchor),
            sourceImageView.trailingAnchor.constraint(equalTo: sourceView.trailingAnchor),
            sourceImageView.bottomAnchor.constraint(equalTo: sourceView.bottomAnchor),
        ])
    }

    private func setupPortalDuplicate() {
        duplicateContainer.translatesAutoresizingMaskIntoConstraints = false
        duplicateContainer.clipsToBounds = true
        duplicateContainer.backgroundColor = .tertiarySystemBackground
        duplicateContainer.layer.cornerRadius = 24
        duplicateContainer.layer.borderWidth = 1
        duplicateContainer.layer.borderColor = UIColor.systemBlue.withAlphaComponent(0.45).cgColor
        view.addSubview(duplicateContainer)

        guard let replica else {
            let fallbackLabel = UILabel()
            fallbackLabel.translatesAutoresizingMaskIntoConstraints = false
            fallbackLabel.text = "_UIPortalView unavailable"
            fallbackLabel.textColor = .secondaryLabel
            fallbackLabel.textAlignment = .center
            duplicateContainer.addSubview(fallbackLabel)

            NSLayoutConstraint.activate([
                fallbackLabel.centerXAnchor.constraint(equalTo: duplicateContainer.centerXAnchor),
                fallbackLabel.centerYAnchor.constraint(equalTo: duplicateContainer.centerYAnchor),
            ])
            return
        }

        let replicaView = replica.renderedView
        replicaView.translatesAutoresizingMaskIntoConstraints = false
        replicaView.clipsToBounds = true
        duplicateContainer.addSubview(replicaView)
        sourceView.connect(replica)

        NSLayoutConstraint.activate([
            replicaView.topAnchor.constraint(equalTo: duplicateContainer.topAnchor),
            replicaView.leadingAnchor.constraint(equalTo: duplicateContainer.leadingAnchor),
            replicaView.trailingAnchor.constraint(equalTo: duplicateContainer.trailingAnchor),
            replicaView.bottomAnchor.constraint(equalTo: duplicateContainer.bottomAnchor),
        ])
    }

    private func setupLayout() {
        let guide = view.safeAreaLayoutGuide

        NSLayoutConstraint.activate([
            sourceView.topAnchor.constraint(equalTo: guide.topAnchor, constant: 32),
            sourceView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            sourceView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            sourceView.heightAnchor.constraint(equalTo: sourceView.widthAnchor, multiplier: 0.68),

            duplicateContainer.topAnchor.constraint(equalTo: sourceView.bottomAnchor, constant: 28),
            duplicateContainer.leadingAnchor.constraint(equalTo: sourceView.leadingAnchor),
            duplicateContainer.trailingAnchor.constraint(equalTo: sourceView.trailingAnchor),
            duplicateContainer.heightAnchor.constraint(equalTo: sourceView.heightAnchor),
        ])
    }

    private func startSourceAnimation() {
        guard sourceImageView.layer.animation(forKey: "portal-source-motion") == nil else { return }

        let animation = CABasicAnimation(keyPath: "transform.scale")
        animation.fromValue = 1
        animation.toValue = 1.3
        animation.duration = 1.8
        animation.autoreverses = true
        animation.repeatCount = .infinity
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        sourceImageView.layer.add(animation, forKey: "portal-source-motion")
    }
}

#Preview {
    struct PortalViewControllerPreview: UIViewControllerRepresentable {
        func makeUIViewController(context: Context) -> PortalViewExampleViewController {
            PortalViewExampleViewController()
        }
        
        func updateUIViewController(_ uiViewController: PortalViewExampleViewController, context: Context) {}
    }
    
    return PortalViewControllerPreview()
}
