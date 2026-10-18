import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.black, Color(red: 0.08, green: 0.12, blue: 0.28)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "iphone.gen3")
                    .font(.system(size: 54))
                    .foregroundStyle(.red)

                Text("Hello, DONI!")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)

                Text("My first iOS app built with GitHub Actions")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.8))
            }
            .padding(28)
        }
    }
}
