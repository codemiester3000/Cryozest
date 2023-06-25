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
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(EdgeInsets(top: 80, leading: 30, bottom: 80, trailing: 30))
        .background(Color(.darkGray))
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
