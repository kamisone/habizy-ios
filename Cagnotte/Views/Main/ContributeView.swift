import SwiftUI

struct ContributeView: View {
    @StateObject private var vm: ContributeViewModel

    init(tokenManager: TokenManager) {
        _vm = StateObject(wrappedValue: ContributeViewModel(tokenManager: tokenManager))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if vm.isLoading {
                    ProgressView().tint(.greenPrimary).padding(40)
                } else {
                    // Balance card
                    if let balance = vm.balance {
                        balanceCard(balance)
                    }

                    // Cycle status
                    if let cycle = vm.cycleStatus {
                        cycleCard(cycle)
                    }

                    // Contribute form
                    contributeForm
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .padding(.bottom, 40)
        }
        .background(Color.screenBackground.ignoresSafeArea())
        .navigationTitle("Cotiser")
        .navigationBarTitleDisplayMode(.large)
        .onAppear { vm.load() }
        .toast(message: Binding(
            get: { vm.errorMessage },
            set: { vm.errorMessage = $0 }
        ), type: .error)
        .toast(message: Binding(
            get: { vm.successMessage },
            set: { vm.successMessage = $0 }
        ), type: .success)
    }

    private func balanceCard(_ balance: BalanceResponse) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Solde actuel")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.85))
            Text(balance.balance.euroFormatted)
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text("Total cotisé: \(balance.totalContributed.euroFormatted)")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LinearGradient.greenGradient)
        .cornerRadius(22)
        .shadow(color: Color.greenDark.opacity(0.3), radius: 10, x: 0, y: 4)
    }

    private func cycleCard(_ cycle: CycleStatusResponse) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Cycle \(cycle.cycleNumber)")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.darkText)
                Spacer()
                Text("\(cycle.paidCount)/\(cycle.totalMembers) payé")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.greenPrimary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.lightCardBg).frame(height: 8)
                    Capsule().fill(Color.greenPrimary)
                        .frame(
                            width: cycle.totalMembers > 0
                                ? geo.size.width * CGFloat(cycle.paidCount) / CGFloat(cycle.totalMembers)
                                : 0,
                            height: 8
                        )
                }
            }
            .frame(height: 8)

            ForEach(cycle.contributions, id: \.user.id) { item in
                HStack(spacing: 10) {
                    RoommateAvatar(user: item.user, size: 34, cornerRadius: 11)
                    Text(item.user.name)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.bodyText)
                    Spacer()
                    Image(systemName: item.hasPaid ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(item.hasPaid ? .greenPrimary : .borderColor)
                        .font(.system(size: 18))
                }
            }
        }
        .padding(18)
        .background(Color.white)
        .cornerRadius(22)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }

    private var contributeForm: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Faire une cotisation")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.darkText)

            if let defaultAmt = vm.defaultAmount {
                Text("Montant suggéré: \(defaultAmt.euroFormatted)")
                    .font(.system(size: 13))
                    .foregroundColor(.subtitleText)
            }

            AppTextField(placeholder: "Montant (€)", text: $vm.contributionAmount)
                .keyboardType(.decimalPad)

            PrimaryButton(
                title: "Cotiser",
                isLoading: vm.isContributing,
                disabled: vm.contributionAmount.isEmpty
            ) {
                vm.contribute()
            }
        }
        .padding(18)
        .background(Color.white)
        .cornerRadius(22)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}
