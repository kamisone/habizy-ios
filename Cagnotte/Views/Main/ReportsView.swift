import SwiftUI

func parseTagColor(_ hex: String) -> Color {
    Color(hex: hex.hasPrefix("#") ? hex : "#\(hex)")
}

struct ReportsView: View {
    @EnvironmentObject var tokenManager: TokenManager
    @StateObject private var vm: ReportsViewModel
    @State private var showCreateReport = false
    @State private var selectedReportId: String?
    @State private var showAddTagDialog = false
    @State private var hasAppeared = false

    init(tokenManager: TokenManager) {
        _vm = StateObject(wrappedValue: ReportsViewModel(tokenManager: tokenManager))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    Text("Signalements")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.darkText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 18).padding(.top, 16)

                    if vm.isLoading {
                        ShimmerReportsLoading()
                    } else {
                        // Create button
                        Button { showCreateReport = true } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "flag").font(.system(size: 14, weight: .bold))
                                Text("Signaler un probleme").font(.system(size: 15, weight: .semibold, design: .rounded))
                            }
                            .foregroundColor(.white).frame(maxWidth: .infinity).padding(.vertical, 14)
                            .background(Color.coralRed).cornerRadius(16)
                            .shadow(color: Color.coralRed.opacity(0.3), radius: 8, x: 0, y: 3)
                        }.buttonStyle(.plain).padding(.horizontal, 18)

                        // Tag filters
                        if !vm.tags.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    TagFilterChipView(label: "Tous", color: .greenPrimary, selected: vm.tagFilter == nil) { vm.setTagFilter(nil) }
                                    ForEach(vm.tags) { tag in
                                        TagFilterChipView(label: tag.title, color: parseTagColor(tag.color), selected: vm.tagFilter == tag.title) { vm.setTagFilter(tag.title) }
                                    }
                                }.padding(.horizontal, 18)
                            }
                        }

                        // Reports list
                        if vm.reports.isEmpty {
                            BreathingEmptyState(icon: "flag", title: "Aucun signalement", subtitle: "Tout va bien !")
                                .padding(.horizontal, 18)
                        } else {
                            VStack(spacing: 0) {
                                ForEach(vm.reports) { report in
                                    Button { selectedReportId = report.id } label: {
                                        ReportCardView(report: report, allTags: vm.tags)
                                    }.buttonStyle(PressableButtonStyle())
                                    if report.id != vm.reports.last?.id { Divider().padding(.leading, 80) }
                                }
                            }
                            .background(Color.white).cornerRadius(22)
                            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
                            .padding(.horizontal, 18)
                        }

                        // Admin tag management
                        if vm.isAdmin {
                            VStack(spacing: 0) {
                                HStack {
                                    Text("Gerer les tags")
                                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                                        .foregroundColor(.darkText)
                                    Spacer()
                                    Button { showAddTagDialog = true } label: {
                                        Image(systemName: "plus")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.greenPrimary)
                                    }
                                }
                                .padding(.horizontal, 16).padding(.vertical, 12)

                                ForEach(vm.tags) { tag in
                                    HStack(spacing: 10) {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(parseTagColor(tag.color))
                                            .frame(width: 14, height: 14)
                                        Text(tag.title)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.bodyText)
                                        Spacer()
                                        Button { vm.deleteTag(id: tag.id) } label: {
                                            Image(systemName: "trash")
                                                .font(.system(size: 14))
                                                .foregroundColor(.coralRed)
                                        }.buttonStyle(.plain)
                                    }
                                    .padding(.horizontal, 16).padding(.vertical, 8)

                                    if tag.id != vm.tags.last?.id {
                                        Divider().padding(.leading, 40)
                                    }
                                }
                            }
                            .background(Color.white).cornerRadius(22)
                            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
                            .padding(.horizontal, 18)
                        }
                    }
                    Spacer(minLength: 80)
                }
            }
            .refreshable { await vm.refresh() }
            .background(Color.screenBackground.ignoresSafeArea())
            .toolbarBackground(.hidden, for: .navigationBar).toolbar(.hidden, for: .navigationBar)
            .onAppear {
                if hasAppeared { Task { await vm.refresh() } } else { vm.load(); hasAppeared = true }
            }
            .toast(message: Binding(get: { vm.errorMessage }, set: { vm.errorMessage = $0 }), type: .error)
            .sheet(isPresented: $showCreateReport) {
                CreateReportView(tokenManager: tokenManager) { vm.load() }
            }
            .navigationDestination(isPresented: Binding(get: { selectedReportId != nil }, set: { if !$0 { selectedReportId = nil } })) {
                if let id = selectedReportId {
                    ReportDetailView(reportId: id, tokenManager: tokenManager)
                }
            }
            .sheet(isPresented: $showAddTagDialog) {
                AddTagSheet { title, color in
                    vm.createTag(title: title, color: color)
                    showAddTagDialog = false
                }
            }
        }
    }
}

