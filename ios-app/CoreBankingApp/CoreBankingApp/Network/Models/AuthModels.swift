//
//  AuthModels.swift
//  CoreBankingApp
//
//  Created by Yusuf Abbas on 07/06/2026.
//

import Foundation

// MARK: - Register Request
struct RegisterRequest: Codable {
    let firstName: String
    let lastName: String
    let email: String
    let phone: String
    let password: String
    let dateOfBirth: String?
    let address: String?
}

// MARK: - Login Request
struct LoginRequest: Codable {
    let email: String
    let password: String
}

// MARK: - API Response Wrapper
struct APIResponse<T: Codable>: Codable {
    let success: Bool
    let message: String
    let data: T?
}

// MARK: - Auth Response Data
struct AuthResponseData: Codable {
    let customer: CustomerData
    let account: AccountData?
    let accessToken: String
    let system: String?
}

// MARK: - Customer Data
struct CustomerData: Codable {
    let id: String
    let firstName: String?
    let lastName: String?
    let first_name: String?
    let last_name: String?
    let email: String
    let phone: String?
    let kycStatus: String?
    let status: String?

    // Handle both camelCase and snake_case from API
    var fullName: String {
        let first = firstName ?? first_name ?? ""
        let last  = lastName  ?? last_name  ?? ""
        return "\(first) \(last)".trimmingCharacters(in: .whitespaces)
    }
}

// MARK: - Account Data
struct AccountData: Codable {
    let id: String
    let accountNumber: String
    let accountType: String
    let accountName: String
    let currency: String
    let balance: Double?
}
