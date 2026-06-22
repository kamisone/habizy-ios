import SwiftUI

struct ShoppingListView: View {
    @EnvironmentObject var tokenManager: TokenManager
    @StateObject private var vm: ShoppingViewModel
    @State private var showAddCatalogDialog = false
    @State private var showCatalogPicker = false
    @State private var selectedArticle: CatalogArticle?
    @State private var quantityInput = 1

    init(tokenManager: TokenManager) {
        _vm = StateObject(wrappedValue: ShoppingViewModel(tokenManager: tokenManager))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    // Header
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Articles manquants")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(.darkText)
                        Text("\(vm.items.count) article\(vm.items.count != 1 ? "s" : "") a acheter")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.subtitleText)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 18)
                    .padding(.top, 16)

                    if vm.isLoading {
                        ProgressView().tint(.greenPrimary).padding(40)
                    } else {
                        // Add button
                        Button { showCatalogPicker = true } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "plus")
                                    .font(.system(size: 14, weight: .bold))
                                Text("Ajouter un article")
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.greenPrimary)
                            .cornerRadius(16)
                            .shadow(color: Color.greenDark.opacity(0.3), radius: 8, x: 0, y: 3)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 18)

                        // Missing items list
                        if vm.items.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "cart")
                                    .font(.system(size: 40))
                                    .foregroundColor(.borderColor)
                                Text("Rien a acheter")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundColor(.subtitleText)
                                Text("Ajoutez des articles depuis le catalogue")
                                    .font(.system(size: 13))
                                    .foregroundColor(.lightText)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 32)
                            .background(Color.white)
                            .cornerRadius(22)
                            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
                            .padding(.horizontal, 18)
                        } else {
                            VStack(spacing: 0) {
                                ForEach(vm.items) { item in
                                    HStack(spacing: 12) {
                                        Circle()
                                            .fill(Color.greenPrimary)
                                            .frame(width: 8, height: 8)
                                        Text(item.name)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.bodyText)
                                        Spacer()
                                        Text("x\(item.quantity)")
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(.subtitleText)
                                        Button { vm.delete(item: item) } label: {
                                            Image(systemName: "trash")
                                                .font(.system(size: 14))
                                                .foregroundColor(.coralRed)
                                                .padding(6)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)

                                    if item.id != vm.items.last?.id {
                                        Divider().padding(.leading, 36)
                                    }
                                }
                            }
                            .background(Color.white)
                            .cornerRadius(22)
                            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
                            .padding(.horizontal, 18)
                        }

                        // Admin catalogue management
                        if vm.isAdmin {
                            VStack(alignment: .leading, spacing: 0) {
                                HStack {
                                    Text("Gerer le catalogue")
                                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                                        .foregroundColor(.darkText)
                                    Spacer()
                                    Button { showAddCatalogDialog = true } label: {
                                        Image(systemName: "plus")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.greenPrimary)
                                            .padding(6)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.top, 14)
                                .padding(.bottom, 8)

                                if vm.catalogArticles.isEmpty {
                                    Text("Aucun article dans le catalogue")
                                        .font(.system(size: 13))
                                        .foregroundColor(.subtitleText)
                                        .padding(.horizontal, 16)
                                        .padding(.bottom, 14)
                                } else {
                                    ForEach(vm.catalogArticles) { article in
                                        HStack(spacing: 10) {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(article.name)
                                                    .font(.system(size: 14, weight: .semibold))
                                                    .foregroundColor(.bodyText)
                                                Text(article.category)
                                                    .font(.system(size: 12))
                                                    .foregroundColor(.subtitleText)
                                            }
                                            Spacer()
                                            Button { vm.deleteCatalogArticle(id: article.id) } label: {
                                                Image(systemName: "trash")
                                                    .font(.system(size: 14))
                                                    .foregroundColor(.coralRed)
                                                    .padding(8)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 10)
                                        Divider().padding(.leading, 16)
                                    }
                                }
                            }
                            .background(Color.white)
                            .cornerRadius(22)
                            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
                            .padding(.horizontal, 18)
                        }
                    }

                    Spacer(minLength: 80)
                }
            }
            .refreshable { await vm.refresh() }
            .background(Color.screenBackground.ignoresSafeArea())
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar(.hidden, for: .navigationBar)
            .onAppear { vm.load() }
            .toast(message: Binding(
                get: { vm.errorMessage },
                set: { vm.errorMessage = $0 }
            ), type: .error)
            .toast(message: Binding(
                get: { vm.successMessage },
                set: { vm.successMessage = $0 }
            ), type: .success)
            .sheet(isPresented: $showAddCatalogDialog) {
                AddCatalogArticleSheet(existingCategories: vm.categories) { name, category in
                    vm.addCatalogArticle(name: name, category: category)
                }
            }
            .sheet(isPresented: $showCatalogPicker) {
                CatalogPickerSheet(articles: vm.catalogArticles) { article in
                    showCatalogPicker = false
                    selectedArticle = article
                    quantityInput = 1
                }
            }
            .sheet(item: $selectedArticle) { article in
                QuantityPickerSheet(articleName: article.name, quantity: $quantityInput) {
                    vm.addItem(name: article.name, quantity: quantityInput, assigneeId: nil)
                    selectedArticle = nil
                }
            }
        }
    }
}