struct ReportNavItem: Hashable { let id: String }

private struct TagFilterChipView: View {
    let label: String
    var color: Color = .greenPrimary
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label).font(.system(size: 12, weight: .semibold))
                .foregroundColor(selected ? .white : color)
                .padding(.horizontal, 14).padding(.vertical, 7)
                .background(selected ? color : color.opacity(0.12)).cornerRadius(20)
        }.buttonStyle(.plain)
    }
}

private struct ReportCardView: View {
    let report: ReportResponse
    var allTags: [ReportTagResponse] = []

    private func colorForTag(_ tagTitle: String) -> Color {
        if let tag = allTags.first(where: { $0.title == tagTitle }) {
            return parseTagColor(tag.color)
        }
        return Color(hex: "#8A8275")
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if let firstPhoto = report.photoUrls?.first, let url = URL(string: firstPhoto) {
                AsyncImage(url: url) { phase in
                    if case .success(let img) = phase { img.resizable().scaledToFill() } else { Color.borderColor }
                }.frame(width: 52, height: 52).cornerRadius(12)
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 12).fill(Color.coralRed.opacity(0.1)).frame(width: 52, height: 52)
                    Image(systemName: "flag").foregroundColor(.coralRed).font(.system(size: 18))
                }
            }
            VStack(alignment: .leading, spacing: 4) {
                if let tags = report.tags, !tags.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(tags.prefix(3), id: \.self) { tag in
                            let c = colorForTag(tag)
                            Text(tag).font(.system(size: 10, weight: .semibold)).foregroundColor(c)
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(c.opacity(0.12)).cornerRadius(6)
                        }
                    }
                }
                Text(report.title).font(.system(size: 14, weight: .semibold)).foregroundColor(.darkText).lineLimit(1)
                if let desc = report.description, !desc.isEmpty {
                    Text(desc).font(.system(size: 12)).foregroundColor(.subtitleText).lineLimit(2)
                }
                HStack(spacing: 8) {
                    Text(report.user.name).font(.system(size: 11)).foregroundColor(.lightText)
                    Text("·").font(.system(size: 11)).foregroundColor(.lightText)
                    Text(formatTimeAgo(report.createdAt)).font(.system(size: 11)).foregroundColor(.lightText)
                    if let count = report.commentCount, count > 0 {
                        HStack(spacing: 3) {
                            Image(systemName: "bubble.left").font(.system(size: 10))
                            Text("\(count)").font(.system(size: 11))
                        }.foregroundColor(.lightText)
                    }
                }
            }
            Spacer()
        }.padding(.horizontal, 16).padding(.vertical, 12)
    }
}

// MARK: - Add Tag Sheet

private let presetColors = ["#FF6B5E", "#FFB020", "#3B82F6", "#7C6BFF", "#17A877", "#EC4899", "#14B8A6", "#F97316"]

private struct AddTagSheet: View {
    let onConfirm: (String, String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var selectedColor = presetColors[0]

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                TextField("Nom du tag", text: $name)
                    .padding(14)
                    .background(Color.white)
                    .cornerRadius(14)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.borderColor, lineWidth: 1))
                    .font(.system(size: 15))

                Text("Couleur")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.bodyText)

                HStack(spacing: 10) {
                    ForEach(presetColors, id: \.self) { hex in
                        let c = Color(hex: hex)
                        Circle()
                            .fill(c)
                            .frame(width: 32, height: 32)
                            .overlay(
                                Circle().stroke(Color.white, lineWidth: selectedColor == hex ? 3 : 0)
                                    .padding(2)
                            )
                            .overlay(
                                Circle().stroke(c, lineWidth: selectedColor == hex ? 2 : 0)
                            )
                            .onTapGesture { selectedColor = hex }
                    }
                }

                Spacer()
            }
            .padding(20)
            .background(Color.screenBackground.ignoresSafeArea())
            .navigationTitle("Nouveau tag")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                        .foregroundColor(.subtitleText)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Ajouter") {
                        if !name.trimmingCharacters(in: .whitespaces).isEmpty {
                            onConfirm(name.trimmingCharacters(in: .whitespaces), selectedColor)
                        }
                    }
                    .foregroundColor(.greenPrimary)
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
    }
}
