//
//  LoginViewController.swift
//  CoreBankingApp
//
//  Created by Yusuf Abbas on 07/06/2026.
//

import Foundation
import UIKit

class LoginViewController: UIViewController {

    // MARK: - ViewModel
    private let viewModel = AuthViewModel()

    // MARK: - UI
    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.showsVerticalScrollIndicator = false
        sv.keyboardDismissMode = .onDrag
        return sv
    }()

    private let contentView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    // MARK: - Header
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.text = "Login to your\nAccount"
        l.font = .systemFont(ofSize: 30, weight: .bold)
        l.textColor = .textPrimary
        l.numberOfLines = 2
        return l
    }()

    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.text = "Please provide the following details"
        l.font = .systemFont(ofSize: 15)
        l.textColor = .textSecondary
        return l
    }()

    // MARK: - Form
    private let emailField = CBTextField(
        placeholder: "Email address",
        icon: "envelope",
        keyboardType: .emailAddress
    )
    private let passwordField = CBTextField(
        placeholder: "Password",
        icon: "lock",
        isSecure: true
    )

    // MARK: - Buttons
    private let loginButton = CBButton(title: "Sign In")

    private let forgotButton: UIButton = {
        let b = UIButton(type: .system)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.setTitle("Forgot the password?", for: .normal)
        b.setTitleColor(.primaryBlue, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 14)
        return b
    }()

    private let registerButton: UIButton = {
        let b = UIButton(type: .system)
        b.translatesAutoresizingMaskIntoConstraints = false
        let text = "Don't have an account? Sign Up"
        let attributed = NSMutableAttributedString(string: text)
        attributed.addAttribute(
            .foregroundColor,
            value: UIColor.textSecondary,
            range: NSRange(location: 0, length: 23)
        )
        attributed.addAttribute(
            .foregroundColor,
            value: UIColor.primaryBlue,
            range: NSRange(location: 23, length: 7)
        )
        attributed.addAttribute(
            .font,
            value: UIFont.systemFont(ofSize: 14, weight: .semibold),
            range: NSRange(location: 23, length: 7)
        )
        b.setAttributedTitle(attributed, for: .normal)
        return b
    }()

    // MARK: - Divider
    private let orLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.text = "or continue with"
        l.font = .systemFont(ofSize: 13)
        l.textColor = .textSecondary
        l.textAlignment = .center
        return l
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .appBackground
        setupUI()
        setupActions()
        bindViewModel()
        setupKeyboard()
    }

    // MARK: - Setup UI
    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
        ])

        [titleLabel, subtitleLabel, emailField, passwordField,
         forgotButton, loginButton, orLabel, registerButton
        ].forEach { contentView.addSubview($0) }

        let p = Constants.UI.padding

        NSLayoutConstraint.activate([
            // Title
            titleLabel.topAnchor.constraint(
                equalTo: contentView.topAnchor, constant: 40),
            titleLabel.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor, constant: p),

            // Subtitle
            subtitleLabel.topAnchor.constraint(
                equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor, constant: p),

            // Email
            emailField.topAnchor.constraint(
                equalTo: subtitleLabel.bottomAnchor, constant: 36),
            emailField.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor, constant: p),
            emailField.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor, constant: -p),
            emailField.heightAnchor.constraint(
                equalToConstant: Constants.UI.inputHeight),

            // Password
            passwordField.topAnchor.constraint(
                equalTo: emailField.bottomAnchor, constant: 16),
            passwordField.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor, constant: p),
            passwordField.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor, constant: -p),
            passwordField.heightAnchor.constraint(
                equalToConstant: Constants.UI.inputHeight),

            // Forgot password
            forgotButton.topAnchor.constraint(
                equalTo: passwordField.bottomAnchor, constant: 12),
            forgotButton.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor, constant: -p),

            // Login button
            loginButton.topAnchor.constraint(
                equalTo: forgotButton.bottomAnchor, constant: 24),
            loginButton.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor, constant: p),
            loginButton.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor, constant: -p),
            loginButton.heightAnchor.constraint(
                equalToConstant: Constants.UI.buttonHeight),

            // Or label
            orLabel.topAnchor.constraint(
                equalTo: loginButton.bottomAnchor, constant: 24),
            orLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),

            // Register link
            registerButton.topAnchor.constraint(
                equalTo: orLabel.bottomAnchor, constant: 20),
            registerButton.centerXAnchor.constraint(
                equalTo: contentView.centerXAnchor),
            registerButton.bottomAnchor.constraint(
                equalTo: contentView.bottomAnchor, constant: -40),
        ])
    }

    // MARK: - Actions
    private func setupActions() {
        loginButton.addTarget(
            self, action: #selector(loginTapped), for: .touchUpInside)
        forgotButton.addTarget(
            self, action: #selector(forgotTapped), for: .touchUpInside)
        registerButton.addTarget(
            self, action: #selector(registerTapped), for: .touchUpInside)
    }

    @objc private func loginTapped() {
        view.endEditing(true)
        viewModel.login(
            email:    emailField.text    ?? "",
            password: passwordField.text ?? ""
        )
    }

    @objc private func forgotTapped() {
        // TODO: ForgotPasswordViewController
        let alert = UIAlertController(
            title: "Forgot Password",
            message: "Coming soon.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    @objc private func registerTapped() {
        let vc = RegisterViewController()
        navigationController?.pushViewController(vc, animated: true)
    }

    // MARK: - Bind ViewModel
    private func bindViewModel() {
        viewModel.onLoading = { [weak self] loading in
            self?.loginButton.isLoading = loading
        }

        viewModel.onSuccess = { [weak self] in
            self?.goToDashboard()
        }

        viewModel.onError = { [weak self] message in
            self?.showError(message)
        }
    }

    // MARK: - Navigation
    private func goToDashboard() {
        let dashboard = MainTabBarController()
        let nav = navigationController
        nav?.setViewControllers([dashboard], animated: true)
    }

    // MARK: - Helpers
    private func showError(_ message: String) {
        let alert = UIAlertController(
            title: "Error",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    // MARK: - Keyboard
    private func setupKeyboard() {
        NotificationCenter.default.addObserver(
            self, selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(
            self, selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc private func keyboardWillShow(_ notification: Notification) {
        if let frame = notification.userInfo?[
            UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            scrollView.contentInset.bottom = frame.height + 20
        }
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        scrollView.contentInset.bottom = 0
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
