import SwiftUI
import FirebaseAuth

struct UserPageView: View {
    @State private var email: String = Auth.auth().currentUser?.email ?? "user@example.com"
    @State private var password: String = "********"
    @State private var showPassword = false
    @State private var showEditFields = false
    @State private var newEmail: String = ""
    @State private var newPassword: String = ""
    @State private var errorMessage: String? = nil

    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

    var body: some View {
        VStack(spacing: 20) {
            // Back button and title
            HStack {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "arrow.left.circle.fill")
                        .foregroundColor(.blue)
                }
                .padding(.top, 20)
                Spacer()
                Text("Account Information")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
            }
            .padding(.horizontal)

            // User Info Display
            VStack(alignment: .leading, spacing: 10) {
                Text("Email: \(email)")
                    .font(.body)
                    .padding(.top, 10)

                HStack {
                    Text("Password: ")
                        .font(.body)
                    Text(showPassword ? password : "********")
                        .font(.body)
                        .onTapGesture {
                            showPassword.toggle()
                        }
                }
                .padding(.bottom, 10)
            }
            .padding()

            // Edit Button
            Button(action: {
                showEditFields.toggle()
            }) {
                Text("Edit Account Info")
                    .foregroundColor(.blue)
                    .font(.title3)
                    .padding(.top, 10)
            }

            // Edit Fields and Submit Changes
            if showEditFields {
                VStack(spacing: 15) {
                    TextField("Enter new email", text: $newEmail)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.blue, lineWidth: 1)
                        )
                        .textInputAutocapitalization(.none)
                        .keyboardType(.emailAddress)

                    SecureField("Enter new password", text: $newPassword)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.blue, lineWidth: 1)
                        )

                    Button(action: {
                        saveChanges()
                    }) {
                        Text("Submit Changes")
                            .fontWeight(.bold)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 20)
                    }
                    .padding(.horizontal)
                }
                .padding(.top, 20)
            }

            // Error message
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.body)
                    .padding()
            }

            Spacer()
        }
        .padding()
        .navigationBarBackButtonHidden(true) // Hide the default back button
        .background(Color.white.ignoresSafeArea()) // Set the background to white
    }

    // Function to save the changes
    func saveChanges() {
        guard let user = Auth.auth().currentUser else {
            errorMessage = "No user is currently logged in."
            return
        }

        var hasChanges = false
        
        if !newEmail.isEmpty, newEmail != email {
            hasChanges = true
        }
        
        if !newPassword.isEmpty, newPassword != password {
            hasChanges = true
        }

        if hasChanges {
            let credential = EmailAuthProvider.credential(withEmail: user.email!, password: password)

            user.reauthenticate(with: credential) { _, error in
                if let error = error {
                    errorMessage = "Reauthentication failed: \(error.localizedDescription)"
                    return
                }
                
                if !newEmail.isEmpty {
                    updateEmail(newEmail)
                }
                
                if !newPassword.isEmpty {
                    updatePassword(newPassword)
                }
            }
        } else {
            errorMessage = "No changes to update."
        }
    }

    // Update email in Firebase
    func updateEmail(_ newEmail: String) {
        Auth.auth().currentUser?.updateEmail(to: newEmail) { error in
            if let error = error {
                errorMessage = "Failed to update email: \(error.localizedDescription)"
            } else {
                self.email = newEmail
                print("Email updated successfully")
            }
        }
    }

    // Update password in Firebase
    func updatePassword(_ newPassword: String) {
        Auth.auth().currentUser?.updatePassword(to: newPassword) { error in
            if let error = error {
                errorMessage = "Failed to update password: \(error.localizedDescription)"
            } else {
                self.password = newPassword
                print("Password updated successfully")
            }
        }
    }
}

struct UserPageView_Previews: PreviewProvider {
    static var previews: some View {
        UserPageView()
    }
}
