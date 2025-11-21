//
//  NetworkManager.swift
//  Citizen_Alerts
//
//  Created on 11/19/25.
//

import Foundation

/// 공통 네트워킹 관리자
class NetworkManager {
    static let shared = NetworkManager()
    
    private let session: URLSession
    
    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = APIConfig.timeout
        configuration.timeoutIntervalForResource = APIConfig.timeout
        self.session = URLSession(configuration: configuration)
    }
    
    /// 기본 HTTP 요청 수행
    func request<T: Decodable>(
        url: URL,
        method: HTTPMethod = .GET,
        headers: [String: String]? = nil,
        body: Data? = nil
    ) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 추가 헤더 설정
        headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // 요청 본문 설정
        if let body = body {
            request.httpBody = body
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidStatusCode(-1)
        }
        
        // 상태 코드 확인
        guard (200...299).contains(httpResponse.statusCode) else {
            // 에러 응답 파싱 시도
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw APIError.serverError(errorResponse.message)
            }
            throw APIError.invalidStatusCode(httpResponse.statusCode)
        }
        
        // JSON 디코딩
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingFailed
        }
    }
    
    /// 인증 토큰이 필요한 요청
    func authenticatedRequest<T: Decodable>(
        url: URL,
        method: HTTPMethod = .GET,
        token: String,
        body: Data? = nil
    ) async throws -> T {
        let headers = [
            "Authorization": "Bearer \(token)"
        ]
        return try await request(url: url, method: method, headers: headers, body: body)
    }
}

/// HTTP 메서드
enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case PATCH = "PATCH"
    case DELETE = "DELETE"
}

