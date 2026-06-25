import SwiftUI

extension Notification.Name {
    static let popToTabRoot = Notification.Name("popToTabRoot")
}

class TabBarVisibility: ObservableObject {
    @Published var isVisible = true
}

struct MainTabView: View {
    @EnvironmentObject var tokenManager: TokenManager
    @State private var selectedTab = 0
    @StateObject private var tabBarVisibility = TabBarVisibility()

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.screenBackground.ignoresSafeArea()

            TabView(selection: $selectedTab) {
                HomeView(tokenManager: tokenManager)
                    .tag(0)

                ReportsView(tokenManager: tokenManager)
                    .tag(1)

                MenageView(tokenManager: tokenManager)
                    .tag(2)

                ExpensesView(tokenManager: tokenManager)
                    .tag(3)

                ProfileView(tokenManager: tokenManager)
                    .tag(4)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .background(Color.screenBackground)

            if tabBarVisibility.isVisible {
                CustomTabBar(selectedTab: $selectedTab, onTabReselected: {
                    NotificationCenter.default.post(name: .popToTabRoot, object: nil)
                })
            }
        }
        .environmentObject(tabBarVisibility)
        .ignoresSafeArea(.keyboard)
    }
}

// MARK: - Custom Tab Bar

struct CustomTabBar: View {
    @Binding var selectedTab: Int
    var onTabReselected: () -> Void = {}

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                TabBarItem(icon: "house", label: "Accueil", isSelected: selectedTab == 0) {
                    if selectedTab == 0 { onTabReselected() } else { selectedTab = 0 }
                }
                TabBarItem(icon: "flag", label: "Signaler", isSelected: selectedTab == 1) {
                    if selectedTab == 1 { onTabReselected() } else { selectedTab = 1 }
                }
                TabBarItem(icon: "bubbles.and.sparkles", label: "Ménage", isSelected: selectedTab == 2) {
                    if selectedTab == 2 { onTabReselected() } else { selectedTab = 2 }
                }
                TabBarItem(icon: "chart.bar", label: "Dépenses", isSelected: selectedTab == 3) {
                    if selectedTab == 3 { onTabReselected() } else { selectedTab = 3 }
                }
                TabBarItem(icon: "person", label: "Profil", isSelected: selectedTab == 4) {
                    if selectedTab == 4 { onTabReselected() } else { selectedTab = 4 }
                }
            }
            .padding(.horizontal, 8)
            .padding(.top, 10)
            .padding(.bottom, 8)
        }
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: -4)
                .ignoresSafeArea(edges: .bottom)
        )
    }
}

private struct TabBarItem: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: { withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { action() } }) {
            VStack(spacing: 3) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(isSelected ? Color.greenPrimary.opacity(0.12) : Color.clear)
                        .frame(width: 52, height: 30)
                        .animation(.easeInOut(duration: 0.25), value: isSelected)

                    Image(systemName: icon)
                        .symbolVariant(isSelected ? .fill : .none)
                        .font(.system(size: 20))
                        .foregroundColor(isSelected ? .greenPrimary : .lightText)
                        .scaleEffect(isSelected ? 1.08 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
                }
                Text(label)
                    .font(.system(size: 10, weight: isSelected ? .bold : .medium))
                    .foregroundColor(isSelected ? .greenPrimary : .lightText)
                    .animation(.easeInOut(duration: 0.2), value: isSelected)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}
