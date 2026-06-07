//
//  RegisterViewController.swift
//  CoreBankingApp
//
//  Created by Yusuf Abbas on 07/06/2026.
//

import UIKit

class RegisterViewController: UIViewController {

    // MARK: - ViewModel
    private let viewModel = AuthViewModel()

    // MARK: - Scroll
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
        l.text = "Create your\nAccount"
        l.font = .systemFont(ofSize: 30, weight: .bold)
        l.textColor = .textPrimary
        l.numberOfLines = 2
        return l
    }()

    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.text = "Fill in your details to get started"
        l.font = .systemFont(ofSize: 15)
        l.textColor = .textSecondary
        return l
    }()

    // MARK: - Form Fields
    private let firstNameField = CBTextField(
        placeholder: "First name",
        icon: "person"
    )
    private let lastNameField = CBTextField(
        placeholder: "Last name",
        icon: "person"
    )
    private let emailField = CBTextField(
        placeholder: "Email address",
        icon: "envelope",
        keyboardType: .emailAddress
    )
    private let phoneField = CBTextField(
        placeholder: "Phone number",
        icon: "phone",
        keyboardType: .phonePad
    )
    private let passwordField = CBTextField(
        placeholder: "Password",
        icon: "lock",
        isSecure: true
    )
    private let confirmPasswordField = CBTextField(
        placeholder: "Confirm password",
        icon: "lock",
        isSecure: true
    )

    // MARK: - Buttons
    private let registerButton = CBButton(title: "Sign Up")

    private let loginButton: UIButton = {
        let b = UIButton(type: .system)
        b.translatesAutoresizingMaskIntoConstraints = false
        let text = "Already have an account? Sign In"
        let attributed = NSMutableAttributedString(string: text)
        attributed.addAttribute(
            .foregroundColor,
            value: UIColor.textSecondary,
            range: NSRange(location: 0, length: 25)
        )
        attributed.addAttribute(
            .foregroundColor,
            value: UIColor.primaryBlue,
            range: NSRange(location: 25, length: 7)
        )
        attributed.addAttribute(
            .font,
            value: UIFont.systemFont(ofSize: 14, weight: .semibold),
            range: NSRange(location: 25, length: 7)
        )
        b.setAttributedTitle(attributed, for: .normal)
        return b
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .appBackground
        setupUI()
        setupActions()
        bindViewModel()
        setupKeyboardHandling()
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

        // Add all subviews to contentView
        [titleLabel, subtitleLabel,
         firstNameField, lastNameField,
         emailField, phoneField,
         passwordField, confirmPasswordField,
         registerButton, loginButton
        ].forEach { contentView.addSubview($0) }

        let p = Constants.UI.padding

        NSLayoutConstraint.activate([
            // Title
            titleLabel.topAnchor.constraint(
                equalTo: contentView.topAnchor, constant: 32),
            titleLabel.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor, constant: p),

            // Subtitle
            subtitleLabel.topAnchor.constraint(
                equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor, constant: p),

            // First name
            firstNameField.topAnchor.constraint(
                equalTo: subtitleLabel.bottomAnchor, constant: 32),
            firstNameField.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor, constant: p),
            firstNameField.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor, constant: -p),
            firstNameField.heightAnchor.constraint(
                equalToConstant: Constants.UI.inputHeight),

            // Last name
            lastNameField.topAnchor.constraint(
                equalTo: firstNameField.bottomAnchor, constant: 16),
            lastNameField.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor, constant: p),
            lastNameField.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor, constant: -p),
            lastNameField.heightAnchor.constraint(
                equalToConstant: Constants.UI.inputHeight),

            // Email
            emailField.topAnchor.constraint(
                equalTo: lastNameField.bottomAnchor, constant: 16),
            emailField.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor, constant: p),
            emailField.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor, constant: -p),
            emailField.heightAnchor.constraint(
                equalToConstant: Constants.UI.inputHeight),

            // Phone
            phoneField.topAnchor.constraint(
                equalTo: emailField.bottomAnchor, constant: 16),
            phoneField.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor, constant: p),
            phoneField.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor, constant: -p),
            phoneField.heightAnchor.constraint(
                equalToConstant: Constants.UI.inputHeight),

            // Password
            passwordField.topAnchor.constraint(
                equalTo: phoneField.bottomAnchor, constant: 16),
            passwordField.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor, constant: p),
            passwordField.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor, constant: -p),
            passwordField.heightAnchor.constraint(
                equalToConstant: Constants.UI.inputHeight),

            // Confirm password
            confirmPasswordField.topAnchor.constraint(
                equalTo: passwordField.bottomAnchor, constant: 16),
            confirmPasswordField.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor, constant: p),
            confirmPasswordField.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor, constant: -p),
            confirmPasswordField.heightAnchor.constraint(
                equalToConstant: Constants.UI.inputHeight),

            // Register button
            registerButton.topAnchor.constraint(
                equalTo: confirmPasswordField.bottomAnchor, constant: 32),
            registerButton.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor, constant: p),
            registerButton.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor, constant: -p),
            registerButton.heightAnchor.constraint(
                equalToConstant: Constants.UI.buttonHeight),

            // Login link
            loginButton.topAnchor.constraint(
                equalTo: registerButton.bottomAnchor, constant: 20),
            loginButton.centerXAnchor.constraint(
                equalTo: contentView.centerXAnchor),
            loginButton.bottomAnchor.constraint(
                equalTo: contentView.bottomAnchor, constant: -40),
        ])
    }

    // MARK: - Actions
    private func setupActions() {
        registerButton.addTarget(
            self, action: #selector(registerTapped), for: .touchUpInside)
        loginButton.addTarget(
            self, action: #selector(loginTapped), for: .touchUpInside)
    }

    @objc private func registerTapped() {
        view.endEditing(true)

        // Check passwords match
        guard passwordField.text == confirmPasswordField.text else {
            showError("Passwords do not match.")
            return
        }

        viewModel.register(
            firstName: firstNameField.text ?? "",
            lastName:  lastNameField.text  ?? "",
            email:     emailField.text     ?? "",
            phone:     phoneField.text     ?? "",
            password:  passwordField.text  ?? ""
        )
    }

    @objc private func loginTapped() {
        navigationController?.popViewController(animated: true)
    }

    // MARK: - Bind ViewModel
    private func bindViewModel() {
        viewModel.onLoading = { [weak self] loading in
            self?.registerButton.isLoading = loading
        }

        viewModel.onSuccess = { [weak self] in
            // Registration successful → go to dashboard
            self?.goToDashboard()
        }

        viewModel.onError = { [weak self] message in
            self?.showError(message)
        }
    }

    // MARK: - Navigation
    private func goToDashboard() {
        let dashboard = MainTabBarController()
        navigationController?.setViewControllers([dashboard], animated: true)
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
    private func setupKeyboardHandling() {
        NotificationCenter.default.addObserver(
            self, selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(
            self, selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc private func keyboardWillShow(_ notification: Notification) {
        if let keyboardFrame = notification.userInfo?[
            UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            scrollView.contentInset.bottom = keyboardFrame.height + 20
        }
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        scrollView.contentInset.bottom = 0
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
