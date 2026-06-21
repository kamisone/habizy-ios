import SwiftUI

struct ShoppingListView: View {
    @EnvironmentObject var tokenManager: TokenManager
    @StateObject private var vm: ShoppingViewModel
    @State private var showAddItem = false
    @State private var newItemName = ""
    @State private var newItemQty = 1
    @State private var selectedAssigneeId: String?

    init(tokenManager: TokenManager) {
        _vm = StateObject(wrappedValue: ShoppingViewModel(tokenManager: tokenManager))
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(spacing: 0) {
                        // Header
                        HStack {
                            Text("Liste de courses")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(.darkText)
                            Spacer()
                            Button { showAddItem = true } label: {
                                Image(systemName: "plus")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(10)
                                    .background(Color.greenPrimary)
                                    .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal, 18)
                        .padding(.top, 16)
                        .padding(.bottom, 12)

                        if vm.isLoading {
                            ProgressView().tint(.greenPrimary).padding(40)
                        } else if vm.items.isEmpty {
                            emptyState
                        } else {
                            itemsList
                        }
                    }
                }

                // Add item sheet handle
                if showAddItem {
                    addItemPanel
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .background(Color.screenBackground.ignoresSafeArea())
            .onAppear { vm.load() }
            .animation(.spring(response: 0.35), value: showAddItem)
            .toast(message: Binding(
                get: { vm.errorMessage },
                set: { vm.errorMessage = $0 }
            ), type: .error)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "cart")
                .font(.system(size: 48))
                .foregroundColor(.borderColor)
            Text("Liste vide")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(.subtitleText)
            Text("Ajoute des articles pour commencer")
                .font(.system(size: 14))
                .foregroundColor(.lightText)
        }
        .padding(60)
    }

    private var itemsList: some View {
        VStack(spacing: 0) {
            if !vm.uncheckedItems.isEmpty {
                sectionHeader("À acheter (\(vm.uncheckedItems.count))")
                ForEach(vm.uncheckedItems) { item in
                    ShoppingItemRow(item: item, onToggle: { vm.toggle(item: item) }, onDelete: { vm.delete(item: item) })
                }
            }
            if !vm.checkedItems.isEmpty {
                sectionHeader("Dans le panier (\(vm.checkedItems.count))")
                ForEach(vm.checkedItems) { item in
                    ShoppingItemRow(item: item, onToggle: { vm.toggle(item: item) }, onDelete: { vm.delete(item: item) })
                }
            }
        }
        .padding(.bottom, 100)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(.subtitleText)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 18)
            .padding(.top, 16)
            .padding(.bottom, 6)
    }

    private var addItemPanel: some View {
        VStack(spacing: 0) {
            Color.black.opacity(0.2)
                .ignoresSafeArea()
                .onTapGesture { showAddItem = false }

            VStack(spacing: 16) {
                Capsule().fill(Color.borderColor).frame(width: 40, height: 4)
                    .padding(.top, 8)

                Text("Ajouter un article")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.darkText)

                AppTextField(placeholder: "Nom de l'article", text: $newItemName)

                HStack {
                    Text("Quantité")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.subtitleText)
                    Spacer()
                    HStack(spacing: 16) {
                        Button { if newItemQty > 1 { newItemQty -= 1 } } label: {
                            Image(systemName: "minus")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.darkText)
                                .frame(width: 32, height: 32)
                                .background(Color.lightCardBg)
                                .cornerRadius(10)
                        }
                        Text("\(newItemQty)")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.darkText)
                            .frame(minWidth: 24)
                        Button { newItemQty += 1 } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 32, height: 32)
                                .background(Color.greenPrimary)
                                .cornerRadius(10)
                        }
                    }
                }

                PrimaryButton(title: "Ajouter", disabled: newItemName.isEmpty) {
                    vm.addItem(name: newItemName, quantity: newItemQty, assigneeId: selectedAssigneeId)
                    newItemName = ""
                    newItemQty = 1
                    showAddItem = false
                }

                Spacer(minLength: 20)
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .background(Color.white)
            .cornerRadius(28, corners: [.topLeft, .topRight])
        }
        .frame(maxHeight: .infinity, alignment: .bottom)
        .ignoresSafeArea()
    }
}

// MARK: - Shopping Item Row
struct ShoppingItemRow: View {
    let item: ShoppingItemResponse
    let onToggle: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                ZStack {
                    RoundedRectangle(cornerRadius: 7)
                        .stroke(item.isChecked ? Color.greenPrimary : Color.borderColor, lineWidth: 1.5)
                        .frame(width: 22, height: 22)
                    if item.isChecked {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.greenPrimary)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(item.isChecked ? .lightText : .bodyText)
                    .strikethrough(item.isChecked, color: .lightText)
                if let assignee = item.assignee {
                    Text(assignee.name)
                        .font(.system(size: 12))
                        .foregroundColor(.subtitleText)
                }
            }
            Spacer()
            Text("×\(item.quantity)")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.subtitleText)

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 14))
                    .foregroundColor(.coralRed)
                    .padding(8)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(Color.white)
        .overlay(Divider().padding(.leading, 18), alignment: .bottom)
    }
}

// MARK: - Corner Radius Helper
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = 0
    var corners: UIRectCorner = .allCorners
    func path(in rect: CGRect) -> Path {
        Path(UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius)).cgPath)
    }
}