// MARK: - Catalogue Picker Sheet
struct CatalogPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    let articles: [CatalogArticle]
    let onSelect: (CatalogArticle) -> Void

    var body: some View {
        NavigationStack {
            Group {
                if articles.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "cart")
                            .font(.system(size: 40))
                            .foregroundColor(.borderColor)
                        Text("Le catalogue est vide")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.subtitleText)
                        Text("L'admin doit d'abord ajouter des articles")
                            .font(.system(size: 13))
                            .foregroundColor(.lightText)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(articles) { article in
                        Button {
                            onSelect(article)
                        } label: {
                            HStack(spacing: 12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.greenPrimary.opacity(0.1))
                                        .frame(width: 40, height: 40)
                                    Image(systemName: "cart")
                                        .font(.system(size: 15))
                                        .foregroundColor(.greenPrimary)
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(article.name)
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(.darkText)
                                    Text(article.category)
                                        .font(.system(size: 12))
                                        .foregroundColor(.subtitleText)
                                }
                                Spacer()
                                Image(systemName: "plus")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.greenPrimary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Choisir un article")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Quantity Picker Sheet
struct QuantityPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    let articleName: String
    @Binding var quantity: Int
    let onConfirm: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text(articleName)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.darkText)

                HStack(spacing: 20) {
                    Text("Quantite")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.subtitleText)
                    Spacer()
                    Button { if quantity > 1 { quantity -= 1 } } label: {
                        Image(systemName: "minus")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.darkText)
                            .frame(width: 36, height: 36)
                            .background(Color.lightCardBg)
                            .cornerRadius(10)
                    }
                    Text("\(quantity)")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.darkText)
                        .frame(minWidth: 28)
                    Button { quantity += 1 } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(Color.greenPrimary)
                            .cornerRadius(10)
                    }
                }

                Button {
                    onConfirm()
                    dismiss()
                } label: {
                    Text("Ajouter")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.greenPrimary)
                        .cornerRadius(14)
                }

                Spacer()
            }
            .padding(24)
            .navigationTitle("Ajouter a la liste")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
            }
            .presentationDetents([.height(260)])
        }
    }
}

// MARK: - Add Catalog Article Sheet
struct AddCatalogArticleSheet: View {
    @Environment(\.dismiss) private var dismiss
    let existingCategories: [String]
    let onDone: (String, String) -> Void

    @State private var name = ""
    @State private var categoryInput = ""

    private var filteredCategories: [String] {
        guard !categoryInput.isEmpty else { return existingCategories }
        return existingCategories.filter { $0.localizedCaseInsensitiveContains(categoryInput) }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Nom") { TextField("Ex: Lait", text: $name) }
                Section("Categorie") {
                    TextField("Ex: Alimentation", text: $categoryInput)
                    if !filteredCategories.isEmpty {
                        ForEach(filteredCategories, id: \.self) { cat in
                            Button {
                                categoryInput = cat
                            } label: {
                                HStack {
                                    Text(cat).foregroundColor(.darkText)
                                    Spacer()
                                    if categoryInput == cat {
                                        Image(systemName: "checkmark").foregroundColor(.greenPrimary)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Nouvel article")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Annuler") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Ajouter") {
                        onDone(name.trimmingCharacters(in: .whitespaces), categoryInput.trimmingCharacters(in: .whitespaces))
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || categoryInput.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
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
