//
//  ContextualTooltip.swift
//  Cryozest-2
//
//  Created by Owen Khoury on 10/9/25.
//

import SwiftUI

enum TooltipArrowPosition {
    case top
    case bottom
    case leading
    case trailing
}

struct ContextualTooltip: View {
    let message: String
    let arrowPosition: TooltipArrowPosition
    let accentColor: Color
    let onDismiss: () -> Void

    @State private var opacity: Double = 0
    @State private var offset: CGFloat = -10

    var body: some View {
        VStack(spacing: 0) {
            if arrowPosition == .bottom {
                tooltipContent
                arrow
            } else if arrowPosition == .top {
                arrow
                tooltipContent
            } else {
                HStack(spacing: 0) {
                    if arrowPosition == .trailing {
                        tooltipContent
                        horizontalArrow
                    } else {
                        horizontalArrow
                        tooltipContent
                    }
                }
            }
        }
        .opacity(opacity)
        .offset(y: offset)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                opacity = 1
                offset = 0
            }

            // Auto-dismiss after 5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                dismissTooltip()
            }
        }
    }

    private var tooltipContent: some View {
        HStack(spacing: 12) {
            Text(message)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            Button(action: dismissTooltip) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(accentColor)
                .shadow(color: accentColor.opacity(0.4), radius: 8, x: 0, y: 4)
        )
    }

    private var arrow: some View {
        Triangle()
            .fill(accentColor)
            .frame(width: 20, height: 10)
            .rotationEffect(.degrees(arrowPosition == .top ? 180 : 0))
    }

    private var horizontalArrow: some View {
        Triangle()
            .fill(accentColor)
            .frame(width: 10, height: 20)
            .rotationEffect(.degrees(arrowPosition == .leading ? 90 : -90))
    }

    private func dismissTooltip() {
        withAnimation(.easeOut(duration: 0.3)) {
            opacity = 0
            offset = -10
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onDismiss()
        }
    }
}

// Triangle shape for tooltip arrow
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// View modifier for easy tooltip attachment
struct TooltipModifier: ViewModifier {
    let message: String
    let isShowing: Bool
    let arrowPosition: TooltipArrowPosition
    let accentColor: Color
    let onDismiss: () -> Void

    func body(content: Content) -> some View {
        ZStack(alignment: alignment) {
            content

            if isShowing {
                ContextualTooltip(
                    message: message,
                    arrowPosition: arrowPosition,
                    accentColor: accentColor,
                    onDismiss: onDismiss
                )
                .offset(tooltipOffset)
                .zIndex(1000)
            }
        }
    }

    private var alignment: Alignment {
        switch arrowPosition {
        case .top: return .bottom
        case .bottom: return .top
        case .leading: return .trailing
        case .trailing: return .leading
        }
    }

    private var tooltipOffset: CGSize {
        switch arrowPosition {
        case .top: return CGSize(width: 0, height: 10)
        case .bottom: return CGSize(width: 0, height: -10)
        case .leading: return CGSize(width: 10, height: 0)
        case .trailing: return CGSize(width: -10, height: 0)
        }
    }
}

extension View {
    func contextualTooltip(
        message: String,
        isShowing: Bool,
        arrowPosition: TooltipArrowPosition = .bottom,
        accentColor: Color = .cyan,
        onDismiss: @escaping () -> Void
    ) -> some View {
        self.modifier(TooltipModifier(
            message: message,
            isShowing: isShowing,
            arrowPosition: arrowPosition,
            accentColor: accentColor,
            onDismiss: onDismiss
        ))
    }
}
