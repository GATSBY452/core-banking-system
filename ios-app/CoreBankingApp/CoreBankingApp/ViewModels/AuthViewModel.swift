//
//  AuthViewModel.swift
//  CoreBankingApp
//
//  Created by Yusuf Abbas on 07/06/2026.
//

import Foundation

// MARK: - Auth ViewModel
// Handles all auth business logic
// Controllers call this — never touch APIService directly

class AuthViewModel {

    // MARK: - Callbacks
    // Controllers bind to these closures
    var onSuccess: (() -> Void)?
    var onError: ((String) -> Void)?
    var onLoading: ((Bool) -> Void)?

    // MARK: - State
    private(set) var customer: CustomerData?
    private(set) var account: AccountData?

    // MARK: - Register
    func register(
        firstName: String,
        lastName: String,
        email: String,
        phone: String,
        password: String
    ) {
        // Validate
        guard !firstName.isEmpty, !lastName.isEmpty else {
            onError?("Please enter your full name.")
            return
        }
        guard !email.isEmpty, email.contains("@") else {
            onError?("Please enter a valid email.")
            return
        }
        guard !phone.isEmpty else {
            onError?("Please enter your phone number.")
            return
        }
        guard password.count >= 6 else {
            onError?("Password must be at least 6 characters.")
            return
        }

        onLoading?(true)

        let request = RegisterRequest(
            firstName:   firstName,
            lastName:    lastName,
            email:       email,
            phone:       phone,
            password:    password,
            dateOfBirth: nil,
            address:     nil
        )

        APIService.shared.request(
            endpoint:     "/auth/register",
            method:       "POST",
            body:         request,
            responseType: APIResponse<AuthResponseData>.self
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.onLoading?(false)

                switch result {
                case .success(let response):
                    if response.success, let data = response.data {
                        // Save to device storage
                        DeviceStorage.shared.accessToken  = data.accessToken
                        DeviceStorage.shared.customerId   = data.customer.id
                        DeviceStorage.shared.customerEmail = data.customer.email
                        DeviceStorage.shared.customerName = data.customer.fullName

                        self?.customer = data.customer
                        self?.account  = data.account
                        self?.onSuccess?()
                    } else {
                        self?.onError?(response.message)
                    }

                case .failure(let error):
                    self?.onError?(error.localizedDescription)
                }
            }
        }
    }

    // MARK: - Login
    func login(email: String, password: String) {
        DeviceStorage.shared.clearAuth()
        
        guard !email.isEmpty, email.contains("@") else {
            onError?("Please enter a valid email.")
            return
        }
        guard !password.isEmpty else {
            onError?("Please enter your password.")
            return
        }

        onLoading?(true)

        let request = LoginRequest(email: email, password: password)

        APIService.shared.request(
            endpoint:     "/auth/login",
            method:       "POST",
            body:         request,
            responseType: APIResponse<AuthResponseData>.self
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.onLoading?(false)

                switch result {
                case .success(let response):
                    if response.success, let data = response.data {
                        // Save to device storage
                        DeviceStorage.shared.accessToken   = data.accessToken
                        DeviceStorage.shared.customerId    = data.customer.id
                        DeviceStorage.shared.customerEmail = data.customer.email
                        DeviceStorage.shared.customerName  = data.customer.fullName

                        self?.customer = data.customer
                        self?.onSuccess?()
                    } else {
                        self?.onError?(response.message)
                    }

                case .failure(let error):
                    self?.onError?(error.localizedDescription)
                }
            }
        }
    }

    // MARK: - Logout
    func logout() {
        DeviceStorage.shared.clearAuth()
    }
}
