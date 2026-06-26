import SwiftUI

struct ExpensesView: View {
    @EnvironmentObject var tokenManager: TokenManager
    @StateObject private var vm: ExpensesViewModel
    @State private var selectedReceipt: ReceiptResponse?
    @State private var hasAppeared = false

    init(tokenManager: TokenManager) {
        _vm = StateObject(wrappedValue: ExpensesViewModel(tokenManager: tokenManager))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Text("Dépenses")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.darkText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 18)
                        .padding(.top, 16)

                    if vm.isLoading {
                        ShimmerExpensesLoading()
                    } else {
                        if !vm.isMyTurn && !vm.currentPurchaserName.isEmpty {
                            HStack(spacing: 10) {
                                Image(systemName: "cart")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.appBlue)
                                Text("C'est au tour de \(vm.currentPurchaserName) de faire les courses")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.appBlue)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.appBlue.opacity(0.08))
                            .cornerRadius(14)
                            .padding(.horizontal, 18)
                        }

                        if let stats = vm.stats {
                            statsSection(stats)
                        }
                        receiptsSection
                    }
                }
                .padding(.bottom, 100)
            }
            .refreshable { await vm.refresh() }
            .background(Color.screenBackground.ignoresSafeArea())
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar(.hidden, for: .navigationBar)
            .onAppear {
                if hasAppeared { Task { await vm.refresh() } } else { vm.load(); hasAppeared = true }
            }
            .toast(message: Binding(
                get: { vm.errorMessage },
                set: { vm.errorMessage = $0 }
            ), type: .error)
            .toast(message: Binding(
                get: { vm.successMessage },
                set: { vm.successMessage = $0 }
            ), type: .success)
            .sheet(item: $selectedReceipt) { receipt in
                ReceiptDetailView(receipt: receipt, isAdmin: vm.isAdmin) {
                    vm.deleteReceipt(id: receipt.id)
                    selectedReceipt = nil
                }
            }
        }
    }

    private func statsSection(_ stats: ExpenseStatsResponse) -> some View {
        let spendingGap: Double? = {
            guard stats.byRoommate.count >= 2 else { return nil }
            let totals = stats.byRoommate.map { $0.total }
            return (totals.max() ?? 0) - (totals.min() ?? 0)
        }()
        let threshold = vm.gapThreshold
        let gapColor: Color = {
            guard let gap = spendingGap else { return .greenPrimary }
            if gap >= threshold { return .coralRed }
            if gap >= threshold * 0.5 { return .orange }
            return .greenPrimary
        }()
        let gapLabel: String = {
            guard let gap = spendingGap else { return "" }
            if gap >= threshold { return "Déséquilibré" }
            if gap >= threshold * 0.5 { return "Attention" }
            return "Équilibré"
        }()

        return VStack(spacing: 12) {
            VStack(spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Total dépensé")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.subtitleText)
                        Text(stats.totalSpent.euroFormatted)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.darkText)
                    }
                    Spacer()
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.greenPrimary.opacity(0.12))
                            .frame(width: 48, height: 48)
                        Image(systemName: "receipt")
                            .font(.system(size: 22))
                            .foregroundColor(.greenPrimary)
                    }
                }

                if let gap = spendingGap {
                    Divider()
                        .padding(.vertical, 12)
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Écart entre colocataires")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.subtitleText)
                            Text(gapLabel)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(gapColor)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(gapColor.opacity(0.12))
                                .cornerRadius(8)
                        }
                        Spacer()
                        Text(gap.euroFormatted)
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(gapColor)
                    }
                }
            }
            .padding(18)
            .background(Color.white)
            .cornerRadius(22)
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
            .padding(.horizontal, 18)

            if !stats.byCategory.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Par catégorie")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.darkText)
                        Spacer()
                        NavigationLink {
                            ArticleStatsView(tokenManager: tokenManager)
                        } label: {
                            Label("Articles", systemImage: "cart")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.greenPrimary)
                        }
                    }
                    ForEach(stats.byCategory) { cat in
                        CategoryRow(stat: cat)
                    }
                }
                .padding(18)
                .background(Color.white)
                .cornerRadius(22)
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
                .padding(.horizontal, 18)
            }

            if !stats.byRoommate.isEmpty {
                let maxFraction = stats.byRoommate.map { $0.fraction }.max() ?? 1.0
                VStack(alignment: .leading, spacing: 14) {
                    Text("Par colocataire")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.darkText)
                    ForEach(stats.byRoommate) { stat in
                        HStack(spacing: 10) {
                            if let user = stat.user {
                                RoommateAvatar(user: user, size: 34, cornerRadius: 11)
                                VStack(alignment: .leading, spacing: 5) {
                                    HStack {
                                        Text(user.name)
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(.darkText)
                                        Spacer()
                                        Text(stat.total.euroFormatted)
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(.darkText)
                                    }
                                    GeometryReader { geo in
                                        ZStack(alignment: .leading) {
                                            Capsule()
                                                .fill(Color.greenPrimary.opacity(0.12))
                                                .frame(height: 6)
                                            Capsule()
                                                .fill(Color.greenPrimary)
                                                .frame(width: geo.size.width * CGFloat(stat.fraction / maxFraction), height: 6)
                                        }
                                    }
                                    .frame(height: 6)
                                }
                            } else {
                                Text("Inconnu")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.bodyText)
                                Spacer()
                                Text(stat.total.euroFormatted)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.darkText)
                            }
                        }
                    }
                }
                .padding(18)
                .background(Color.white)
                .cornerRadius(22)
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
                .padding(.horizontal, 18)
            }
        }
    }

    private var receiptsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Tickets de caisse")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.darkText)
                .padding(.horizontal, 18)

            if vm.receipts.isEmpty {
                Text("Aucun ticket enregistré")
                    .font(.system(size: 14))
                    .foregroundColor(.subtitleText)
                    .padding(.horizontal, 18)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(vm.receipts.enumerated()), id: \.element.id) { index, receipt in
                        ReceiptRow(receipt: receipt)
                            .onTapGesture { selectedReceipt = receipt }
                        if index < vm.receipts.count - 1 {
                            Divider()
                                .padding(.horizontal, 16)
                        }
                    }
                }
                .background(Color.white)
                .cornerRadius(22)
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
                .padding(.horizontal, 18)
            }
        }
    }
}

