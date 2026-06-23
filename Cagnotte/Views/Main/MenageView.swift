import SwiftUI

private let dayLabels = ["Lun", "Mar", "Mer", "Jeu", "Ven", "Sam", "Dim"]

private func getDayOfWeek(_ isoDate: String) -> Int {
    let formatters: [DateFormatter] = {
        let f1 = DateFormatter(); f1.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        let f2 = DateFormatter(); f2.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        let f3 = DateFormatter(); f3.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        f3.timeZone = TimeZone(identifier: "UTC")
        return [f1, f2, f3]
    }()
    let cleaned = isoDate.replacingOccurrences(of: "\\.\\d+", with: "", options: .regularExpression)
    for fmt in formatters {
        if let date = fmt.date(from: cleaned) ?? fmt.date(from: isoDate) {
            let dow = Calendar.current.component(.weekday, from: date)
            return dow == 1 ? 6 : dow - 2
        }
    }
    return -1
}

private func getWeekDates(_ weekStart: String) -> [String] {
    let sdf = DateFormatter(); sdf.dateFormat = "yyyy-MM-dd"
    guard let start = sdf.date(from: weekStart) else { return (1...7).map { "\($0)" } }
    let dayFmt = DateFormatter(); dayFmt.dateFormat = "d"
    return (0..<7).map { dayFmt.string(from: Calendar.current.date(byAdding: .day, value: $0, to: start)!) }
}

private func isToday(_ weekStart: String, dayIndex: Int) -> Bool {
    let sdf = DateFormatter(); sdf.dateFormat = "yyyy-MM-dd"
    guard let start = sdf.date(from: weekStart),
          let day = Calendar.current.date(byAdding: .day, value: dayIndex, to: start) else { return false }
    return Calendar.current.isDateInToday(day)
}

struct MenageView: View {
    @EnvironmentObject var tokenManager: TokenManager
    @StateObject private var vm: MenageViewModel
    @State private var showCommentSheet = false

    init(tokenManager: TokenManager) {
        _vm = StateObject(wrappedValue: MenageViewModel(tokenManager: tokenManager))
    }

    var body: some View {
        ZStack {
            if vm.isLoading && vm.weekData == nil {
                VStack { Spacer(); ProgressView().tint(.greenPrimary); Spacer() }
            } else if let data = vm.weekData {
                let todayTaken = data.todayTakenBy != nil
                let iAmTodayOwner = data.todayTakenBy == vm.currentUserId

                List {
                    Section {
                        // Header
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Semaine du \(data.weekStart)")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(.darkText)
                            Text("Passer l'aspirateur et serpillère")
                                .font(.system(size: 13)).foregroundColor(.subtitleText)
                            HStack(spacing: 6) {
                                Text("\(data.totalDone)/\(data.totalMembers)")
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                    .foregroundColor(.greenPrimary)
                                Text("ont fait le ménage")
                                    .font(.system(size: 13)).foregroundColor(.subtitleText)
                            }
                        }
                        .padding(16).frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white).cornerRadius(22)
                        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
                        .listRowInsets(EdgeInsets(top: 7, leading: 18, bottom: 7, trailing: 18))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)

                        // Today highlight
                        if todayTaken && !iAmTodayOwner {
                            let takenName = data.board.first { $0.userId == data.todayTakenBy }?.name ?? ""
                            let takenComment = data.board.first { $0.userId == data.todayTakenBy }?.comment
                            HStack(spacing: 10) {
                                Text("✨").font(.system(size: 18))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("\(takenName) a fait le ménage aujourd'hui")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(.greenPrimary)
                                    if let c = takenComment, !c.isEmpty {
                                        Text("\"\(c)\"")
                                            .font(.system(size: 12))
                                            .foregroundColor(.subtitleText)
                                    }
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 16).padding(.vertical, 12)
                            .background(Color.greenPrimary.opacity(0.08))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.greenPrimary.opacity(0.3), lineWidth: 1))
                            .cornerRadius(16)
                            .listRowInsets(EdgeInsets(top: 4, leading: 18, bottom: 4, trailing: 18))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                        }

                        // Action button (hidden when someone else took today)
                        if !(todayTaken && !iAmTodayOwner) {
                            MenageActionButton(data: data, currentUserId: vm.currentUserId, onMark: { showCommentSheet = true }, onUndo: { vm.undoDone() })
                                .listRowInsets(EdgeInsets(top: 4, leading: 18, bottom: 4, trailing: 18))
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                        }

                        // Calendar
                        WeekCalendarView(data: data)
                            .listRowInsets(EdgeInsets(top: 4, leading: 18, bottom: 4, trailing: 18))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)

                        // Participants
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Participants")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(.darkText)
                                .padding(.horizontal, 16).padding(.top, 12).padding(.bottom, 4)
                            ForEach(data.board, id: \.userId) { member in
                                MenageMemberRow(member: member)
                                if member.userId != data.board.last?.userId { Divider().padding(.leading, 64) }
                            }
                        }
                        .background(Color.white).cornerRadius(22)
                        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
                        .listRowInsets(EdgeInsets(top: 4, leading: 18, bottom: 4, trailing: 18))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    }
                }
                .listStyle(.plain)
                .listRowBackground(Color.clear)
                .refreshable { await vm.refresh() }
            }
        }
        .background(Color.screenBackground.ignoresSafeArea())
        .navigationTitle("Ménage").navigationBarTitleDisplayMode(.inline)
        .onAppear { vm.load() }
        .toast(message: Binding(get: { vm.errorMessage }, set: { vm.errorMessage = $0 }), type: .error)
        .sheet(isPresented: $showCommentSheet) {
            CommentSheet { comment in
                showCommentSheet = false
                vm.markDone(comment: comment)
            }
        }
    }
}

