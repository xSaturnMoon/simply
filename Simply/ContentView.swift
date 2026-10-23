import SwiftUI

struct ContentView: View {
    // Colore di sfondo #1C1C1E
    private let backgroundColor = Color(red: 28 / 255.0, green: 28 / 255.0, blue: 30 / 255.0)

    var body: some View {
        backgroundColor
            .ignoresSafeArea()
    }
}

#Preview {
    ContentView()
}
