import SwiftUI
import UIKit

struct CameraPickerView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    var sourceType: UIImagePickerController.SourceType
    @Environment(\.dismiss) private var dismiss

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPickerView
        init(_ parent: CameraPickerView) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            parent.image = info[.originalImage] as? UIImage
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

struct ReceiptLineItem: Identifiable {
    let id = UUID()
    let name: String
    var price: Double
    let category: String
}

struct AddReceiptView: View {
    @Environment(\.dismiss) private var dismiss
    private let tokenManager: TokenManager
    private let repo: ReceiptRepository
    private let storageRepo: StorageRepository
    private let catalogRepo: CatalogRepository

    @State private var store = ""
    @State private var date = Date()
    @State private var receiptItems: [ReceiptLineItem] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var capturedImage: UIImage?
    @State private var showCamera = false
    @State private var showPickerSource = false
    @State private var catalogArticles: [CatalogArticle] = []
    @State private var showCatalogPicker = false
    @State private var pendingArticle: CatalogArticle?
    @State private var priceInput = ""
    @State private var showPriceAlert = false
    @State private var isMyTurn = true
    @State private var currentPurchaserName = ""
    @State private var turnCheckDone = false

    private let rotationRepo: RotationRepository
    private let authRepo: AuthRepository

    init(tokenManager: TokenManager) {
        self.tokenManager = tokenManager
        let api = APIService.configure(tokenManager: tokenManager)
        self.repo = ReceiptRepository(api: api)
        self.storageRepo = StorageRepository(api: api)
        self.catalogRepo = CatalogRepository(api: api)
        self.rotationRepo = RotationRepository(api: api)
        self.authRepo = AuthRepository(api: api, tokenManager: tokenManager)
    }

    var totalAmount: Double {
        receiptItems.reduce(0) { $0 + $1.price }
    }

