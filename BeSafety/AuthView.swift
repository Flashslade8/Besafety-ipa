import SwiftUI

struct AuthView: View {
    @EnvironmentObject var auth: AuthViewModel
    @State private var isSignUp = false
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("BeSafety").font(.largeTitle.bold()).padding(.top, 40)

                Picker("", selection: $isSignUp) {
                    Text("Log in").tag(false)
                    Text("Sign up").tag(true)
                }
                .pickerStyle(.segmented)

                if isSignUp {
                    TextField("Full name", text: $name)
                        .textContentType(.name)
                        .textFieldStyle(.roundedBorder)
                }

                TextField("Email", text: $email)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .textFieldStyle(.roundedBorder)

                SecureField("Password (6+ characters)", text: $password)
                    .textContentType(isSignUp ? .newPassword : .password)
                    .textFieldStyle(.roundedBorder)

                if let msg = auth.errorMessage {
                    Text(msg).font(.footnote).foregroundColor(.red)
                }

                Button {
                    Task {
                        if isSignUp {
                            await auth.signUp(name: name, email: email, password: password)
                        } else {
                            await auth.signIn(email: email, password: password)
                        }
                    }
                } label: {
                    Group {
                        if auth.isLoading { ProgressView().tint(.white) }
                        else { Text(isSignUp ? "Create account" : "Log in") }
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .cornerRadius(12)
                }
                .disabled(auth.isLoading || email.isEmpty || password.count < 6 || (isSignUp && name.isEmpty))

                if !isSignUp {
                    Button("Forgot password?") {
                        Task { await auth.resetPassword(email: email) }
                    }
                    .font(.footnote)
                }

                HStack {
                    Rectangle().frame(height: 1).opacity(0.2)
                    Text("or").font(.footnote).foregroundColor(.secondary)
                    Rectangle().frame(height: 1).opacity(0.2)
                }

                Button {
                    Task { await auth.signInWithGoogle() }
                } label: {
                    Label("Continue with Google", systemImage: "globe")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                }
                .disabled(auth.isLoading)
            }
            .padding()
        }
    }
}
