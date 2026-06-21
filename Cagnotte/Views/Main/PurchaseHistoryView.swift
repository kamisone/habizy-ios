import SwiftUI

struct PurchaseHistoryView: View {
    @StateObject private var vm: ReceiptViewModel
    @State private var selectedReceipt: ReceiptResponse?

    init(tokenManager: TokenManager) {
        _vm = StateObject(wrappedValue: ReceiptViewModel(tokenManager: tokenManager))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                if vm.isLoading {
                    ProgressView().tint(.greenPrimary).padding(40)
                } else if vm.receipts.isEmpty {
                    emptyState
                } else {
                    ForEach(vm.receipts) { receipt in
                        ReceiptRow(receipt: receipt)
                            .onTapGesture { selectedReceipt = receipt }
                            .padding(.bottom, 1)
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .padding(.bottom, 40)
        }
        .background(Color.screenBackground.ignoresSafeArea())
        .navigationTitle("Historique")
        .navigationBarTitleDisplayMode(.large)
        .onAppear { vm.load() }
        .sheet(item: $selectedReceipt) { receipt in
            ReceiptDetailSheet(receipt: receipt)
        }
        .toast(message: Binding(
            get: { vm.errorMessage },
            set: { vm.errorMessage = $0 }
        ), type: .error)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 48))
                .foregroundColor(.borderColor)
            Text("Aucun achat enregistré")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(.subtitleText)
        }
        .padding(60)
    }
}

private struct ReceiptDetailSheet: View {
    let receipt: ReceiptResponse
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Header
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.greenPrimary.opacity(0.12))
                                .frame(width: 56, height: 56)
                            Image(systemName: "bag.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.greenPrimary)
                        }
                        VStack(alignment: .leading, spacing: 3) {
                            Text(receipt.store)
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(.darkText)
                            Text("par \(receipt.user.name) · \(receipt.date.prefix(10))")
                                .font(.system(size: 13))
                                .foregroundColor(.subtitleText)
                        }
                    }

                    // Total
                    HStack {
                        Text("Total")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.darkText)
                        Spacer()
                        Text(receipt.totalAmount.euroFormatted)
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(.greenPrimary)
                    }
                    .padding(16)
                    .background(Color.lightCardBg)
                    .cornerRadius(16)

                    // Items
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Articles (\(receipt.items.count))")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(.darkText)

                        ForEach(receipt.items) { item in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.name)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.bodyText)
                                    Text("\(item.category) · ×\(item.quantity)")
                                        .font(.system(size: 11))
                                        .foregroundColor(.subtitleText)
                                }
                                Spacer()
                                Text((item.price * Double(item.quantity)).euroFormatted)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.darkText)
                            }
                            .padding(12)
                            .background(Color.white)
                            .cornerRadius(12)
                        }
                    }

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
            }
            .background(Color.screenBackground.ignoresSafeArea())
            .navigationTitle("Ticket")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { dismiss() }
                }
            }
        }
    }
}
