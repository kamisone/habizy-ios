import SwiftUI

struct CountingText: View {
    let targetValue: Double
    var duration: Double = 0.8
    var font: Font = .system(size: 32, weight: .bold, design: .rounded)
    var color: Color = .white

    @State private var displayValue: Double = 0

    private var formattedValue: String {
        displayValue.euroFormatted
    }

    var body: some View {
        Text(formattedValue)
            .font(font)
            .foregroundColor(color)
            .onAppear {
                withAnimation(.easeOut(duration: duration)) {
                    displayValue = targetValue
                }
            }
            .onChange(of: targetValue) { newValue in
                withAnimation(.easeOut(duration: duration)) {
                    displayValue = newValue
                }
            }
    }
}
