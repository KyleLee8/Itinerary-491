import SwiftUI
import FirebaseAuth

struct SignUpView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @Environment(\.presentationMode) var presentationMode // To dismiss the view
    @State private var errorMessage: String? // For displaying error messages
    @State private var successMessage: String? // For displaying success messages

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea() // Background color
            
            VStack(spacing: 20) {
                Text("Create Account")
                    .foregroundColor(.blue)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .padding(.top, 40)

                // Blue Outline Rectangle
                VStack(spacing: 20) {
                    // Email TextField
                    TextField("Email", text: $email)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.blue, lineWidth: 1) // Blue border
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
                                .stroke(Color.blue, lineWidth: 1) // Blue border
                        )
                    
                    // Sign Up Button
                    Button(action: {
                        signUp() // Call the sign-up function
                    }) {
                        Text("Sign Up")
                            .bold()
                            .frame(width: 200, height: 40)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(
                                        .linearGradient(colors: [.blue, .cyan], startPoint: .top, endPoint: .bottom)
                                    )
                            )
                            .foregroundColor(.white)
                    }
                }
                .padding()
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.blue, lineWidth: 2) // Blue outline
                )
                .padding(.horizontal)
                
                if let errorMessage = errorMessage { // Display error message if exists
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.top, 10)
                }

                if let successMessage = successMessage { // Display success message if exists
                    Text(successMessage)
                        .foregroundColor(.green)
                        .font(.caption)
                        .padding(.top, 10)
                }
            }
        }
    }
    
    /// Handles user sign-up functionality
    private func signUp() {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Email and password cannot be empty."
            return
        }
        
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                errorMessage = "Sign-up failed: \(error.localizedDescription)"
            } else {
                DispatchQueue.main.async {
                    // Notify user and redirect back to LoginView
                    errorMessage = nil
                    successMessage = "Sign-up successful! Redirecting..."
                    print("Sign-up successful!")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        presentationMode.wrappedValue.dismiss() // Dismiss the sign-up view
                    }
                }
            }
        }
    }
}

struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        SignUpView()
    }
}
