import SwiftUI

let allTags = [
    "Urgent", "Important", "Information", "Rappel", "Suggestion",
    "Besoin d'aide", "A faire", "A verifier", "Aujourd'hui",
    "Des que possible", "Resolu",
]

func tagColor(_ tag: String) -> Color {
    switch tag {
    case "Urgent": return Color(hex: "#FF6B5E")
    case "Important": return Color(hex: "#FFB020")
    case "Information": return Color(hex: "#3B82F6")
    case "Rappel": return Color(hex: "#7C6BFF")
    case "Suggestion": return Color(hex: "#17A877")
    case "Besoin d'aide": return Color(hex: "#EC4899")
    case "A faire": return Color(hex: "#FF6B5E")
    case "A verifier": return Color(hex: "#FFB020")
    case "Aujourd'hui": return Color(hex: "#FF6B5E")
    case "Des que possible": return Color(hex: "#FFB020")
    case "Resolu": return Color(hex: "#8A8275")
    default: return Color(hex: "#8A8275")
    }
}

struct ReportsView: View {
    @EnvironmentObject var tokenManager: TokenManager
    @StateObject private var vm: ReportsViewModel
    @State private var showCreateReport = false
    @State private var selectedReportId: String?

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
                        ProgressView().tint(.greenPrimary).padding(40)
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
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                TagFilterChipView(label: "Tous", selected: vm.tagFilter == nil) { vm.setTagFilter(nil) }
                                ForEach(allTags, id: \.self) { tag in
                                    TagFilterChipView(label: tag, selected: vm.tagFilter == tag) { vm.setTagFilter(tag) }
                                }
                            }.padding(.horizontal, 18)
                        }

                        // Reports list
                        if vm.reports.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "flag").font(.system(size: 40)).foregroundColor(.borderColor)
                                Text("Aucun signalement").font(.system(size: 16, weight: .semibold, design: .rounded)).foregroundColor(.subtitleText)
                                Text("Tout va bien !").font(.system(size: 13)).foregroundColor(.lightText)
                            }
                            .frame(maxWidth: .infinity).padding(.vertical, 32)
                            .background(Color.white).cornerRadius(22)
                            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
                            .padding(.horizontal, 18)
                        } else {
                            VStack(spacing: 0) {
                                ForEach(vm.reports) { report in
                                    Button { selectedReportId = report.id } label: { ReportCardView(report: report) }.buttonStyle(.plain)
                                    if report.id != vm.reports.last?.id { Divider().padding(.leading, 80) }
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
            .onAppear { vm.load() }
            .toast(message: Binding(get: { vm.errorMessage }, set: { vm.errorMessage = $0 }), type: .error)
            .sheet(isPresented: $showCreateReport) {
                CreateReportView(tokenManager: tokenManager) { vm.load() }
            }
            .navigationDestination(item: Binding(
                get: { selectedReportId.map { ReportNavItem(id: $0) } },
                set: { selectedReportId = $0?.id }
            )) { item in
                ReportDetailView(reportId: item.id, tokenManager: tokenManager)
            }
        }
    }
}

struct ReportNavItem: Hashable { let id: String }

private struct TagFilterChipView: View {
    let label: String; let selected: Bool; let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(label).font(.system(size: 12, weight: .semibold))
                .foregroundColor(selected ? .white : .subtitleText)
                .padding(.horizontal, 14).padding(.vertical, 7)
                .background(selected ? Color.greenPrimary : Color.lightCardBg).cornerRadius(20)
        }.buttonStyle(.plain)
    }
}

private struct ReportCardView: View {
    let report: ReportResponse
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
                            Text(tag).font(.system(size: 10, weight: .semibold)).foregroundColor(tagColor(tag))
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(tagColor(tag).opacity(0.12)).cornerRadius(6)
                        }
                    }
                }
                Text(report.title).font(.system(size: 14, weight: .semibold)).foregroundColor(.darkText).lineLimit(1)
                if let desc = report.description, !desc.isEmpty {
                    Text(desc).font(.system(size: 12)).foregroundColor(.subtitleText).lineLimit(2)
                }
                HStack(spacing: 8) {
                    Text(report.user.name).font(.system(size: 11)).foregroundColor(.lightText)
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
