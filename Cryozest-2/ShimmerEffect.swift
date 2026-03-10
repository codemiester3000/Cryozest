//
//  ShimmerEffect.swift
//  Cryozest-2
//
//  Created by Owen Khoury on 10/9/25.
//  Modern shimmer loading effect for skeleton screens
//

import SwiftUI

// MARK: - Shimmer ViewModifier

struct Shimmer: ViewModifier {
    @State private var startPoint: UnitPoint = UnitPoint(x: -1.8, y: -1.8)
    @State private var endPoint: UnitPoint = UnitPoint(x: -0.8, y: -0.8)
    var duration: Double = 1.5

    func body(content: Content) -> some View {
        content
            .mask(
                LinearGradient(
                    stops: [
                        .init(color: .black.opacity(0.4), location: 0),
                        .init(color: .black, location: 0.5),
                        .init(color: .black.opacity(0.4), location: 1)
                    ],
                    startPoint: startPoint,
                    endPoint: endPoint
                )
            )
            .onAppear {
                withAnimation(
                    .linear(duration: duration)
                    .repeatForever(autoreverses: false)
                ) {
                    startPoint = UnitPoint(x: 1.0, y: 1.0)
                    endPoint = UnitPoint(x: 2.8, y: 2.8)
                }
            }
    }
}

extension View {
    func shimmer(duration: Double = 1.5) -> some View {
        modifier(Shimmer(duration: duration))
    }
}

// MARK: - Skeleton Card Components

struct SkeletonCard: View {
    var height: CGFloat = 100

    var body: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.white.opacity(0.10))
            .frame(height: height)
            .shimmer()
    }
}

struct SkeletonLine: View {
    var width: CGFloat? = nil
    var height: CGFloat = 16

    var body: some View {
        RoundedRectangle(cornerRadius: height / 2)
            .fill(Color.white.opacity(0.12))
            .frame(width: width, height: height)
            .shimmer()
    }
}

struct SkeletonCircle: View {
    var size: CGFloat = 40

    var body: some View {
        Circle()
            .fill(Color.white.opacity(0.12))
            .frame(width: size, height: size)
            .shimmer()
    }
}

#Preview {
    ZStack {
        Color(red: 0.06, green: 0.10, blue: 0.18)
            .ignoresSafeArea()

        VStack(spacing: 16) {
            SkeletonCard(height: 100)
            SkeletonLine(width: 200)
            SkeletonCircle(size: 50)
        }
        .padding()
    }
}
