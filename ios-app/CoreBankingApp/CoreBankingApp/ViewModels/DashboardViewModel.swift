//
//  DashboardViewModel.swift
//  CoreBankingApp
//
//  Created by Yusuf Abbas on 07/06/2026.
//

import Foundation


class DashboardViewModel {

    // MARK: - Callbacks
    var onAccountsLoaded: (([Account]) -> Void)?
    var onTransactionsLoaded: (([Transaction]) -> Void)?
    var onError: ((String) -> Void)?
    var onLoading: ((Bool) -> Void)?

    // MARK: - State
    private(set) var accounts: [Account] = []
    private(set) var transactions: [Transaction] = []
    private(set) var primaryAccount: Account?

    // MARK: - Load Accounts
    func loadAccounts() {
        onLoading?(true)

        APIService.shared.request(
            endpoint: "/accounts",
            method: "GET",
            responseType: APIResponse<AccountsData>.self
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.onLoading?(false)
                switch result {
                case .success(let response):
                    if response.success, let data = response.data {
                        self?.accounts = data.accounts
                        self?.primaryAccount = data.accounts.first
                        self?.onAccountsLoaded?(data.accounts)
                        // Load transactions for primary account
                        if let accountId = data.accounts.first?.id {
                            self?.loadTransactions(accountId: accountId)
                        }
                    } else {
                        self?.onError?(response.message)
                    }
                case .failure(let error):
                    self?.onError?(error.localizedDescription)
                }
            }
        }
    }

    // MARK: - Load Transactions
    func loadTransactions(accountId: String, limit: Int = 10) {
        APIService.shared.request(
            endpoint: "/accounts/\(accountId)/transactions?limit=\(limit)&offset=0",
            method: "GET",
            responseType: APIResponse<TransactionsData>.self
        ) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    if response.success, let data = response.data {
                        self?.transactions = data.transactions
                        self?.onTransactionsLoaded?(data.transactions)
                    }
                case .failure(let error):
                    self?.onError?(error.localizedDescription)
                }
            }
        }
    }
}
