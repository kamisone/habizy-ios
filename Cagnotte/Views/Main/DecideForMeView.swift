import SwiftUI

struct DecideForMeView: View {
    @StateObject private var vm: ShoppingViewModel
    @State private var decidedItem: ShoppingItemResponse?
    @State private var isSpinning = false
    @State private var showResult = false
    @State private var hasAppeared = false

    init(tokenManager: TokenManager) {
        _vm = StateObject(wrappedValue: ShoppingViewModel(tokenManager: tokenManager))
    }

    var unchecked: [ShoppingItemResponse] { vm.uncheckedItems }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Wheel / animation area
                ZStack {
                    Circle()
                        .fill(LinearGradient.greenGradient)
                        .frame(width: 180, height: 180)
                        .shadow(color: Color.greenDark.opacity(0.3), radius: 16, x: 0, y: 6)

                    if let item = decidedItem, showResult {
                        VStack(spacing: 6) {
                            Image(systemName: "bag.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.white)
                            Text(item.name)
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 16)
                        }
                    } else {
                        Image(systemName: "dice.fill")
                            .font(.system(size: 52))
                            .foregroundColor(.white)
                            .rotationEffect(.degrees(isSpinning ? 360 : 0))
                            .animation(isSpinning ? .linear(duration: 0.4).repeatForever(autoreverses: false) : .default, value: isSpinning)
                    }
                }
                .padding(.top, 40)

                if showResult, let item = decidedItem {
                    VStack(spacing: 8) {
                        Text("Tu dois acheter…")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.subtitleText)
                        Text(item.name)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.darkText)
                        Text("×\(item.quantity)")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.subtitleText)
                    }
                } else if vm.isLoading {
                    ProgressView().tint(.greenPrimary)
                } else if unchecked.isEmpty {
                    Text("La liste de courses est vide !")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.subtitleText)
                } else {
                    Text("Laisse le hasard choisir !")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.subtitleText)
                }

                Button {
                    guard !unchecked.isEmpty else { return }
                    isSpinning = true
                    showResult = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        isSpinning = false
                        decidedItem = unchecked.randomElement()
                        withAnimation(.spring(response: 0.5)) { showResult = true }
                    }
                } label: {
                    Text(showResult ? "Relancer" : "Décide pour moi !")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(unchecked.isEmpty ? Color.greenPrimary.opacity(0.4) : Color.greenPrimary)
                        .cornerRadius(22)
                        .shadow(color: Color.greenPrimary.opacity(0.4), radius: 10, x: 0, y: 4)
                }
                .disabled(unchecked.isEmpty || isSpinning)

                // Item list
                if !unchecked.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Articles disponibles (\(unchecked.count))")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.subtitleText)
                        ForEach(unchecked) { item in
                            HStack {
                                Text(item.name)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(decidedItem?.id == item.id ? .greenPrimary : .bodyText)
                                Spacer()
                                Text("×\(item.quantity)")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.subtitleText)
                            }
                            .padding(12)
                            .background(decidedItem?.id == item.id ? Color.greenPrimary.opacity(0.08) : Color.white)
                            .cornerRadius(12)
                        }
                    }
                    .padding(16)
                    .background(Color.white)
                    .cornerRadius(22)
                    .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
                }

                Spacer(minLength: 40)
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 16)
        }
        .background(Color.screenBackground.ignoresSafeArea())
        .navigationTitle("Décide pour moi")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            if hasAppeared { Task { await vm.refresh() } } else { vm.load(); hasAppeared = true }
        }
    }
}