// MARK: - Receipt Detail Sheet

struct ReceiptDetailView: View {
    let receipt: ReceiptResponse
    var isAdmin: Bool = false
    var onDelete: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss
    @State private var showFullScreenPhoto = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Photo
                    if let photoUrl = receipt.photoUrl, let url = URL(string: photoUrl) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 220)
                                    .clipped()
                                    .cornerRadius(18)
                                    .onTapGesture { showFullScreenPhoto = true }
                            case .failure:
                                photoPlaceholder
                            case .empty:
                                ZStack {
                                    RoundedRectangle(cornerRadius: 18)
                                        .fill(Color.greenPrimary.opacity(0.08))
                                        .frame(height: 220)
                                    ProgressView().tint(.greenPrimary)
                                }
                            @unknown default:
                                photoPlaceholder
                            }
                        }
                    } else {
                        photoPlaceholder
                    }

                    // Store + total
                    HStack(alignment: .firstTextBaseline) {
                        Text(receipt.store)
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.darkText)
                        Spacer()
                        Text("−\(receipt.totalAmount.euroFormatted)")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.coralRed)
                    }

                    // Meta
                    HStack(spacing: 18) {
                        Label(receipt.formattedDateTime, systemImage: "calendar")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.subtitleText)
                        HStack(spacing: 5) {
                            Label(receipt.user.name, systemImage: "person")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.subtitleText)
                            if receipt.user.isAdmin == true {
                                HStack(spacing: 3) {
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 8))
                                        .foregroundColor(Color(hex: "#FFB020"))
                                    Text("Admin")
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundColor(Color(hex: "#FFB020"))
                                }
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color(hex: "#FFB020").opacity(0.12))
                                .cornerRadius(7)
                            }
                        }
                    }

                    // Items
                    if !receipt.items.isEmpty {
                        VStack(alignment: .leading, spacing: 0) {
                            HStack {
                                Label("Articles", systemImage: "cart")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.darkText)
                                Spacer()
                                Text("\(receipt.items.count) article\(receipt.items.count > 1 ? "s" : "")")
                                    .font(.system(size: 12))
                                    .foregroundColor(.subtitleText)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)

                            Divider().padding(.horizontal, 14)

                            ForEach(receipt.items) { item in
                                HStack(alignment: .top) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.quantity > 1 ? "\(item.name) ×\(item.quantity)" : item.name)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.bodyText)
                                        if !item.category.isEmpty && item.category.lowercased() != "divers" {
                                            Text(item.category)
                                                .font(.system(size: 11))
                                                .foregroundColor(.lightText)
                                        }
                                    }
                                    Spacer()
                                    Text((item.price * Double(item.quantity)).euroFormatted)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.darkText)
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 11)

                                if item.id != receipt.items.last?.id {
                                    Divider().padding(.horizontal, 14)
                                }
                            }
                        }
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
                    }

                    // Delete button (admin only)
                    if isAdmin, let onDelete {
                        Button {
                            onDelete()
                            dismiss()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "trash")
                                    .font(.system(size: 14, weight: .semibold))
                                Text("Supprimer ce ticket")
                                    .font(.system(size: 15, weight: .semibold))
                            }
                            .foregroundColor(.coralRed)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.coralRed.opacity(0.08))
                            .cornerRadius(16)
                        }
                        .buttonStyle(.plain)
                    }

                    Spacer(minLength: 40)
                }
                .padding(20)
            }
            .background(Color.screenBackground.ignoresSafeArea())
            .navigationTitle("Détail du ticket")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { dismiss() }
                }
            }
            .fullScreenCover(isPresented: $showFullScreenPhoto) {
                if let photoUrl = receipt.photoUrl, let url = URL(string: photoUrl) {
                    FullScreenPhotoViewer(url: url)
                }
            }
        }
    }

    private var photoPlaceholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.greenPrimary.opacity(0.08))
                .frame(height: 120)
            VStack(spacing: 8) {
                Image(systemName: "receipt")
                    .font(.system(size: 28))
                    .foregroundColor(.greenPrimary)
                Text("Pas de photo")
                    .font(.system(size: 13))
                    .foregroundColor(.subtitleText)
            }
        }
    }
}

