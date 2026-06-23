import SwiftUI

class TabBarVisibility: ObservableObject {
    @Published var isVisible = true
}

struct MainTabView: View {
    @EnvironmentObject var tokenManager: TokenManager
    @State private var selectedTab = 0
    @State private var showAddReceipt = false
    @StateObject private var tabBarVisibility = TabBarVisibility()

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.screenBackground.ignoresSafeArea()

            TabView(selection: $selectedTab) {
                HomeView(tokenManager: tokenManager)
                    .tag(0)

                ReportsView(tokenManager: tokenManager)
                    .tag(1)

                ExpensesView(tokenManager: tokenManager)
                    .tag(2)

                ProfileView(tokenManager: tokenManager)
                    .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .background(Color.screenBackground)

            if tabBarVisibility.isVisible {
                CustomTabBar(selectedTab: $selectedTab, onAddTapped: {
                    showAddReceipt = true
                })
            }
        }
        .environmentObject(tabBarVisibility)
        .ignoresSafeArea(.keyboard)
        .sheet(isPresented: $showAddReceipt) {
            AddReceiptView(tokenManager: tokenManager)
        }
    }
}

// MARK: - Custom Tab Bar

struct CustomTabBar: View {
    @Binding var selectedTab: Int
    let onAddTapped: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                TabBarItem(icon: "house", label: "Accueil", isSelected: selectedTab == 0) {
                    selectedTab = 0
                }
                TabBarItem(icon: "flag", label: "Signaler", isSelected: selectedTab == 1) {
                    selectedTab = 1
                }

                // FAB placeholder + button
                Button(action: onAddTapped) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient.greenGradient)
                            .frame(width: 56, height: 56)
                            .shadow(color: Color.greenDark.opacity(0.4), radius: 8, x: 0, y: 4)
                        Image(systemName: "plus")
                            .foregroundColor(.white)
                            .font(.system(size: 22, weight: .bold))
                    }
                }
                .offset(y: -10)
                .frame(width: 80)

                TabBarItem(icon: "chart.bar", label: "Dépenses", isSelected: selectedTab == 2) {
                    selectedTab = 2
                }
                TabBarItem(icon: "person", label: "Profil", isSelected: selectedTab == 3) {
                    selectedTab = 3
                }
            }
            .padding(.horizontal, 8)
            .padding(.top, 12)
            .padding(.bottom, 8)
        }
        .background(Color.white.opacity(0.92))
        .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: -4)
    }
}

private struct TabBarItem: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: { withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { action() } }) {
            VStack(spacing: 4) {
                Image(systemName: isSelected ? "\(icon).fill" : icon)
                    .font(.system(size: 22))
                    .foregroundColor(isSelected ? .greenPrimary : .lightText)
                    .scaleEffect(isSelected ? 1.1 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
                Text(label)
                    .font(.system(size: 10, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .greenPrimary : .lightText)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}
