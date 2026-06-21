import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var tokenManager: TokenManager
    @State private var selectedTab = 0
    @State private var showAddReceipt = false

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                HomeView(tokenManager: tokenManager)
                    .tag(0)

                ShoppingListView(tokenManager: tokenManager)
                    .tag(1)

                ExpensesView(tokenManager: tokenManager)
                    .tag(2)

                ProfileView(tokenManager: tokenManager)
                    .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            // Custom bottom bar
            CustomTabBar(selectedTab: $selectedTab, onAddTapped: {
                showAddReceipt = true
            })
        }
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
        HStack(spacing: 0) {
            TabBarItem(icon: "house", label: "Accueil", isSelected: selectedTab == 0) {
                selectedTab = 0
            }
            TabBarItem(icon: "cart", label: "Courses", isSelected: selectedTab == 1) {
                selectedTab = 1
            }

            // Center FAB
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
        .background(
            Color.white
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: -4)
        )
    }
}

private struct TabBarItem: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: isSelected ? "\(icon).fill" : icon)
                    .font(.system(size: 22))
                    .foregroundColor(isSelected ? .greenPrimary : .lightText)
                Text(label)
                    .font(.system(size: 10, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .greenPrimary : .lightText)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}