// MARK: - ReceiptResponse helpers

private extension ReceiptResponse {
    var formattedDate: String {
        let parts = date.prefix(10).split(separator: "-")
        guard parts.count == 3 else { return String(date.prefix(10)) }
        return "\(parts[2])/\(parts[1])/\(parts[0])"
    }

    var formattedDateTime: String {
        guard let t = time, !t.isEmpty else { return formattedDate }
        return "\(formattedDate) à \(t)"
    }

    var formattedDateShort: String {
        let parts = date.prefix(10).split(separator: "-")
        guard parts.count == 3 else { return String(date.prefix(10)) }
        return "\(parts[2])/\(parts[1])"
    }

    var formattedDateTimeShort: String {
        guard let t = time, !t.isEmpty else { return formattedDateShort }
        return "\(formattedDateShort) \(t)"
    }
}

// MARK: - Subviews

private struct CategoryRow: View {
    let stat: CategoryStat
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(stat.category)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.bodyText)
                Spacer()
                Text(stat.total.euroFormatted)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.darkText)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.lightCardBg).frame(height: 6)
                    Capsule().fill(Color.greenPrimary).frame(width: geo.size.width * CGFloat(stat.fraction), height: 6)
                }
            }
            .frame(height: 6)
        }
    }
}

struct ReceiptRow: View {
    let receipt: ReceiptResponse
    var body: some View {
        HStack(spacing: 12) {
            RoommateAvatar(user: receipt.user, size: 40, cornerRadius: 13)
            VStack(alignment: .leading, spacing: 2) {
                Text(receipt.store)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.darkText)
                    .lineLimit(1)
                Text(receipt.user.name)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.subtitleText)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("−\(receipt.totalAmount.euroFormatted)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.coralRed)
                Text(receipt.formattedDateTimeShort)
                    .font(.system(size: 11))
                    .foregroundColor(.lightText)
            }
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.lightText)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

// MARK: - Full Screen Photo Viewer

struct FullScreenPhotoViewer: View {
    let url: URL
    @Environment(\.dismiss) private var dismiss
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                        .scaleEffect(scale)
                        .offset(offset)
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    scale = max(1, lastScale * value)
                                }
                                .onEnded { value in
                                    lastScale = scale
                                    if scale <= 1 {
                                        withAnimation(.spring(response: 0.3)) {
                                            scale = 1
                                            lastScale = 1
                                            offset = .zero
                                            lastOffset = .zero
                                        }
                                    }
                                }
                        )
                        .simultaneousGesture(
                            DragGesture()
                                .onChanged { value in
                                    if scale > 1 {
                                        offset = CGSize(
                                            width: lastOffset.width + value.translation.width,
                                            height: lastOffset.height + value.translation.height
                                        )
                                    }
                                }
                                .onEnded { _ in
                                    lastOffset = offset
                                }
                        )
                        .onTapGesture(count: 2) {
                            withAnimation(.spring(response: 0.3)) {
                                if scale > 1 {
                                    scale = 1; lastScale = 1; offset = .zero; lastOffset = .zero
                                } else {
                                    scale = 3; lastScale = 3
                                }
                            }
                        }
                case .empty:
                    ProgressView().tint(.white)
                default:
                    Image(systemName: "photo")
                        .font(.system(size: 48))
                        .foregroundColor(.white.opacity(0.4))
                }
            }

            VStack {
                HStack {
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .padding(16)
                }
                Spacer()
            }
        }
        .statusBarHidden()
    }
}
