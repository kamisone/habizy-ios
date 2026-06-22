import SwiftUI

struct ContributeView: View {
    @StateObject private var vm: ContributeViewModel

    init(tokenManager: TokenManager) {
        _vm = StateObject(wrappedValue: ContributeViewModel(tokenManager: tokenManager))
    }

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "xmark.circle")
                .font(.system(size: 48))
                .foregroundColor(.subtitleText)
            Text("Fonctionnalité supprimée")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(.darkText)
            Text("Le système de cotisations a été retiré de l'application.")
                .font(.system(size: 14))
                .foregroundColor(.subtitleText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.screenBackground.ignoresSafeArea())
        .navigationTitle("Cotiser")
        .navigationBarTitleDisplayMode(.large)
    }
}
