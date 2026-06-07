//
//  AppColors.swift
//  CoreBankingApp
//
//  Created by Yusuf Abbas on 07/06/2026.
//

import Foundation
import UIKit

// MARK: - App Colors (AllPay Blue Design System)
extension UIColor {

    // Primary — the main blue from your design
    static let primaryBlue  = UIColor(red: 0.18, green: 0.38, blue: 0.98, alpha: 1)
    static let primaryDark  = UIColor(red: 0.12, green: 0.28, blue: 0.85, alpha: 1)
    static let primaryLight = UIColor(red: 0.35, green: 0.55, blue: 1.00, alpha: 1)

    // Background
    static let appBackground  = UIColor(red: 0.97, green: 0.97, blue: 0.99, alpha: 1)
    static let cardBackground = UIColor.white

    // Text
    static let textPrimary   = UIColor(red: 0.10, green: 0.10, blue: 0.15, alpha: 1)
    static let textSecondary = UIColor(red: 0.55, green: 0.57, blue: 0.63, alpha: 1)
    static let textLight     = UIColor(red: 0.75, green: 0.76, blue: 0.80, alpha: 1)

    // Input fields
    static let inputBorder   = UIColor(red: 0.88, green: 0.90, blue: 0.94, alpha: 1)
    static let inputFocused  = UIColor.primaryBlue

    // Status colors
    static let successGreen = UIColor(red: 0.20, green: 0.78, blue: 0.35, alpha: 1)
    static let errorRed     = UIColor(red: 0.95, green: 0.25, blue: 0.25, alpha: 1)
    static let warningOrange = UIColor(red: 1.00, green: 0.60, blue: 0.10, alpha: 1)
}
