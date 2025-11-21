//
//  ForgotPasswordView.swift
//  Citizen_Alerts
//
//  Created on 11/19/25.
//

import SwiftUI

struct ForgotPasswordView: View {
    @State private var email: String = ""
    @State private var emailTouched: Bool = false
    @State private var isSubmitting: Bool = false
    @State private var showSuccess: Bool = false
    @State private var errorMessage: String? = nil
    @Environment(\.dismiss) private var dismiss
    
    private var isEmailValid: Bool {
        Validator.validateEmail(email)
    }
    
    private var canSubmit: Bool {
        isEmailValid && !isSubmitting
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 밝은 배경
                Color.white
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Compact header
                        VStack(spacing: 20) {
                            Image("phi_with_text")
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 40)
                                .foregroundStyle(Color("primaryBlue"))
                                .padding(.top, 60)
                            
                            VStack(spacing: 8) {
                                Text("Forgot Password?")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.primary)
                                
                                Text("Enter your email to receive a password reset link")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, 40)
                        
                        // Form - centered
                        VStack(alignment: .leading, spacing: 16) {
                            if showSuccess {
                                // Success message
                                VStack(spacing: 16) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 60))
                                        .foregroundColor(.green)
                                    
                                    Text("Email Sent!")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                    
                                    Text("We've sent a password reset link to\n\(email)")
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal)
                                    
                                    Text("Please check your email and follow the instructions to reset your password.")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal)
                                    
                                    Button(action: {
                                        dismiss()
                                    }) {
                                        Text("Back to Login")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 16)
                                            .background(
                                                LinearGradient(
                                                    colors: [
                                                        Color("navyGray"),
                                                        Color("navyGray").opacity(0.85)
                                                    ],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .cornerRadius(12)
                                            .shadow(color: Color("navyGray").opacity(0.3), radius: 8, x: 0, y: 4)
                                    }
                                    .padding(.top, 24)
                                }
                            } else {
                                // Email input form
                                VStack(alignment: .leading, spacing: 4) {
                                    TextField("Email address",
                                              text: $email,
                                              onEditingChanged: { began in
                                        if !began { emailTouched = true }
                                    })
                                    .keyboardType(.emailAddress)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled(true)
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color(.systemGray6))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(emailTouched && !isEmailValid ? Color.red : Color.clear, lineWidth: 1.5)
                                            )
                                    )
                                    
                                    if emailTouched && !isEmailValid {
                                        Text("Please enter a valid email address.")
                                            .font(.system(size: 13))
                                            .foregroundColor(.red)
                                            .padding(.leading, 4)
                                    }
                                }
                                
                                // Submit button
                                Button(action: {
                                    guard canSubmit else { return }
                                    
                                    errorMessage = nil
                                    isSubmitting = true
                                    
                                    Task {
                                        do {
                                            try await AuthAPI.forgotPassword(email: email)
                                            
                                            await MainActor.run {
                                                isSubmitting = false
                                                showSuccess = true
                                            }
                                        } catch APIError.serverError(let message) {
                                            await MainActor.run {
                                                errorMessage = message
                                                isSubmitting = false
                                            }
                                        } catch APIError.invalidURL {
                                            await MainActor.run {
                                                errorMessage = "Invalid server URL. Please check your connection settings."
                                                isSubmitting = false
                                            }
                                        } catch APIError.invalidStatusCode(let code) {
                                            await MainActor.run {
                                                errorMessage = "Server error (Status: \(code)). Please try again."
                                                isSubmitting = false
                                            }
                                        } catch let urlError as URLError {
                                            await MainActor.run {
                                                switch urlError.code {
                                                case .notConnectedToInternet:
                                                    errorMessage = "No internet connection. Please check your network."
                                                case .cannotFindHost, .cannotConnectToHost:
                                                    errorMessage = "Cannot connect to server. Please check if the server is running."
                                                case .timedOut:
                                                    errorMessage = "Connection timed out. Please try again."
                                                default:
                                                    errorMessage = "Network error: \(urlError.localizedDescription)"
                                                }
                                                isSubmitting = false
                                            }
                                        } catch {
                                            await MainActor.run {
                                                errorMessage = "Could not reach server. Please try again."
                                                isSubmitting = false
                                            }
                                            print("Forgot password error:", error)
                                        }
                                    }
                                }) {
                                    HStack {
                                        if isSubmitting {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        }
                                        Text(isSubmitting ? "Sending..." : "Send Reset Link")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.white)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(
                                        LinearGradient(
                                            colors: [
                                                Color("navyGray"),
                                                Color("navyGray").opacity(0.85)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .cornerRadius(12)
                                    .shadow(color: Color("navyGray").opacity(0.3), radius: 8, x: 0, y: 4)
                                }
                                .disabled(!canSubmit)
                                .opacity(canSubmit ? 1.0 : 0.5)
                                
                                if let errorMessage {
                                    Text(errorMessage)
                                        .font(.system(size: 13))
                                        .foregroundColor(.red)
                                        .padding(.leading, 4)
                                }
                                
                                // Back to login
                                HStack(spacing: 4) {
                                    Text("Remember your password?")
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                    
                                    Button(action: {
                                        dismiss()
                                    }) {
                                        Text("Sign In")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(Color("primaryBlue"))
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.top, 8)
                            }
                        }
                        .frame(maxWidth: 400)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 40)
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "chevron.left")
                                .foregroundColor(.primary)
                        }
                    }
                }
            }
        }
    }
}

struct ForgotPasswordView_Previews: PreviewProvider {
    static var previews: some View {
        ForgotPasswordView()
    }
}
