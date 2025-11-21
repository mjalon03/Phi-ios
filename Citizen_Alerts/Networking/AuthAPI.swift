//
//  AuthAPI.swift
//  Citizen_Alerts
//
//  Created by Mina on 11/19/25.
//

// Networking/AuthAPI.swift
import Foundation

enum APIError: Error {
    case invalidURL
    case invalidStatusCode(Int)
    case decodingFailed
    case serverError(String)
    case unauthorized
}

struct AuthAPI {
    /// 로그인
    /// - Parameters:
    ///   - email: 사용자 이메일
    ///   - password: 사용자 비밀번호
    /// - Returns: LoginResponse (JWT 토큰 및 사용자 정보 포함)
    static func login(email: String, password: String) async throws -> LoginResponse {
        let urlString = APIConfig.apiPath("auth/login")
        print("🔵 [Login] Request URL: \(urlString)")
        print("🔵 [Login] Base URL: \(APIConfig.baseURL)")
        
        guard let url = URL(string: urlString) else {
            print("❌ [Login] Invalid URL: \(urlString)")
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = LoginRequestDTO(email: email, password: password)
        request.httpBody = try JSONEncoder().encode(body)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ [Login] Invalid response type")
                throw APIError.invalidStatusCode(-1)
            }
            
            print("🔵 [Login] Response Status: \(httpResponse.statusCode)")

            // 에러 응답 파싱 시도
            if !(200...299).contains(httpResponse.statusCode) {
                if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data),
                   let errorString = String(data: data, encoding: .utf8) {
                    print("❌ [Login] Error Response: \(errorString)")
                    throw APIError.serverError(errorResponse.message)
                }
                if let errorString = String(data: data, encoding: .utf8) {
                    print("❌ [Login] Error Response (raw): \(errorString)")
                }
                throw APIError.invalidStatusCode(httpResponse.statusCode)
            }

            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let loginResponse = try decoder.decode(LoginResponse.self, from: data)
                print("✅ [Login] Success: \(loginResponse.user.email ?? "unknown")")
                return loginResponse
            } catch {
                if let errorString = String(data: data, encoding: .utf8) {
                    print("❌ [Login] Decoding failed. Response: \(errorString)")
                }
                print("❌ [Login] Decoding error: \(error)")
                throw APIError.decodingFailed
            }
        } catch let error as APIError {
            throw error
        } catch {
            print("❌ [Login] Network error: \(error.localizedDescription)")
            print("❌ [Login] Error type: \(type(of: error))")
            throw error
        }
    }
    
    /// 회원가입
    /// - Parameter request: 회원가입 요청 데이터
    /// - Returns: UserResponseDTO (생성된 사용자 정보)
    static func signup(_ request: SignupRequest) async throws -> UserResponseDTO {
        let urlString = APIConfig.apiPath("auth/signup")
        print("🔵 [Signup] Request URL: \(urlString)")
        print("🔵 [Signup] Base URL: \(APIConfig.baseURL)")
        
        guard let url = URL(string: urlString) else {
            print("❌ [Signup] Invalid URL: \(urlString)")
            throw APIError.invalidURL
        }

        var httpRequest = URLRequest(url: url)
        httpRequest.httpMethod = "POST"
        httpRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        httpRequest.httpBody = try JSONEncoder().encode(request)
        
        // 요청 본문 로그 (디버깅용)
        if let bodyData = httpRequest.httpBody,
           let bodyString = String(data: bodyData, encoding: .utf8) {
            print("🔵 [Signup] Request Body: \(bodyString)")
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: httpRequest)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ [Signup] Invalid response type")
                throw APIError.invalidStatusCode(-1)
            }
            
            print("🔵 [Signup] Response Status: \(httpResponse.statusCode)")
            
            // 에러 응답 파싱 시도
            if !(200...299).contains(httpResponse.statusCode) {
                if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data),
                   let errorString = String(data: data, encoding: .utf8) {
                    print("❌ [Signup] Error Response: \(errorString)")
                    throw APIError.serverError(errorResponse.message)
                }
                if let errorString = String(data: data, encoding: .utf8) {
                    print("❌ [Signup] Error Response (raw): \(errorString)")
                }
                throw APIError.invalidStatusCode(httpResponse.statusCode)
            }

            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let userResponse = try decoder.decode(UserResponseDTO.self, from: data)
                print("✅ [Signup] Success: \(userResponse.email ?? "unknown")")
                return userResponse
            } catch {
                if let errorString = String(data: data, encoding: .utf8) {
                    print("❌ [Signup] Decoding failed. Response: \(errorString)")
                }
                print("❌ [Signup] Decoding error: \(error)")
                throw APIError.decodingFailed
            }
        } catch let error as APIError {
            throw error
        } catch {
            print("❌ [Signup] Network error: \(error.localizedDescription)")
            print("❌ [Signup] Error type: \(type(of: error))")
            throw error
        }
    }
    
    /// 비밀번호 찾기 (이메일로 재설정 링크 전송)
    /// - Parameter email: 사용자 이메일
    static func forgotPassword(email: String) async throws {
        let urlString = APIConfig.apiPath("auth/forgot-password")
        print("🔵 [ForgotPassword] Request URL: \(urlString)")
        print("🔵 [ForgotPassword] Base URL: \(APIConfig.baseURL)")
        
        guard let url = URL(string: urlString) else {
            print("❌ [ForgotPassword] Invalid URL: \(urlString)")
            throw APIError.invalidURL
        }

        var httpRequest = URLRequest(url: url)
        httpRequest.httpMethod = "POST"
        httpRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let request = ForgotPasswordRequest(email: email)
        httpRequest.httpBody = try JSONEncoder().encode(request)
        
        // 요청 본문 로그 (디버깅용)
        if let bodyData = httpRequest.httpBody,
           let bodyString = String(data: bodyData, encoding: .utf8) {
            print("🔵 [ForgotPassword] Request Body: \(bodyString)")
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: httpRequest)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ [ForgotPassword] Invalid response type")
                throw APIError.invalidStatusCode(-1)
            }
            
            print("🔵 [ForgotPassword] Response Status: \(httpResponse.statusCode)")
            
            // 에러 응답 파싱 시도
            if !(200...299).contains(httpResponse.statusCode) {
                if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data),
                   let errorString = String(data: data, encoding: .utf8) {
                    print("❌ [ForgotPassword] Error Response: \(errorString)")
                    throw APIError.serverError(errorResponse.message)
                }
                if let errorString = String(data: data, encoding: .utf8) {
                    print("❌ [ForgotPassword] Error Response (raw): \(errorString)")
                }
                throw APIError.invalidStatusCode(httpResponse.statusCode)
            }
            
            print("✅ [ForgotPassword] Success: Password reset email sent")
        } catch let error as APIError {
            throw error
        } catch {
            print("❌ [ForgotPassword] Network error: \(error.localizedDescription)")
            print("❌ [ForgotPassword] Error type: \(type(of: error))")
            throw error
        }
    }
}
