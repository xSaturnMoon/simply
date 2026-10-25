import SwiftUI
import UIKit
import FirebaseCore

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
    @AppStorage("appTheme") private var appTheme: String = "system"

    init() {
        FirebaseApp.configure()
    }

    private var preferredColorScheme: ColorScheme? {
        switch appTheme {
        case "light": return .light
        case "dark": return .dark
        default: return nil // sistema
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(preferredColorScheme)
        }
    }
}
