//
//  APIService.swift
//  CoreBankingApp
//
//  Created by Yusuf Abbas on 07/06/2026.
//

import Foundation

// MARK: - API Error
enum APIError: Error, LocalizedError {
    case invalidURL
    case noData
    case decodingError(String)
    case serverError(String)
    case networkError(String)
    case unauthorized

    var errorDescription: String? {
        switch self {
        case .invalidURL:            return "Invalid URL."
        case .noData:                return "No data received."
        case .decodingError(let m):  return "Decoding error: \(m)"
        case .serverError(let m):    return m
        case .networkError(let m):   return "Network error: \(m)"
        case .unauthorized:          return "Session expired. Please log in again."
        }
    }
}

// MARK: - API Service
class APIService {

    static let shared = APIService()
    private init() {}

    private let baseURL = Constants.API.baseURL
    private let session = URLSession.shared

    // MARK: - Generic Request
    func request<T: Codable>(
        endpoint: String,
        method: String = "GET",
        body: Encodable? = nil,
        responseType: T.Type,
        completion: @escaping (Result<T, APIError>) -> Void
    ) {
        guard let url = URL(string: baseURL + endpoint) else {
            log("❌ INVALID URL: \(baseURL + endpoint)")
            completion(.failure(.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        // Add auth token only for protected routes
        // Never add token to auth endpoints
        let publicEndpoints = ["/auth/login", "/auth/register"]
        let isPublicEndpoint = publicEndpoints.contains(where: { endpoint.contains($0) })

        if !isPublicEndpoint, let token = DeviceStorage.shared.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        // Add body
        if let body = body {
            do {
                let encoded = try JSONEncoder().encode(body)
                request.httpBody = encoded
            } catch {
                log("❌ ENCODE ERROR: \(error.localizedDescription)")
                completion(.failure(.networkError("Failed to encode request")))
                return
            }
        }

        // Log the outgoing request
        logRequest(request)

        // Make the request
        session.dataTask(with: request) { data, response, error in

            // Network error
            if let error = error {
                self.log("❌ NETWORK ERROR: \(error.localizedDescription)")
                completion(.failure(.networkError(error.localizedDescription)))
                return
            }

            // Log the response
            self.logResponse(response, data: data)

            // Check HTTP status
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 401 {
                    self.log("🔒 UNAUTHORIZED — token expired or invalid")
                    completion(.failure(.unauthorized))
                    return
                }
            }

            guard let data = data else {
                self.log("❌ NO DATA received")
                completion(.failure(.noData))
                return
            }

            // Decode response
            do {
                let decoded = try JSONDecoder().decode(T.self, from: data)
                self.log("✅ DECODED SUCCESSFULLY as \(T.self)")
                completion(.success(decoded))
            } catch {
                self.log("❌ DECODE ERROR: \(error.localizedDescription)")
                // Try to extract error message from response
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let message = json["message"] as? String {
                    self.log("   Server message: \(message)")
                    completion(.failure(.serverError(message)))
                } else {
                    completion(.failure(.decodingError(error.localizedDescription)))
                }
            }
        }.resume()
    }

    // MARK: - Logging

    private func log(_ message: String) {
        print("[APIService] \(message)")
    }

    private func logRequest(_ request: URLRequest) {
        let method   = request.httpMethod ?? "GET"
        let url      = request.url?.absoluteString ?? "unknown"
        let hasToken = request.value(forHTTPHeaderField: "Authorization") != nil

        print("")
        print("┌─────────────────────────────────────")
        print("│ 📤 REQUEST")
        print("│ \(method) \(url)")
        print("│ Auth: \(hasToken ? "✅ Bearer token present" : "❌ No token")")

        if let body = request.httpBody,
           let json = try? JSONSerialization.jsonObject(with: body) as? [String: Any] {
            // Mask password fields for security
            var safeJson = json
            if safeJson["password"] != nil    { safeJson["password"]    = "***" }
            if safeJson["confirmPassword"] != nil { safeJson["confirmPassword"] = "***" }
            print("│ Body: \(safeJson)")
        }

        print("└─────────────────────────────────────")
    }

    private func logResponse(_ response: URLResponse?, data: Data?) {
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
        let statusEmoji = statusCode >= 200 && statusCode < 300 ? "✅" : "❌"

        print("")
        print("┌─────────────────────────────────────")
        print("│ 📥 RESPONSE")
        print("│ Status: \(statusEmoji) \(statusCode)")

        if let data = data {
            print("│ Size: \(data.count) bytes")
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                // Show clean summary
                let success = json["success"] as? Bool ?? false
                let message = json["message"] as? String ?? ""
                print("│ Success: \(success ? "✅" : "❌")")
                print("│ Message: \(message)")

                // Show data keys if present
                if let dataObj = json["data"] as? [String: Any] {
                    print("│ Data keys: \(Array(dataObj.keys).joined(separator: ", "))")
                }

                // Show full JSON in debug builds
                #if DEBUG
                if let prettyData = try? JSONSerialization.data(
                    withJSONObject: json, options: .prettyPrinted),
                   let prettyString = String(data: prettyData, encoding: .utf8) {
                    // Mask token in logs
                    let masked = prettyString.replacingOccurrences(
                        of: #"\"accessToken\" : \"[^\"]+\""#,
                        with: "\"accessToken\" : \"***\"",
                        options: .regularExpression
                    )
                    print("│ Full response:")
                    masked.components(separatedBy: "\n").forEach {
                        print("│   \($0)")
                    }
                }
                #endif
            }
        }

        print("└─────────────────────────────────────")
        print("")
    }
}
