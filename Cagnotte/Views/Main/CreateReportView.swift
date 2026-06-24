import SwiftUI
import AVFoundation

struct CreateReportView: View {
    @Environment(\.dismiss) private var dismiss
    private let tokenManager: TokenManager
    private let repo: ReportRepository
    private let storageRepo: StorageRepository
    let onCreated: () -> Void

    @State private var title = ""
    @State private var description = ""
    @State private var selectedTags: Set<String> = []
    @State private var capturedImages: [UIImage] = []
    @State private var showCamera = false
    @State private var showCameraUnavailable = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var availableTags: [ReportTagResponse] = []

    init(tokenManager: TokenManager, onCreated: @escaping () -> Void) {
        self.tokenManager = tokenManager
        let api = APIService.configure(tokenManager: tokenManager)
        self.repo = ReportRepository(api: api)
        self.storageRepo = StorageRepository(api: api)
        self.onCreated = onCreated
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Photos
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Photos").font(.system(size: 16, weight: .semibold, design: .rounded)).foregroundColor(.darkText)
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 8) {
                            ForEach(capturedImages.indices, id: \.self) { index in
                                ZStack(alignment: .topTrailing) {
                                    Image(uiImage: capturedImages[index]).resizable().scaledToFill().frame(width: 80, height: 80).clipped().cornerRadius(14)
                                    Button { capturedImages.remove(at: index) } label: {
                                        Image(systemName: "xmark").font(.system(size: 10, weight: .bold)).foregroundColor(.white).padding(4).background(Color.black.opacity(0.5)).clipShape(Circle())
                                    }.offset(x: -4, y: 4)
                                }
                            }
                            Button {
                                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                                    let status = AVCaptureDevice.authorizationStatus(for: .video)
                                    if status == .denied || status == .restricted {
                                        showCameraUnavailable = true
                                    } else {
                                        showCamera = true
                                    }
                                } else {
                                    showCameraUnavailable = true
                                }
                            } label: {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 14).fill(Color.lightCardBg).frame(width: 80, height: 80)
                                    Image(systemName: "camera").font(.system(size: 20)).foregroundColor(.subtitleText)
                                }
                            }.buttonStyle(.plain)
                        }
                    }.padding(16).background(Color.white).cornerRadius(22).shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)

                    AppTextField(placeholder: "Titre du signalement", text: $title)

                    VStack(alignment: .leading) {
                        Text("Description (optionnel)").font(.system(size: 13, weight: .medium)).foregroundColor(.subtitleText)
                        TextEditor(text: $description).frame(height: 100).padding(8).background(Color.white).cornerRadius(14)
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.borderColor, lineWidth: 1))
                    }

                    // Tags
                    Text("Tags (optionnel)").font(.system(size: 16, weight: .semibold, design: .rounded)).foregroundColor(.darkText)
                    WrappingHStack(spacing: 8) {
                        ForEach(availableTags) { tag in
                            let selected = selectedTags.contains(tag.title)
                            let color = parseTagColor(tag.color)
                            Button { if selected { selectedTags.remove(tag.title) } else { selectedTags.insert(tag.title) } } label: {
                                Text(tag.title).font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(selected ? .white : color)
                                    .padding(.horizontal, 14).padding(.vertical, 8)
                                    .background(selected ? color : color.opacity(0.12)).cornerRadius(20)
                            }.buttonStyle(.plain)
                        }
                    }
                    .onAppear {
                        if let id = tokenManager.colocationId {
                            let api = APIService.configure(tokenManager: tokenManager)
                            Task { availableTags = (try? await api.getReportTags(colocationId: id)) ?? [] }
                        }
                    }

                    if let err = errorMessage {
                        Text(err).font(.system(size: 13, weight: .medium)).foregroundColor(.coralRed)
                    }
                }.padding(18)
            }
            .background(Color.screenBackground.ignoresSafeArea())
            .navigationTitle("Nouveau signalement").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Annuler") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button { save() } label: {
                        if isLoading { ProgressView().tint(.greenPrimary) } else { Text("Envoyer").fontWeight(.semibold) }
                    }.disabled(title.trimmingCharacters(in: .whitespaces).isEmpty || isLoading)
                }
            }
            .sheet(isPresented: $showCamera) {
                CameraPickerView(image: Binding(get: { nil }, set: { if let img = $0 { capturedImages.append(img) } }), sourceType: .camera)
            }
            .alert("Caméra indisponible", isPresented: $showCameraUnavailable) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("L'accès à la caméra est désactivé. Activez-le dans Réglages > Habizy.")
            }
        }
    }

    private func save() {
        guard let colId = tokenManager.colocationId else { return }
        isLoading = true; errorMessage = nil
        Task {
            defer { isLoading = false }
            var uploadedUrls: [String] = []
            for image in capturedImages {
                do {
                    let url = try await storageRepo.uploadImage(image, folder: "reports")
                    uploadedUrls.append(url)
                } catch {
                    errorMessage = "Echec upload photo"; return
                }
            }
            do {
                _ = try await repo.create(body: CreateReportRequest(
                    colocationId: colId,
                    title: title.trimmingCharacters(in: .whitespaces),
                    description: description.trimmingCharacters(in: .whitespaces).isEmpty ? nil : description.trimmingCharacters(in: .whitespaces),
                    tags: selectedTags.isEmpty ? nil : Array(selectedTags),
                    photoUrls: uploadedUrls.isEmpty ? nil : uploadedUrls
                ))
                onCreated(); dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

struct WrappingHStack<Content: View>: View {
    let spacing: CGFloat
    @ViewBuilder let content: () -> Content

    init(spacing: CGFloat = 8, @ViewBuilder content: @escaping () -> Content) {
        self.spacing = spacing
        self.content = content
    }

    var body: some View {
        FlowLayoutView(spacing: spacing) { content() }
    }
}
