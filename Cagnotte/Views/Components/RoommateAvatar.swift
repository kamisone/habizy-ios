import SwiftUI

struct RoommateAvatar: View {
    let colorHex: String
    let initial: String
    var size: CGFloat = 44
    var cornerRadius: CGFloat = 15
    var fontSize: CGFloat = 17

    init(user: UserResponse, size: CGFloat = 44, cornerRadius: CGFloat = 15, fontSize: CGFloat = 17) {
        self.colorHex = user.colorHex ?? "#888888"
        self.initial = user.initial ?? String(user.name.prefix(1)).uppercased()
        self.size = size
        self.cornerRadius = cornerRadius
        self.fontSize = fontSize
    }

    init(colorHex: String, initial: String, size: CGFloat = 44, cornerRadius: CGFloat = 15, fontSize: CGFloat = 17) {
        self.colorHex = colorHex
        self.initial = initial
        self.size = size
        self.cornerRadius = cornerRadius
        self.fontSize = fontSize
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color(hex: colorHex).opacity(0.22))
                .frame(width: size, height: size)
            Text(initial)
                .font(.system(size: fontSize, weight: .semibold, design: .rounded))
                .foregroundColor(Color(hex: colorHex))
        }
    }
}
