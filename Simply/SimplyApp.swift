import SwiftUI
import UIKit

// Fix: Riabilita il gesto swipe-back anche con back button nascosta
extension UINavigationController: @retroactive UIGestureRecognizerDelegate {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        viewControllers.count > 1
    }
}

@main
struct SimplyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
