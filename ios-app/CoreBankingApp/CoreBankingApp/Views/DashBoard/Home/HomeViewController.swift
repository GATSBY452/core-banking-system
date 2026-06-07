//
//  HomeViewController.swift
//  CoreBankingApp
//
//  Created by Yusuf Abbas on 07/06/2026.
//

import UIKit

class HomeViewController: UIViewController {

    // MARK: - ViewModel
    private let viewModel = DashboardViewModel()

    // MARK: - Fixed Header
    private let headerView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .primaryBlue
        return v
    }()

    private let greetingLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = .systemFont(ofSize: 14)
        l.textColor = UIColor.white.withAlphaComponent(0.8)
        return l
    }()

    private let nameLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = .systemFont(ofSize: 20, weight: .bold)
        l.textColor = .white
        return l
    }()

    private let avatarView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        v.layer.cornerRadius = 22
        return v
    }()

    private let avatarLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = .systemFont(ofSize: 16, weight: .bold)
        l.textColor = .white
        l.textAlignment = .center
        return l
    }()

    // MARK: - Fixed Balance Card
    private let balanceCard: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .white
        v.layer.cornerRadius = 20
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.1
        v.layer.shadowOffset = CGSize(width: 0, height: 4)
        v.layer.shadowRadius = 12
        return v
    }()

    private let balanceTitleLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.text = "Total Balance"
        l.font = .systemFont(ofSize: 13)
        l.textColor = .textSecondary
        return l
    }()

    private let balanceLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.text = "$0.00"
        l.font = .systemFont(ofSize: 36, weight: .bold)
        l.textColor = .textPrimary
        return l
    }()

    private let accountNumberLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = .systemFont(ofSize: 13)
        l.textColor = .textSecondary
        return l
    }()

    private let loadingIndicator: UIActivityIndicatorView = {
        let i = UIActivityIndicatorView(style: .medium)
        i.translatesAutoresizingMaskIntoConstraints = false
        i.hidesWhenStopped = true
        i.color = .primaryBlue
        return i
    }()

    // MARK: - Fixed Quick Actions
    private let actionsLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.text = "Quick Actions"
        l.font = .systemFont(ofSize: 16, weight: .semibold)
        l.textColor = .textPrimary
        return l
    }()

    private let actionsStack: UIStackView = {
        let sv = UIStackView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.axis = .horizontal
        sv.distribution = .fillEqually
        sv.spacing = 12
        return sv
    }()

    // MARK: - Scrollable Transactions Only
    private let transactionsLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.text = "Recent Transactions"
        l.font = .systemFont(ofSize: 16, weight: .semibold)
        l.textColor = .textPrimary
        return l
    }()

    private let transactionsScrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.showsVerticalScrollIndicator = false
        sv.alwaysBounceVertical = true
        sv.backgroundColor = .clear
        return sv
    }()

    private let transactionsContentView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let transactionsStack: UIStackView = {
        let sv = UIStackView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.axis = .vertical
        sv.spacing = 0
        return sv
    }()

    private let emptyLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.text = "No transactions yet"
        l.font = .systemFont(ofSize: 14)
        l.textColor = .textSecondary
        l.textAlignment = .center
        l.isHidden = true
        return l
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .appBackground
        setupUI()
        setupGreeting()
        bindViewModel()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.loadAccounts()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    // MARK: - Setup UI
    private func setupUI() {
        // Add all fixed views directly to view
        view.addSubview(headerView)
        headerView.addSubview(greetingLabel)
        headerView.addSubview(nameLabel)
        headerView.addSubview(avatarView)
        avatarView.addSubview(avatarLabel)

        view.addSubview(balanceCard)
        balanceCard.addSubview(balanceTitleLabel)
        balanceCard.addSubview(balanceLabel)
        balanceCard.addSubview(accountNumberLabel)
        balanceCard.addSubview(loadingIndicator)

        view.addSubview(actionsLabel)
        view.addSubview(actionsStack)

        // Transactions header is also fixed
        view.addSubview(transactionsLabel)

        // Only the scroll view scrolls
        view.addSubview(transactionsScrollView)
        transactionsScrollView.addSubview(transactionsContentView)
        transactionsContentView.addSubview(transactionsStack)
        transactionsContentView.addSubview(emptyLabel)

        let p = Constants.UI.padding

        NSLayoutConstraint.activate([

            // ── HEADER (fixed, behind status bar) ──
            headerView.topAnchor.constraint(equalTo: view.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 160),

            greetingLabel.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            greetingLabel.leadingAnchor.constraint(
                equalTo: headerView.leadingAnchor, constant: p),

            nameLabel.topAnchor.constraint(
                equalTo: greetingLabel.bottomAnchor, constant: 4),
            nameLabel.leadingAnchor.constraint(
                equalTo: headerView.leadingAnchor, constant: p),

            avatarView.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor),
            avatarView.trailingAnchor.constraint(
                equalTo: headerView.trailingAnchor, constant: -p),
            avatarView.widthAnchor.constraint(equalToConstant: 44),
            avatarView.heightAnchor.constraint(equalToConstant: 44),

            avatarLabel.centerXAnchor.constraint(equalTo: avatarView.centerXAnchor),
            avatarLabel.centerYAnchor.constraint(equalTo: avatarView.centerYAnchor),

            // ── BALANCE CARD (fixed, overlaps header) ──
            balanceCard.topAnchor.constraint(
                equalTo: headerView.bottomAnchor, constant: -20),
            balanceCard.leadingAnchor.constraint(
                equalTo: view.leadingAnchor, constant: 20),
            balanceCard.trailingAnchor.constraint(
                equalTo: view.trailingAnchor, constant: -20),

            balanceTitleLabel.topAnchor.constraint(
                equalTo: balanceCard.topAnchor, constant: 20),
            balanceTitleLabel.leadingAnchor.constraint(
                equalTo: balanceCard.leadingAnchor, constant: p),

            balanceLabel.topAnchor.constraint(
                equalTo: balanceTitleLabel.bottomAnchor, constant: 8),
            balanceLabel.leadingAnchor.constraint(
                equalTo: balanceCard.leadingAnchor, constant: p),

            accountNumberLabel.topAnchor.constraint(
                equalTo: balanceLabel.bottomAnchor, constant: 8),
            accountNumberLabel.leadingAnchor.constraint(
                equalTo: balanceCard.leadingAnchor, constant: p),
            accountNumberLabel.bottomAnchor.constraint(
                equalTo: balanceCard.bottomAnchor, constant: -20),

            loadingIndicator.centerXAnchor.constraint(equalTo: balanceCard.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: balanceCard.centerYAnchor),

            // ── QUICK ACTIONS (fixed) ──
            actionsLabel.topAnchor.constraint(
                equalTo: balanceCard.bottomAnchor, constant: 24),
            actionsLabel.leadingAnchor.constraint(
                equalTo: view.leadingAnchor, constant: p),

            actionsStack.topAnchor.constraint(
                equalTo: actionsLabel.bottomAnchor, constant: 16),
            actionsStack.leadingAnchor.constraint(
                equalTo: view.leadingAnchor, constant: p),
            actionsStack.trailingAnchor.constraint(
                equalTo: view.trailingAnchor, constant: -p),
            actionsStack.heightAnchor.constraint(equalToConstant: 80),

            // ── TRANSACTIONS TITLE (fixed) ──
            transactionsLabel.topAnchor.constraint(
                equalTo: actionsStack.bottomAnchor, constant: 24),
            transactionsLabel.leadingAnchor.constraint(
                equalTo: view.leadingAnchor, constant: p),

            // ── SCROLL VIEW (fills rest of screen) ──
            transactionsScrollView.topAnchor.constraint(
                equalTo: transactionsLabel.bottomAnchor, constant: 12),
            transactionsScrollView.leadingAnchor.constraint(
                equalTo: view.leadingAnchor),
            transactionsScrollView.trailingAnchor.constraint(
                equalTo: view.trailingAnchor),
            transactionsScrollView.bottomAnchor.constraint(
                equalTo: view.bottomAnchor),

            // Content inside scroll view
            transactionsContentView.topAnchor.constraint(
                equalTo: transactionsScrollView.topAnchor),
            transactionsContentView.leadingAnchor.constraint(
                equalTo: transactionsScrollView.leadingAnchor),
            transactionsContentView.trailingAnchor.constraint(
                equalTo: transactionsScrollView.trailingAnchor),
            transactionsContentView.bottomAnchor.constraint(
                equalTo: transactionsScrollView.bottomAnchor),
            transactionsContentView.widthAnchor.constraint(
                equalTo: transactionsScrollView.widthAnchor),

            // Transactions stack inside content
            transactionsStack.topAnchor.constraint(
                equalTo: transactionsContentView.topAnchor),
            transactionsStack.leadingAnchor.constraint(
                equalTo: transactionsContentView.leadingAnchor, constant: p),
            transactionsStack.trailingAnchor.constraint(
                equalTo: transactionsContentView.trailingAnchor, constant: -p),
            transactionsStack.bottomAnchor.constraint(
                equalTo: transactionsContentView.bottomAnchor, constant: -20),

            // Empty label
            emptyLabel.topAnchor.constraint(
                equalTo: transactionsContentView.topAnchor, constant: 40),
            emptyLabel.centerXAnchor.constraint(
                equalTo: transactionsContentView.centerXAnchor),
        ])

        // Build quick action buttons
        let actions: [(String, String, UIColor)] = [
            ("Deposit",  "arrow.down.circle.fill",             .successGreen),
            ("Withdraw", "arrow.up.circle.fill",               .errorRed),
            ("Transfer", "arrow.left.arrow.right.circle.fill", .primaryBlue),
            ("History",  "clock.fill",                         .textSecondary),
        ]
        for (title, icon, color) in actions {
            let button = makeActionButton(title: title, icon: icon, color: color)
            actionsStack.addArrangedSubview(button)
        }
    }

    // MARK: - Greeting
    private func setupGreeting() {
        let hour = Calendar.current.component(.hour, from: Date())
        greetingLabel.text = hour < 12 ? "Good morning! ☀️"
                           : hour < 17 ? "Good afternoon! 👋"
                           : "Good evening! 🌙"
        let name = DeviceStorage.shared.customerName ?? "there"
        nameLabel.text = name
        let initials = name.components(separatedBy: " ")
            .compactMap { $0.first }.map { String($0) }
            .prefix(2).joined().uppercased()
        avatarLabel.text = initials
    }

    // MARK: - Bind ViewModel
    private func bindViewModel() {
        viewModel.onLoading = { [weak self] loading in
            loading
                ? self?.loadingIndicator.startAnimating()
                : self?.loadingIndicator.stopAnimating()
            self?.balanceLabel.isHidden = loading
        }

        viewModel.onAccountsLoaded = { [weak self] accounts in
            guard let account = accounts.first else { return }
            self?.balanceLabel.text = account.formattedBalance
            self?.accountNumberLabel.text = account.account_number
        }

        viewModel.onTransactionsLoaded = { [weak self] txns in
            self?.updateTransactions(txns)
        }

        viewModel.onError = { [weak self] msg in
            let alert = UIAlertController(
                title: "Error", message: msg, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self?.present(alert, animated: true)
        }
    }

    // MARK: - Update Transactions
    private func updateTransactions(_ transactions: [Transaction]) {
        transactionsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        if transactions.isEmpty {
            emptyLabel.isHidden = false
            return
        }
        emptyLabel.isHidden = true

        for txn in transactions {
            transactionsStack.addArrangedSubview(makeTransactionRow(txn))
            let divider = UIView()
            divider.translatesAutoresizingMaskIntoConstraints = false
            divider.backgroundColor = UIColor.inputBorder.withAlphaComponent(0.5)
            divider.heightAnchor.constraint(equalToConstant: 1).isActive = true
            transactionsStack.addArrangedSubview(divider)
        }
    }

    // MARK: - Transaction Row
    private func makeTransactionRow(_ transaction: Transaction) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = .white
        container.heightAnchor.constraint(equalToConstant: 72).isActive = true

        let isCredit = transaction.isCredit

        let iconContainer = UIView()
        iconContainer.translatesAutoresizingMaskIntoConstraints = false
        iconContainer.backgroundColor = isCredit
            ? UIColor.successGreen.withAlphaComponent(0.1)
            : UIColor.errorRed.withAlphaComponent(0.1)
        iconContainer.layer.cornerRadius = 22

        let iconView = UIImageView()
        iconView.translatesAutoresizingMaskIntoConstraints = false
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        iconView.image = UIImage(systemName: transaction.typeIcon,
                                  withConfiguration: config)
        iconView.tintColor = isCredit ? .successGreen : .errorRed
        iconView.contentMode = .scaleAspectFit

        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = transaction.description
        titleLabel.font = .systemFont(ofSize: 14, weight: .medium)
        titleLabel.textColor = .textPrimary

        let dateLabel = UILabel()
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        dateLabel.text = transaction.formattedDate
        dateLabel.font = .systemFont(ofSize: 12)
        dateLabel.textColor = .textSecondary

        let amountLabel = UILabel()
        amountLabel.translatesAutoresizingMaskIntoConstraints = false
        amountLabel.text = transaction.formattedAmount
        amountLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        amountLabel.textColor = isCredit ? .successGreen : .errorRed
        amountLabel.textAlignment = .right

        container.addSubview(iconContainer)
        iconContainer.addSubview(iconView)
        container.addSubview(titleLabel)
        container.addSubview(dateLabel)
        container.addSubview(amountLabel)

        NSLayoutConstraint.activate([
            iconContainer.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            iconContainer.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            iconContainer.widthAnchor.constraint(equalToConstant: 44),
            iconContainer.heightAnchor.constraint(equalToConstant: 44),

            iconView.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 20),
            iconView.heightAnchor.constraint(equalToConstant: 20),

            titleLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(
                equalTo: iconContainer.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(
                equalTo: amountLabel.leadingAnchor, constant: -8),

            dateLabel.topAnchor.constraint(
                equalTo: titleLabel.bottomAnchor, constant: 4),
            dateLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),

            amountLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            amountLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            amountLabel.widthAnchor.constraint(equalToConstant: 90),
        ])

        return container
    }

    // MARK: - Action Buttons
    private func makeActionButton(
        title: String, icon: String, color: UIColor
    ) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let iconContainer = UIView()
        iconContainer.translatesAutoresizingMaskIntoConstraints = false
        iconContainer.backgroundColor = color.withAlphaComponent(0.12)
        iconContainer.layer.cornerRadius = 16

        let iconView = UIImageView()
        iconView.translatesAutoresizingMaskIntoConstraints = false
        let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)
        iconView.image = UIImage(systemName: icon, withConfiguration: config)
        iconView.tintColor = color
        iconView.contentMode = .scaleAspectFit

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = title
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .textSecondary
        label.textAlignment = .center

        container.addSubview(iconContainer)
        iconContainer.addSubview(iconView)
        container.addSubview(label)

        NSLayoutConstraint.activate([
            iconContainer.topAnchor.constraint(equalTo: container.topAnchor),
            iconContainer.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            iconContainer.widthAnchor.constraint(equalToConstant: 52),
            iconContainer.heightAnchor.constraint(equalToConstant: 52),

            iconView.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 24),
            iconView.heightAnchor.constraint(equalToConstant: 24),

            label.topAnchor.constraint(
                equalTo: iconContainer.bottomAnchor, constant: 6),
            label.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])

        let tap = UITapGestureRecognizer(
            target: self, action: #selector(actionTapped(_:)))
        container.addGestureRecognizer(tap)
        container.tag = ["Deposit","Withdraw","Transfer","History"]
            .firstIndex(of: title) ?? 0
        container.isUserInteractionEnabled = true

        return container
    }

    @objc private func actionTapped(_ gesture: UITapGestureRecognizer) {
        guard let tag = gesture.view?.tag else { return }
        let titles = ["Deposit", "Withdraw", "Transfer", "History"]
        let alert = UIAlertController(
            title: titles[tag],
            message: "\(titles[tag]) screen coming next.",
            preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
