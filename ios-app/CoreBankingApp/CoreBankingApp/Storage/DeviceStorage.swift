//
//  DeviceStorage.swift
//  CoreBankingApp
//
//  Created by Yusuf Abbas on 07/06/2026.
//

import Foundation
import UIKit

// MARK: - Device Storage
// Handles everything stored locally on the device

class DeviceStorage {

    static let shared = DeviceStorage()
    private init() {}

    private let defaults = UserDefaults.standard

    // MARK: - Onboarding
    var hasSeenOnboarding: Bool {
        get { defaults.bool(forKey: "hasSeenOnboarding") }
        set { defaults.set(newValue, forKey: "hasSeenOnboarding") }
    }

    // MARK: - Auth Token
    // Stored in UserDefaults for simplicity
    // In production use Keychain
    var accessToken: String? {
        get { defaults.string(forKey: Constants.Keychain.accessToken) }
        set { defaults.set(newValue, forKey: Constants.Keychain.accessToken) }
    }

    var customerId: String? {
        get { defaults.string(forKey: Constants.Keychain.customerId) }
        set { defaults.set(newValue, forKey: Constants.Keychain.customerId) }
    }

    var customerEmail: String? {
        get { defaults.string(forKey: Constants.Keychain.customerEmail) }
        set { defaults.set(newValue, forKey: Constants.Keychain.customerEmail) }
    }

    var customerName: String? {
        get { defaults.string(forKey: "customerName") }
        set { defaults.set(newValue, forKey: "customerName") }
    }

    var isLoggedIn: Bool {
        return accessToken != nil
    }

    // MARK: - Clear on logout
    func clearAuth() {
        accessToken  = nil
        customerId   = nil
        customerEmail = nil
        customerName = nil
    }
}
