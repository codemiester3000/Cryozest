import SwiftUI

struct LoadingView: View {
    var body: some View {
        VStack {
            Spacer()
            RectangleLoader()
                .frame(height: 20)
                .padding(.horizontal, 15)
            Spacer()
            RectangleLoader()
                .frame(height: 20)
                .padding(.horizontal, 15)
            Spacer()
            RectangleLoader()
                .frame(height: 20)
                .padding(.horizontal, 15)
            Spacer()
            RectangleLoader()
                .frame(height: 20)
                .padding(.horizontal, 15)
            Spacer()
            RectangleLoader()
                .frame(height: 20)
                .padding(.horizontal, 15)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(EdgeInsets(top: 40, leading: 30, bottom: 40, trailing: 30))
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.05, green: 0.15, blue: 0.25),
                    Color(red: 0.1, green: 0.2, blue: 0.35),
                    Color(red: 0.15, green: 0.25, blue: 0.4)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .padding(.horizontal)
    }
}


struct RectangleLoader: View {
    @State private var isAnimating = false
    
    let gradient = Gradient(colors: [Color.gray.opacity(0.4), Color.gray.opacity(0.8), Color.gray.opacity(0.4)])
    
    var body: some View {
        GeometryReader { geometry in
            Rectangle()
                .fill(LinearGradient(gradient: self.gradient, startPoint: .leading, endPoint: .trailing))
                .frame(width: geometry.size.width, height: geometry.size.height)
                .mask(RoundedRectangle(cornerRadius: 5).fill(Color.white))
                .offset(x: isAnimating ? geometry.size.width : -geometry.size.width)
                .animation(Animation.linear(duration: 1).repeatForever(autoreverses: false))
                .onAppear {
                    self.isAnimating = true
                }
        }
    }
}