// MARK: - Comment Sheet

private struct CommentSheet: View {
    let onConfirm: (String?) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                Text("Ajouter un commentaire (optionnel)")
                    .font(.system(size: 13)).foregroundColor(.subtitleText)
                TextField("Ex: Aspirateur + serpillère salon", text: $text, axis: .vertical)
                    .lineLimit(3...6)
                    .padding(12)
                    .background(Color.white).cornerRadius(14)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.borderColor, lineWidth: 1))
                Spacer()
            }
            .padding(20)
            .background(Color.screenBackground.ignoresSafeArea())
            .navigationTitle("Ménage fait !")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Annuler") { dismiss() }.foregroundColor(.subtitleText) }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Valider") { onConfirm(text.isEmpty ? nil : text) }.foregroundColor(.greenPrimary).fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Action Button

private struct MenageActionButton: View {
    let data: MenageWeekResponse
    let currentUserId: String?
    let onMark: () -> Void
    let onUndo: () -> Void

    private var todayTaken: Bool { data.todayTakenBy != nil }
    private var iAmTodayOwner: Bool { data.todayTakenBy == currentUserId }
    private var myWeekDone: Bool { data.board.contains { $0.userId == currentUserId && $0.done } }
    private var enabled: Bool { (!todayTaken && !myWeekDone) || iAmTodayOwner }

    private var buttonText: String {
        if iAmTodayOwner { return "Annuler mon ménage" }
        if myWeekDone { return "Ménage déjà fait cette semaine" }
        if todayTaken { return "Déjà pris aujourd'hui" }
        return "J'ai fait le ménage !"
    }

    var body: some View {
        Button {
            if enabled { iAmTodayOwner ? onUndo() : onMark() }
        } label: {
            Text(buttonText)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(enabled ? Color.greenPrimary : Color.subtitleText.opacity(0.3))
                .cornerRadius(16)
                .shadow(color: enabled ? Color.greenDark.opacity(0.3) : .clear, radius: 8, x: 0, y: 3)
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }
}

// MARK: - Week Calendar

private struct WeekCalendarView: View {
    let data: MenageWeekResponse

    var body: some View {
        let dates = getWeekDates(data.weekStart)
        let membersByDay: [Int: MenageBoardMember?] = {
            var dict = [Int: MenageBoardMember?]()
            for i in 0...6 { dict[i] = nil }
            for m in data.board where m.done {
                if let doneAt = m.doneAt {
                    let day = getDayOfWeek(doneAt)
                    if day >= 0 && day <= 6 && dict[day] == nil { dict[day] = m }
                }
            }
            return dict
        }()

        VStack(alignment: .leading, spacing: 8) {
            Text("Calendrier")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.darkText).padding(.horizontal, 4)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(0..<7, id: \.self) { dayIndex in
                        let today = isToday(data.weekStart, dayIndex: dayIndex)
                        let m = membersByDay[dayIndex] ?? nil
                        let dateNum = dayIndex < dates.count ? dates[dayIndex] : ""

                        VStack(spacing: 4) {
                            Text(dayLabels[dayIndex])
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(today ? .greenPrimary : .subtitleText)
                            Text(dateNum)
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(today ? .greenPrimary : .darkText)
                            Spacer().frame(height: 4)
                            if let m = m {
                                ZStack {
                                    Circle().fill(Color(hex: m.colorHex ?? "#17A877")).frame(width: 30, height: 30)
                                    Text(m.initial ?? "?").font(.system(size: 12, weight: .bold)).foregroundColor(.white)
                                }
                                Text(m.name.components(separatedBy: " ").first ?? "")
                                    .font(.system(size: 9)).foregroundColor(.darkText).lineLimit(1)
                                if let comment = m.comment, !comment.isEmpty {
                                    Text(comment)
                                        .font(.system(size: 8)).foregroundColor(.subtitleText)
                                        .lineLimit(2).multilineTextAlignment(.center)
                                        .padding(.top, 2)
                                }
                            } else {
                                Spacer().frame(height: 44)
                            }
                        }
                        .frame(width: 72)
                        .padding(.vertical, 10).padding(.horizontal, 6)
                        .background(today ? Color.greenPrimary.opacity(0.06) : Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(today ? Color.greenPrimary : Color.dividerColor, lineWidth: today ? 2 : 1)
                        )
                        .cornerRadius(16)
                    }
                }
            }
        }
        .padding(12)
        .background(Color.white).cornerRadius(22)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Member Row

private struct MenageMemberRow: View {
    let member: MenageBoardMember

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 11).fill(Color(hex: member.colorHex ?? "#17A877")).frame(width: 36, height: 36)
                Text(member.initial ?? "?").font(.system(size: 14, weight: .semibold, design: .rounded)).foregroundColor(.white)
            }
            Text(member.name).font(.system(size: 14, weight: .medium)).foregroundColor(.darkText).lineLimit(1)
            Spacer()
            if member.done {
                Text("Fait").font(.system(size: 12, weight: .semibold)).foregroundColor(.greenPrimary)
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(Color.greenPrimary.opacity(0.1)).cornerRadius(8)
            } else {
                Text("En attente").font(.system(size: 12)).foregroundColor(.subtitleText)
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(Color.lightCardBg).cornerRadius(8)
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
    }
}
