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

private func formatWeekStart(_ weekStart: String) -> String {
    let sdf = DateFormatter(); sdf.dateFormat = "yyyy-MM-dd"; sdf.locale = Locale(identifier: "fr_FR")
    guard let date = sdf.date(from: weekStart) else { return weekStart }
    let display = DateFormatter(); display.dateFormat = "d MMMM"; display.locale = Locale(identifier: "fr_FR")
    return display.string(from: date)
}

struct MenageView: View {
    @EnvironmentObject var tokenManager: TokenManager
    @StateObject private var vm: MenageViewModel
    @State private var showCommentSheet = false
    @State private var showEditTaskSheet = false

    init(tokenManager: TokenManager) {
        _vm = StateObject(wrappedValue: MenageViewModel(tokenManager: tokenManager))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.screenBackground.ignoresSafeArea()

                if vm.isLoading && vm.weekData == nil {
                    VStack { Spacer(); ProgressView().tint(.greenPrimary); Spacer() }
                } else if let data = vm.weekData {
                    let todayTaken = data.todayTakenBy != nil
                    let iAmTodayOwner = data.todayTakenBy == vm.currentUserId

                    ScrollView {
                        VStack(spacing: 16) {
                            // Gradient progress card
                            ProgressHeaderCard(
                                data: data,
                                isAdmin: vm.isAdmin,
                                onEditTask: { showEditTaskSheet = true }
                            )

                            // Today highlight
                            if todayTaken && !iAmTodayOwner {
                                TodayHighlight(data: data, currentUserId: vm.currentUserId)
                            }

                            // Action button
                            if !(todayTaken && !iAmTodayOwner) {
                                MenageActionButton(
                                    data: data,
                                    currentUserId: vm.currentUserId,
                                    onMark: { showCommentSheet = true },
                                    onUndo: { vm.undoDone() }
                                )
                            }

                            // Calendar
                            WeekCalendarView(data: data)

                            // Participants
                            ParticipantsCard(data: data)
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 8)
                        .padding(.bottom, 40)
                    }
                    .refreshable { await vm.refresh() }
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar(.hidden, for: .navigationBar)
            .onAppear { vm.load() }
            .toast(message: Binding(get: { vm.errorMessage }, set: { vm.errorMessage = $0 }), type: .error)
            .sheet(isPresented: $showCommentSheet) {
                CommentSheet { comment in
                    showCommentSheet = false
                    vm.markDone(comment: comment)
                }
            }
            .sheet(isPresented: $showEditTaskSheet) {
                EditTaskSheet(
                    currentDescription: vm.weekData?.taskDescription ?? "Passer l'aspirateur et serpillère"
                ) { description in
                    showEditTaskSheet = false
                    vm.updateTaskDescription(description)
                }
            }
        }
    }
}

// MARK: - Progress Header Card

private struct ProgressHeaderCard: View {
    let data: MenageWeekResponse
    let isAdmin: Bool
    let onEditTask: () -> Void

