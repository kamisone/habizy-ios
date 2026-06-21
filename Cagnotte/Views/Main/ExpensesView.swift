import SwiftUI

struct ExpensesView: View {
    @EnvironmentObject var tokenManager: TokenManager
    @StateObject private var vm: ExpensesViewModel

    init(tokenManager: TokenManager) {
        _vm = StateObject(wrappedValue: ExpensesViewModel(tokenManager: tokenManager))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Text("Dépenses")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.darkText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 18)
                        .padding(.top, 16)

                    if vm.isLoading {
                        ProgressView().tint(.greenPrimary).padding(40)
                    } else {
                        if let stats = vm.stats {
                            statsSection(stats)
                        }
                        receiptsSection
                    }
                }
                .padding(.bottom, 100)
            }
            .background(Color.screenBackground.ignoresSafeArea())
            .onAppear { vm.load() }
            .toast(message: Binding(
                get: { vm.errorMessage },
                set: { vm.errorMessage = $0 }
            ), type: .error)
        }
    }

    private func statsSection(_ stats: ExpenseStatsResponse) -> some View {
        VStack(spacing: 12) {
            // Total
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total dépensé")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.subtitleText)
                    Text(stats.totalSpent.euroFormatted)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.darkText)
                }
                Spacer()
                Image(systemName: "receipt")
                    .font(.system(size: 28))
                    .foregroundColor(.greenPrimary)
            }
            .padding(18)
            .background(Color.white)
            .cornerRadius(22)
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
            .padding(.horizontal, 18)

            // By category
            if !stats.byCategory.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Par catégorie")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.darkText)
                    ForEach(stats.byCategory) { cat in
                        CategoryRow(stat: cat)
                    }
                }
                .padding(18)
                .background(Color.white)
                .cornerRadius(22)
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
                .padding(.horizontal, 18)
            }

            // By roommate
            if !stats.byRoommate.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Par colocataire")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.darkText)
                    ForEach(stats.byRoommate) { stat in
                        HStack(spacing: 10) {
                            if let user = stat.user {
                                RoommateAvatar(user: user, size: 36, cornerRadius: 12)
                                Text(user.name)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.bodyText)
                            } else {
                                Text("Inconnu")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.bodyText)
                            }
                            Spacer()
                            Text(stat.total.euroFormatted)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.darkText)
                        }
                    }
                }
                .padding(18)
                .background(Color.white)
                .cornerRadius(22)
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
                .padding(.horizontal, 18)
            }
        }
    }

    private var receiptsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Tickets de caisse")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.darkText)
                .padding(.horizontal, 18)

            if vm.receipts.isEmpty {
                Text("Aucun ticket enregistré")
                    .font(.system(size: 14))
                    .foregroundColor(.subtitleText)
                    .padding(.horizontal, 18)
            } else {
                ForEach(vm.receipts) { receipt in
                    ReceiptRow(receipt: receipt)
                }
            }
        }
    }
}

private struct CategoryRow: View {
    let stat: CategoryStat
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(stat.category)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.bodyText)
                Spacer()
                Text(stat.total.euroFormatted)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.darkText)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.lightCardBg).frame(height: 6)
                    Capsule().fill(Color.greenPrimary).frame(width: geo.size.width * CGFloat(stat.fraction), height: 6)
                }
            }
            .frame(height: 6)
        }
    }
}

struct ReceiptRow: View {
    let receipt: ReceiptResponse
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.greenPrimary.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: "bag")
                    .font(.system(size: 18))
                    .foregroundColor(.greenPrimary)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(receipt.store)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.darkText)
                Text(receipt.user.name)
                    .font(.system(size: 12))
                    .foregroundColor(.subtitleText)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(receipt.totalAmount.euroFormatted)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.darkText)
                Text(receipt.date.prefix(10))
                    .font(.system(size: 11))
                    .foregroundColor(.lightText)
            }
        }
        .padding(14)
        .background(Color.white)
        .cornerRadius(18)
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
        .padding(.horizontal, 18)
    }
}
