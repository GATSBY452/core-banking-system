//
//  AccountModels.swift
//  CoreBankingApp
//
//  Created by Yusuf Abbas on 07/06/2026.
//

import Foundation


// MARK: - Account
struct Account: Codable {
    let id: String
    let customer_id: String?
    let account_number: String
    let account_type: String
    let account_name: String
    let currency: String
    let status: String
    let balance: String
    let created_at: String?

    var balanceDouble: Double {
        return Double(balance) ?? 0
    }

    var formattedBalance: String {
        let amount = balanceDouble
        return String(format: "%@%.2f", currency == "USD" ? "$" : "", amount)
    }
}

// MARK: - Accounts Response
struct AccountsData: Codable {
    let accounts: [Account]
    let count: Int
}

// MARK: - Transaction
struct Transaction: Codable {
    let id: String
    let reference: String
    let type: String
    let description: String
    let amount: String
    let status: String
    let created_at: String
    let entry_type: String?
    let running_balance: String?

    var amountDouble: Double {
        return Double(amount) ?? 0
    }

    var isCredit: Bool {
        return entry_type == "CREDIT"
    }

    var formattedAmount: String {
        let prefix = isCredit ? "+" : "-"
        return "\(prefix)$\(String(format: "%.2f", amountDouble))"
    }

    var formattedDate: String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: created_at) {
            let display = DateFormatter()
            display.dateFormat = "MMM dd, yyyy"
            return display.string(from: date)
        }
        return created_at
    }

    var typeIcon: String {
        switch type {
        case "deposit":    return "arrow.down.circle.fill"
        case "withdrawal": return "arrow.up.circle.fill"
        case "transfer":   return "arrow.left.arrow.right.circle.fill"
        case "reversal":   return "arrow.uturn.left.circle.fill"
        default:           return "circle.fill"
        }
    }
}

// MARK: - Transactions Response
struct TransactionsData: Codable {
    let transactions: [Transaction]
}
