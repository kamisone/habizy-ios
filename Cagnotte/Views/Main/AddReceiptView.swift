import SwiftUI

struct AddReceiptView: View {
    @Environment(\.dismiss) private var dismiss
    private let tokenManager: TokenManager
    private let repo: ReceiptRepository

    @State private var store = ""
    @State private var date = Date()
    @State private var items: [DraftItem] = [DraftItem()]
    @State private var isLoading = false
    @State private var errorMessage: String?

    struct DraftItem: Identifiable {
        let id = UUID()
        var name = ""
        var price = ""
        var quantity = "1"
        var category = "Alimentation"
    }

    static let categories = ["Alimentation", "Hygiène", "Ménage", "Boissons", "Autre"]

    init(tokenManager: TokenManager) {
        self.tokenManager = tokenManager
        let api = APIService.configure(tokenManager: tokenManager)
        self.repo = ReceiptRepository(api: api)
    }

    var totalAmount: Double {
        items.compactMap { item -> Double? in
            guard let price = Double(item.price.replacingOccurrences(of: ",", with: ".")),
                  let qty = Int(item.quantity) else { return nil }
            return price * Double(qty)
        }.reduce(0, +)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Store & Date
                    VStack(spacing: 14) {
                        AppTextField(placeholder: "Magasin (ex: Carrefour)", text: $store)
                        DatePicker("Date", selection: $date, displayedComponents: .date)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.bodyText)
                    }
                    .padding(18)
                    .background(Color.white)
                    .cornerRadius(22)
                    .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)

                    // Items
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text("Articles")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(.darkText)
                            Spacer()
                            Button {
                                items.append(DraftItem())
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.greenPrimary)
                                    .font(.system(size: 22))
                            }
                        }

                        ForEach($items) { $item in
                            ItemFormRow(item: $item, onDelete: {
                                items.removeAll { $0.id == item.id }
                            })
                        }
                    }
                    .padding(18)
                    .background(Color.white)
                    .cornerRadius(22)
                    .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)

                    // Total
                    HStack {
                        Text("Total")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.darkText)
                        Spacer()
                        Text(totalAmount.euroFormatted)
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(.greenPrimary)
                    }
                    .padding(18)
                    .background(Color.white)
                    .cornerRadius(22)
                    .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)

                    if let err = errorMessage {
                        Text(err)
                            .font(.caption)
                            .foregroundColor(.coralRed)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    PrimaryButton(
                        title: "Enregistrer le ticket",
                        isLoading: isLoading,
                        disabled: store.isEmpty || items.isEmpty || totalAmount == 0
                    ) {
                        Task { await save() }
                    }

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
            }
            .background(Color.screenBackground.ignoresSafeArea())
            .navigationTitle("Nouveau ticket")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
            }
        }
    }

    private func save() async {
        guard let colId = tokenManager.colocationId else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: date)

        let receiptItems = items.compactMap { item -> CreateReceiptItemRequest? in
            guard !item.name.isEmpty,
                  let price = Double(item.price.replacingOccurrences(of: ",", with: ".")),
                  let qty = Int(item.quantity) else { return nil }
            return CreateReceiptItemRequest(name: item.name, price: price, quantity: qty, category: item.category)
        }

        do {
            _ = try await repo.createReceipt(
                colocationId: colId,
                store: store,
                date: dateString,
                totalAmount: totalAmount,
                items: receiptItems
            )
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct ItemFormRow: View {
    @Binding var item: AddReceiptView.DraftItem
    let onDelete: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                AppTextField(placeholder: "Nom de l'article", text: $item.name)
                Button(action: onDelete) {
                    Image(systemName: "minus.circle.fill")
                        .foregroundColor(.coralRed)
                        .font(.system(size: 22))
                }
            }
            HStack(spacing: 10) {
                AppTextField(placeholder: "Prix (€)", text: $item.price)
                    .keyboardType(.decimalPad)
                    .frame(maxWidth: .infinity)
                AppTextField(placeholder: "Qté", text: $item.quantity)
                    .keyboardType(.numberPad)
                    .frame(width: 60)
            }
            Picker("Catégorie", selection: $item.category) {
                ForEach(AddReceiptView.categories, id: \.self) { cat in
                    Text(cat).tag(cat)
                }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.lightCardBg)
            .cornerRadius(10)
        }
        .padding(12)
        .background(Color.lightCardBg)
        .cornerRadius(14)
    }
}
