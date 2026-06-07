//
//  Constants.swift
//  CoreBankingApp
//
//  Created by Yusuf Abbas on 07/06/2026.
//

import Foundation

struct Constants {

    // MARK: - API
    // Spring Boot Gateway — iOS only talks to this
    // Never talks to Node.js (3000) or blockchain (3001) directly
    struct API {
        static let baseURL = "http://192.168.100.39:8080/api/v1"
    }

    // MARK: - Keychain Keys
    struct Keychain {
        static let accessToken   = "cb_access_token"
        static let customerId    = "cb_customer_id"
        static let customerEmail = "cb_customer_email"
    }

    // MARK: - UserDefaults Keys
    struct Defaults {
        static let hasSeenOnboarding = "has_seen_onboarding"
        static let isLoggedIn        = "is_logged_in"
    }

    // MARK: - UI
    struct UI {
        static let cornerRadius:      CGFloat = 14
        static let buttonHeight:      CGFloat = 56
        static let inputHeight:       CGFloat = 56
        static let padding:           CGFloat = 24
        static let cardShadowOpacity: Float   = 0.08
    }
}
