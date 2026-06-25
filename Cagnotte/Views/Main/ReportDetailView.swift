import SwiftUI

struct ReportDetailView: View {
    let reportId: String
    let tokenManager: TokenManager
    @StateObject private var vm: ReportDetailViewModel
    @EnvironmentObject private var tabBarVisibility: TabBarVisibility
    @Environment(\.dismiss) private var dismiss
    @State private var commentText = ""
    @State private var showEditSheet = false
    @State private var showDeleteConfirm = false

    init(reportId: String, tokenManager: TokenManager) {
        self.reportId = reportId
        self.tokenManager = tokenManager
        _vm = StateObject(wrappedValue: ReportDetailViewModel(tokenManager: tokenManager))
    }

    var body: some View {
        VStack(spacing: 0) {
            if vm.isLoading {
                Spacer(); ProgressView().tint(.greenPrimary); Spacer()
            } else if let detail = vm.detail {
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        // Photos
                        if let urls = detail.photoUrls, !urls.isEmpty {
                            ImageCarousel(imageUrls: urls)
                        }

                        // Info card
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(alignment: .top) {
                                if let tags = detail.tags, !tags.isEmpty {
                                    FlowLayoutView(spacing: 6) {
                                        ForEach(tags, id: \.self) { tag in
                                            Text(tag).font(.system(size: 11, weight: .semibold)).foregroundColor(tagColor(tag))
                                                .padding(.horizontal, 8).padding(.vertical, 4)
                                                .background(tagColor(tag).opacity(0.12)).cornerRadius(8)
                                        }
                                    }
                                }
                                Spacer()
                                if vm.canEdit {
                                    HStack(spacing: 6) {
                                        Button { showEditSheet = true } label: {
                                            Image(systemName: "pencil")
                                                .font(.system(size: 13, weight: .semibold))
                                                .foregroundColor(.greenPrimary)
                                                .frame(width: 32, height: 32)
                                                .background(Color.greenPrimary.opacity(0.1))
                                                .cornerRadius(10)
                                        }.buttonStyle(.plain)
                                        Button { showDeleteConfirm = true } label: {
                                            Image(systemName: "trash")
                                                .font(.system(size: 13, weight: .semibold))
                                                .foregroundColor(.coralRed)
                                                .frame(width: 32, height: 32)
                                                .background(Color.coralRed.opacity(0.1))
                                                .cornerRadius(10)
                                        }.buttonStyle(.plain)
                                    }
                                }
                            }
                            Text(detail.title).font(.system(size: 20, weight: .bold, design: .rounded)).foregroundColor(.darkText)
                            if let desc = detail.description, !desc.isEmpty {
                                Text(desc).font(.system(size: 14, weight: .medium)).foregroundColor(.bodyText)
                            }
                            HStack(spacing: 8) {
                                RoommateAvatar(user: detail.user, size: 28, cornerRadius: 9)
                                Text(detail.user.name).font(.system(size: 12)).foregroundColor(.subtitleText)
                                Spacer()
                                Text(formatTimeAgo(detail.createdAt)).font(.system(size: 11)).foregroundColor(.lightText)
                            }
                        }
                        .padding(16).background(Color.white).cornerRadius(22)
                        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)

                        // Comments
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Commentaires (\(detail.comments.count))")
                                .font(.system(size: 16, weight: .semibold, design: .rounded)).foregroundColor(.darkText)
                            if detail.comments.isEmpty {
                                Text("Aucun commentaire").font(.system(size: 13)).foregroundColor(.subtitleText)
                            } else {
                                ForEach(detail.comments) { comment in
                                    HStack(alignment: .top, spacing: 10) {
                                        RoommateAvatar(user: comment.user, size: 32, cornerRadius: 10)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(comment.user.name).font(.system(size: 13, weight: .semibold)).foregroundColor(.darkText)
                                            Text(comment.content).font(.system(size: 13)).foregroundColor(.bodyText)
                                        }
                                    }
                                    if comment.id != detail.comments.last?.id { Divider() }
                                }
                            }
                        }
                        .padding(16).background(Color.white).cornerRadius(22)
                        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)

                        Spacer(minLength: 16)
                    }
                    .padding(.horizontal, 18).padding(.vertical, 8)
                }

                // Comment input
                HStack(spacing: 8) {
                    TextField("Ajouter un commentaire...", text: $commentText)
                        .textFieldStyle(.plain)
                        .foregroundColor(.darkText)
                        .tint(.greenPrimary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.lightCardBg)
                        .cornerRadius(16)
                    Button {
                        guard !commentText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                        vm.addComment(reportId: reportId, content: commentText.trimmingCharacters(in: .whitespaces))
                        commentText = ""
                    } label: {
                        Image(systemName: "paperplane.fill").font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.greenPrimary)
                            .cornerRadius(12)
                    }.buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.white)
            }
        }
        .background(Color.screenBackground.ignoresSafeArea())
        .navigationTitle("Signalement").navigationBarTitleDisplayMode(.inline)
        .onAppear {
            vm.load(reportId: reportId)
            tabBarVisibility.isVisible = false
        }
        .onDisappear {
            tabBarVisibility.isVisible = true
        }
        .toast(message: Binding(get: { vm.errorMessage }, set: { vm.errorMessage = $0 }), type: .error)
        .toast(message: Binding(get: { vm.successMessage }, set: { vm.successMessage = $0 }), type: .success)
        .sheet(isPresented: $showEditSheet) {
            if let detail = vm.detail {
                EditReportSheet(detail: detail, tokenManager: tokenManager) { title, desc, tags in
                    vm.updateReport(reportId: reportId, title: title, description: desc, tags: tags)
                }
            }
        }
        .alert("Supprimer le signalement", isPresented: $showDeleteConfirm) {
            Button("Annuler", role: .cancel) {}
            Button("Supprimer", role: .destructive) { vm.deleteReport(reportId: reportId) }
        } message: {
            Text("Cette action est irréversible.")
        }
        .onChange(of: vm.deleted) { _ in if vm.deleted { dismiss() } }
    }
}

