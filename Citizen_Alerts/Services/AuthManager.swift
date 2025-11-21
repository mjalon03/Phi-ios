//
//  AuthManager.swift
//  Citizen_Alerts
//
//  Created on 11/19/25.
//

import Foundation
import Combine

/// 인증 상태 관리자
@MainActor
class AuthManager: ObservableObject {
    static let shared = AuthManager()
    
    @Published var isAuthenticated: Bool = false
    @Published var currentUser: User?
    
    private let userDefaults = UserDefaults.standard
    private let isLoggedInKey = "isLoggedIn"
    private let userDataKey = "currentUserData"
    private let tokenKey = "jwt_token"
    
    /// 현재 JWT 토큰
    var token: String? {
        return userDefaults.string(forKey: tokenKey)
    }
    
    private init() {
        // 앱 시작 시 저장된 로그인 상태 확인
        loadAuthState()
    }
    
    /// 로그인 상태 로드
    private func loadAuthState() {
        // 토큰이 있으면 인증된 것으로 간주
        isAuthenticated = userDefaults.string(forKey: tokenKey) != nil
        
        if let userData = userDefaults.data(forKey: userDataKey),
           let user = try? JSONDecoder().decode(User.self, from: userData) {
            currentUser = user
        }
    }
    
    /// 로그인 처리 (JWT 토큰 포함)
    func login(user: User, token: String) {
        currentUser = user
        isAuthenticated = true
        
        // 토큰 저장
        userDefaults.set(token, forKey: tokenKey)
        
        // 상태 저장
        userDefaults.set(true, forKey: isLoggedInKey)
        if let userData = try? JSONEncoder().encode(user) {
            userDefaults.set(userData, forKey: userDataKey)
        }
    }
    
    /// 로그아웃 처리
    func logout() {
        currentUser = nil
        isAuthenticated = false
        
        // 저장된 상태 제거
        userDefaults.removeObject(forKey: isLoggedInKey)
        userDefaults.removeObject(forKey: userDataKey)
        userDefaults.removeObject(forKey: tokenKey)
    }
    
    /// 토큰 존재 여부 확인
    func hasToken() -> Bool {
        return token != nil
    }
}

