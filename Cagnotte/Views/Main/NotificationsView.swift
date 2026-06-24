import SwiftUI

struct NotificationsView: View {
    @StateObject private var vm: NotificationsViewModel
    @State private var hasAppeared = false

    init(tokenManager: TokenManager) {
        _vm = StateObject(wrappedValue: NotificationsViewModel(tokenManager: tokenManager))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                if vm.isLoading {
                    ProgressView().tint(.greenPrimary).padding(40)
                } else if vm.notifications.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "bell.slash")
                            .font(.system(size: 48))
                            .foregroundColor(.borderColor)
                        Text("Aucune notification")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(.subtitleText)
                    }
                    .padding(60)
                } else {
                    ForEach(vm.notifications) { notif in
                        NotificationRow(notification: notif)
                            .onTapGesture {
                                if !notif.isRead { vm.markRead(notification: notif) }
                            }
                    }
                }
            }
        }
        .background(Color.screenBackground.ignoresSafeArea())
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if vm.unreadCount > 0 {
                    Button("Tout lire") { vm.markAllRead() }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.greenPrimary)
                }
            }
        }
        .onAppear {
            if hasAppeared { Task { await vm.refresh() } } else { vm.load(); hasAppeared = true }
        }
    }
}

private struct NotificationRow: View {
    let notification: NotificationResponse
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(notification.isRead ? Color.lightCardBg : Color.greenPrimary.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: iconName)
                    .font(.system(size: 18))
                    .foregroundColor(notification.isRead ? .subtitleText : .greenPrimary)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(notification.message)
                    .font(.system(size: 14, weight: notification.isRead ? .regular : .semibold))
                    .foregroundColor(notification.isRead ? .bodyText : .darkText)
                    .lineLimit(2)
                if let date = notification.createdAt {
                    Text(date.prefix(10))
                        .font(.system(size: 11))
                        .foregroundColor(.lightText)
                }
            }
            Spacer()
            if !notification.isRead {
                Circle().fill(Color.greenPrimary).frame(width: 8, height: 8)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(notification.isRead ? Color.white : Color.greenPrimary.opacity(0.04))
        .overlay(Divider().padding(.leading, 76), alignment: .bottom)
    }

    private var iconName: String {
        switch notification.type {
        case "contribution": return "eurosign.circle.fill"
        case "shopping":     return "cart.fill"
        case "rotation":     return "arrow.triangle.2.circlepath"
        default:             return "bell.fill"
        }
    }
}