private struct EditReportSheet: View {
    @Environment(\.dismiss) private var dismiss
    let detail: ReportDetailResponse
    let tokenManager: TokenManager
    let onSave: (String, String, [String]?) -> Void

    @State private var title: String = ""
    @State private var description: String = ""
    @State private var selectedTags: Set<String> = []
    @State private var availableTags: [ReportTagResponse] = []

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Titre").font(.system(size: 13, weight: .medium)).foregroundColor(.subtitleText)
                        TextField("Titre du signalement", text: $title)
                            .textFieldStyle(.plain)
                            .foregroundColor(.darkText)
                            .tint(.greenPrimary)
                            .padding(12)
                            .background(Color.white).cornerRadius(14)
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.borderColor, lineWidth: 1))
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Description").font(.system(size: 13, weight: .medium)).foregroundColor(.subtitleText)
                        TextEditor(text: $description)
                            .frame(height: 100).padding(8)
                            .background(Color.white).cornerRadius(14)
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.borderColor, lineWidth: 1))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tags").font(.system(size: 13, weight: .medium)).foregroundColor(.subtitleText)
                        WrappingHStack(spacing: 8) {
                            ForEach(availableTags) { tag in
                                let selected = selectedTags.contains(tag.title)
                                let color = parseTagColor(tag.color)
                                Button {
                                    if selected { selectedTags.remove(tag.title) } else { selectedTags.insert(tag.title) }
                                } label: {
                                    Text(tag.title).font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(selected ? .white : color)
                                        .padding(.horizontal, 14).padding(.vertical, 8)
                                        .background(selected ? color : color.opacity(0.12)).cornerRadius(20)
                                }.buttonStyle(.plain)
                            }
                        }
                    }
                }.padding(18)
            }
            .onAppear {
                if let id = tokenManager.colocationId {
                    let api = APIService.configure(tokenManager: tokenManager)
                    Task { availableTags = (try? await api.getReportTags(colocationId: id)) ?? [] }
                }
            }
            .background(Color.screenBackground.ignoresSafeArea())
            .navigationTitle("Modifier").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Annuler") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Enregistrer") {
                        onSave(
                            title.trimmingCharacters(in: .whitespaces),
                            description.trimmingCharacters(in: .whitespaces),
                            selectedTags.isEmpty ? nil : Array(selectedTags)
                        )
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                title = detail.title
                description = detail.description ?? ""
                selectedTags = Set(detail.tags ?? [])
            }
        }
    }
}

struct FlowLayoutView<Content: View>: View {
    let spacing: CGFloat
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
    }
}
