import SwiftUI
import Firebase
import FirebaseAuth

struct LoginView: View {
    @State private var email = "" // Email input
    @State private var password = "" // Password input
    @State private var isLoggedIn = false // Tracks login state
    @State private var showingSignUp = false // Tracks navigation to SignUpView

    var body: some View {
        NavigationView {
            ZStack {
                Color.white.ignoresSafeArea() // Background color
                
                VStack(spacing: 20) {
                    // Title
                    Text("Itravelary")
                        .foregroundColor(.blue)
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .padding(.top, 40)

                    // Login Header
                    Text("Login")
                        .foregroundColor(.blue)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .padding(.bottom, 20)

                    // Login Form
                    VStack(spacing: 20) {
                        // Email TextField
                        TextField("Email", text: $email)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.blue, lineWidth: 1)
                            )
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)

                        // Password SecureField
                        SecureField("Password", text: $password)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.blue, lineWidth: 1)
                            )

                        // Login Button
                        Button(action: {
                            login()
                        }) {
                            Text("Login")
                                .bold()
                                .frame(width: 200, height: 40)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(
                                            LinearGradient(colors: [.blue, .cyan], startPoint: .top, endPoint: .bottom)
                                        )
                                )
                                .foregroundColor(.white)
                        }

                        // Sign-Up Navigation
                        Button(action: {
                            showingSignUp = true // Navigate to SignUpView
                        }) {
                            Text("Sign up")
                                .bold()
                                .foregroundColor(.blue)
                        }
                    }
                    .padding()
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.blue, lineWidth: 2)
                    )
                    .padding(.horizontal)
                }
                .onAppear {
                    Auth.auth().addStateDidChangeListener { _, user in
                        if user != nil {
                            DispatchQueue.main.async {
                                isLoggedIn = true // Navigate to ContentView on login
                            }
                        }
                    }
                }
            }
            .background(
                NavigationLink(
                    destination: ContentView(),
                    isActive: $isLoggedIn
                ) {
                    EmptyView()
                }
                .hidden()
            )
            .sheet(isPresented: $showingSignUp) {
                SignUpView()
            }
        }
    }

    /// Handles user login
    func login() {
        guard !email.isEmpty, !password.isEmpty else {
            print("Email and password cannot be empty.")
            return
        }

        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                print("Login failed: \(error.localizedDescription)")
            } else {
                DispatchQueue.main.async {
                    isLoggedIn = true
                }
            }
        }
    }
}
