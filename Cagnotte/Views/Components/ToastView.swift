import SwiftUI

enum ToastType {
    case success, error, info
    var color: Color {
        switch self {
        case .success: return .greenPrimary
        case .error:   return .coralRed
        case .info:    return .appBlue
        }
    }
    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error:   return "xmark.circle.fill"
        case .info:    return "info.circle.fill"
        }
    }
}

struct ToastView: View {
    let message: String
    let type: ToastType

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: type.icon)
                .foregroundColor(type.color)
                .font(.system(size: 18))
            Text(message)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.darkText)
                .multilineTextAlignment(.leading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 4)
    }
}

// MARK: - Toast Modifier
struct ToastModifier: ViewModifier {
    @Binding var message: String?
    var type: ToastType = .error
    var duration: Double = 3.0

    func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            content
            if let msg = message {
                ToastView(message: msg, type: type)
                    .padding(.horizontal, 20)
                    .padding(.top, 60)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                            withAnimation { message = nil }
                        }
                    }
                    .zIndex(999)
            }
        }
        .animation(.spring(response: 0.4), value: message)
    }
}

extension View {
    func toast(message: Binding<String?>, type: ToastType = .error) -> some View {
        modifier(ToastModifier(message: message, type: type))
    }
}
