import Foundation
import UIKit

extension UIView {
    func showIndetermineHud() {
        // Hide all previous hud
        hideHud()

        // show new hud
        showLoadingIndicatorView()
    }

    func hideHud() {
        hideLoadingIndicatorView()
    }
}

extension UIView {
    // Using a function since `var image` might conflict with an existing variable
    // (like on `UIImageView`)
    func asImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { rendererContext in
            layer.render(in: rendererContext.cgContext)
        }
    }

    func asImageInBackground() -> UIImage {
        layoutIfNeeded()
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { rendererContext in
            layer.render(in: rendererContext.cgContext)
        }
    }
}

extension UIView {
    func lightShadow() -> Self {
        shadow(color: .black, alpha: 0.05, x: 0, y: 0, blur: 8, spread: 0)
    }

    func mediumShadow() -> Self {
        shadow(color: .black, alpha: 0.07, x: 0, y: 2, blur: 8, spread: 0)
    }
}

extension UIView {
    func shake() {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
        animation.duration = 0.6
        animation.values = [-20.0, 20.0, -20.0, 20.0, -10.0, 10.0, -5.0, 5.0, 0.0]
        layer.add(animation, forKey: "shake")
    }
}
