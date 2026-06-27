import SwiftUI

struct WelcomeView: View {
    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Logo + name
            VStack(spacing: 12) {
                if let uiImage = UIImage(named: "logo_habizy") {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 26))
                }
                Text("Habizy")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(hex: "#17C97E"),
                                Color(hex: "#00B4D8"),
                                Color(hex: "#6C63FF"),
                                Color(hex: "#E040A0"),
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                Text("Gérez votre colocation\nen toute sérénité.")
                    .font(.system(size: 16))
                    .foregroundColor(.subtitleText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            Spacer()

            // Action buttons
            VStack(spacing: 12) {
                NavigationLink(value: AuthRoute.register) {
                    Label("Créer un compte", systemImage: "")
                        .labelStyle(.titleOnly)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.greenPrimary)
                        .cornerRadius(18)
                        .shadow(color: Color.greenPrimary.opacity(0.35), radius: 10, x: 0, y: 4)
                }

                NavigationLink(value: AuthRoute.join) {
                    Text("Rejoindre une colocation")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.darkText)
                        .cornerRadius(18)
                        .shadow(color: Color.darkText.opacity(0.25), radius: 8, x: 0, y: 3)
                }

                NavigationLink(value: AuthRoute.login) {
                    Text("Se connecter")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(.darkText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(Color.clear)
                        .cornerRadius(18)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(Color.borderColor, lineWidth: 1.5)
                        )
                }
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 48)
        }
        .background(Color.screenBackground.ignoresSafeArea())
        .navigationBarHidden(true)
    }
}

enum AuthRoute: Hashable {
    case login, register, join
}