    private var progress: CGFloat {
        guard data.totalMembers > 0 else { return 0 }
        return CGFloat(data.totalDone) / CGFloat(data.totalMembers)
    }

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Ménage")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("Semaine du \(formatWeekStart(data.weekStart))")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.85))
                Spacer().frame(height: 4)
                Text("\(data.totalDone)/\(data.totalMembers) ont fait le ménage")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                HStack(spacing: 6) {
                    Text(data.taskDescription ?? "Passer l'aspirateur et serpillère")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                    if isAdmin {
                        Button(action: onEditTask) {
                            Image(systemName: "pencil")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            Spacer()

            // Circular progress
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 6)
                    .frame(width: 68, height: 68)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color.white, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 68, height: 68)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.8), value: progress)
                VStack(spacing: 0) {
                    Text("\(data.totalDone)")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("/\(data.totalMembers)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
        .padding(22)
        .background(
            LinearGradient(
                colors: [Color.purple, Color(hex: "#5B4FCC")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(26)
        .shadow(color: Color.purple.opacity(0.3), radius: 12, x: 0, y: 6)
    }
}

// MARK: - Today Highlight

private struct TodayHighlight: View {
    let data: MenageWeekResponse
    let currentUserId: String?

    var body: some View {
        let takenName = data.board.first { $0.userId == data.todayTakenBy }?.name ?? ""
        let takenComment = data.board.first { $0.userId == data.todayTakenBy }?.comment

        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.greenPrimary.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.greenPrimary)
            }
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
        .padding(.horizontal, 16).padding(.vertical, 14)
        .background(Color.white)
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color.greenPrimary.opacity(0.2), lineWidth: 1))
        .cornerRadius(18)
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
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

// MARK: - Edit Task Sheet

private struct EditTaskSheet: View {
    let currentDescription: String
    let onConfirm: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var text: String

    init(currentDescription: String, onConfirm: @escaping (String) -> Void) {
        self.currentDescription = currentDescription
        self.onConfirm = onConfirm
        _text = State(initialValue: currentDescription)
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                Text("Description de la tâche de ménage")
                    .font(.system(size: 13)).foregroundColor(.subtitleText)
                TextField("Ex: Passer l'aspirateur et serpillère", text: $text, axis: .vertical)
                    .lineLimit(3...6)
                    .padding(12)
                    .background(Color.white).cornerRadius(14)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.borderColor, lineWidth: 1))
                Spacer()
            }
            .padding(20)
            .background(Color.screenBackground.ignoresSafeArea())
            .navigationTitle("Modifier la tâche")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }.foregroundColor(.subtitleText)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Enregistrer") {
                        if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            onConfirm(text.trimmingCharacters(in: .whitespacesAndNewlines))
                        }
                    }
                    .foregroundColor(.greenPrimary)
                    .fontWeight(.semibold)
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
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
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    enabled
                        ? LinearGradient(colors: [.greenLight, .greenPrimary], startPoint: .leading, endPoint: .trailing)
                        : LinearGradient(colors: [Color.subtitleText.opacity(0.3), Color.subtitleText.opacity(0.3)], startPoint: .leading, endPoint: .trailing)
                )
                .cornerRadius(18)
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

        VStack(alignment: .leading, spacing: 10) {
            Text("Calendrier")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.darkText).padding(.horizontal, 4)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(0..<7, id: \.self) { dayIndex in
                        let today = isToday(data.weekStart, dayIndex: dayIndex)
                        let m = membersByDay[dayIndex] ?? nil
                        let dateNum = dayIndex < dates.count ? dates[dayIndex] : ""
                        let hasDone = m != nil

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
                        .background(
                            today ? Color.greenPrimary.opacity(0.06)
                            : hasDone ? Color.greenPrimary.opacity(0.03)
                            : Color.clear
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(
                                    today ? Color.greenPrimary
                                    : hasDone ? Color.greenPrimary.opacity(0.3)
                                    : Color.dividerColor,
                                    lineWidth: today ? 2 : 1
                                )
                        )
                        .cornerRadius(18)
                    }
                }
            }
        }
        .padding(14)
        .background(Color.white).cornerRadius(22)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Participants Card

private struct ParticipantsCard: View {
    let data: MenageWeekResponse

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Participants")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.darkText)
                .padding(.horizontal, 16).padding(.top, 14).padding(.bottom, 6)
            ForEach(data.board, id: \.userId) { member in
                MenageMemberRow(member: member)
                if member.userId != data.board.last?.userId {
                    Divider().padding(.leading, 68)
                }
            }
        }
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
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .fill(Color(hex: member.colorHex ?? "#17A877"))
                    .frame(width: 40, height: 40)
                Text(member.initial ?? "?")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
            }
            Text(member.name)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.darkText)
                .lineLimit(1)
            Spacer()
            if member.done {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.greenPrimary)
                    Text("Fait")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.greenPrimary)
                }
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(Color.greenPrimary.opacity(0.1)).cornerRadius(10)
            } else {
                Text("En attente")
                    .font(.system(size: 12))
                    .foregroundColor(.subtitleText)
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(Color.lightCardBg).cornerRadius(10)
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
    }
}