    var body: some View {
        NavigationStack {
            if !turnCheckDone {
                VStack {
                    Spacer()
                    ProgressView().tint(.greenPrimary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.screenBackground)
                .task { await checkTurn() }
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Fermer") { dismiss() }
                    }
                }
            } else if !isMyTurn {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "clock")
                        .font(.system(size: 48))
                        .foregroundColor(.appBlue)
                    Text("Ce n'est pas ton tour")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundColor(.darkText)
                    Text("C'est au tour de \(currentPurchaserName) de faire les courses.")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.subtitleText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.screenBackground)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Fermer") { dismiss() }
                    }
                }
            } else {
            ScrollView {
                VStack(spacing: 16) {
                    // Photo capture box
                    Button {
                        if UIImagePickerController.isSourceTypeAvailable(.camera) {
                            showPickerSource = true
                        } else {
                            showCamera = true
                        }
                    } label: {
                        ZStack {
                            if let img = capturedImage {
                                Image(uiImage: img)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 160)
                                    .clipped()
                                    .cornerRadius(18)
                                VStack {
                                    HStack {
                                        Spacer()
                                        Image(systemName: "arrow.clockwise")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.white)
                                            .padding(8)
                                            .background(Color.black.opacity(0.45))
                                            .cornerRadius(10)
                                            .padding(10)
                                    }
                                    Spacer()
                                }
                            } else {
                                RoundedRectangle(cornerRadius: 18)
                                    .fill(Color.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 160)
                                    .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
                                VStack(spacing: 10) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 14)
                                            .fill(Color.greenPrimary.opacity(0.12))
                                            .frame(width: 48, height: 48)
                                        Image(systemName: "camera")
                                            .font(.system(size: 22, weight: .medium))
                                            .foregroundColor(.greenPrimary)
                                    }
                                    Text("Photographier le ticket")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.darkText)
                                }
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .confirmationDialog("Ajouter une photo", isPresented: $showPickerSource) {
                        Button("Appareil photo") { showCamera = true }
                        Button("Galerie") { showCamera = false; showPickerSource = false }
                        Button("Annuler", role: .cancel) {}
                    }
                    .sheet(isPresented: $showCamera) {
                        CameraPickerView(image: $capturedImage, sourceType: .camera)
                            .ignoresSafeArea()
                    }

                    // Store & Date/Time
                    VStack(spacing: 14) {
                        AppTextField(placeholder: "Magasin (ex: Carrefour)", text: $store)
                        DatePicker("Date et heure", selection: $date, displayedComponents: [.date, .hourAndMinute])
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.bodyText)
                    }
                    .padding(18)
                    .background(Color.white)
                    .cornerRadius(22)
                    .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)

                    // Articles
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Articles")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(.darkText)
                            Spacer()
                            Button { showCatalogPicker = true } label: {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.greenPrimary)
                                    .font(.system(size: 22))
                            }
                        }

                        if receiptItems.isEmpty {
                            Text("Appuyez sur + pour ajouter un article")
                                .font(.system(size: 13))
                                .foregroundColor(.subtitleText)
                                .padding(.vertical, 4)
                        } else {
                            ForEach(receiptItems) { item in
                                HStack(spacing: 10) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.name)
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.bodyText)
                                        Text(item.category)
                                            .font(.system(size: 12))
                                            .foregroundColor(.subtitleText)
                                    }
                                    Spacer()
                                    Text(item.price.euroFormatted)
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(.darkText)
                                    Button {
                                        receiptItems.removeAll { $0.id == item.id }
                                    } label: {
                                        Image(systemName: "xmark")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.lightText)
                                            .padding(6)
                                    }
                                }
                                Divider()
                            }
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
                        disabled: store.isEmpty || receiptItems.isEmpty
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
            .task {
                guard let colId = tokenManager.colocationId else { return }
                catalogArticles = (try? await catalogRepo.getArticles(colocationId: colId)) ?? []
            }
            .sheet(isPresented: $showCatalogPicker) {
                CatalogPickerSheet(articles: catalogArticles) { article in
                    pendingArticle = article
                    showCatalogPicker = false
                    priceInput = ""
                    showPriceAlert = true
                }
            }
            .alert(pendingArticle?.name ?? "Prix", isPresented: $showPriceAlert) {
                TextField("0,00", text: $priceInput)
                    .keyboardType(.decimalPad)
                Button("Ajouter") {
                    if let article = pendingArticle,
                       let price = Double(priceInput.replacingOccurrences(of: ",", with: ".")),
                       price > 0 {
                        receiptItems.append(ReceiptLineItem(name: article.name, price: price, category: article.category))
                    }
                    pendingArticle = nil
                }
                Button("Annuler", role: .cancel) { pendingArticle = nil }
            } message: {
                Text("Entrez le prix pour \(pendingArticle?.name ?? "")")
            }
        } // else isMyTurn
        } // NavigationStack
    }

    private func checkTurn() async {
        guard let id = tokenManager.colocationId else {
            turnCheckDone = true
            return
        }
        let me = try? await authRepo.getMe()
        let rotation = (try? await rotationRepo.getRotation(colocationId: id)) ?? []
        let currentPurchaser = rotation.first { $0.status == "current" }
        isMyTurn = currentPurchaser == nil || currentPurchaser?.user.id == me?.id
        currentPurchaserName = currentPurchaser?.user.name ?? ""
        turnCheckDone = true
    }

    private func save() async {
        guard let colId = tokenManager.colocationId else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: date)

        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        let timeString = timeFormatter.string(from: date)

        let items = receiptItems.map { item in
            CreateReceiptItemRequest(name: item.name, price: item.price, quantity: 1, category: item.category)
        }

        var photoUrl: String?
        if let image = capturedImage {
            do {
                photoUrl = try await storageRepo.uploadImage(image)
            } catch {
                errorMessage = "Echec de l'upload photo : \(error.localizedDescription)"
                return
            }
        }

        do {
            _ = try await repo.createReceipt(
                colocationId: colId,
                store: store,
                date: dateString,
                time: timeString,
                totalAmount: totalAmount,
                photoUrl: photoUrl,
                items: items
            )
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct CatalogPickerSheet: View {
    let articles: [CatalogArticle]
    let onSelect: (CatalogArticle) -> Void

    @State private var searchQuery = ""

    var filtered: [CatalogArticle] {
        guard !searchQuery.isEmpty else { return articles }
        return articles.filter {
            $0.name.localizedCaseInsensitiveContains(searchQuery) ||
            $0.category.localizedCaseInsensitiveContains(searchQuery)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if articles.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "tray")
                            .font(.system(size: 40))
                            .foregroundColor(.borderColor)
                        Text("Aucun article dans le catalogue")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.subtitleText)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(filtered) { article in
                        Button {
                            onSelect(article)
                        } label: {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(article.name)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.darkText)
                                Text(article.category)
                                    .font(.system(size: 12))
                                    .foregroundColor(.subtitleText)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    .listStyle(.plain)
                    .searchable(text: $searchQuery, prompt: "Rechercher un article…")
                }
            }
            .navigationTitle("Choisir un article")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
