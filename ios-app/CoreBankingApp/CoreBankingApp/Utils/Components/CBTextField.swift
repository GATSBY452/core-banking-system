//
//  CBTextField.swift
//  CoreBankingApp
//
//  Created by Yusuf Abbas on 07/06/2026.
//

import Foundation
import UIKit

// MARK: - Custom Text Field
// Used for all input fields — email, password, amount etc

class CBTextField: UIView {

    // MARK: - UI Elements
    private let containerView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .white
        v.layer.cornerRadius = 12
        v.layer.borderWidth  = 1.5
        v.layer.borderColor  = UIColor.inputBorder.cgColor
        return v
    }()

    private let iconView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFit
        iv.tintColor = .textSecondary
        return iv
    }()

    let textField: UITextField = {
        let tf = UITextField()
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.font = .systemFont(ofSize: 15)
        tf.textColor = .textPrimary
        tf.borderStyle = .none
        tf.autocorrectionType = .no
        tf.spellCheckingType = .no
        return tf
    }()

    private var iconConstraint: NSLayoutConstraint?

    // MARK: - Public Properties
    var text: String? { return textField.text }

    var placeholder: String? {
        didSet {
            textField.placeholder = placeholder
        }
    }

    // MARK: - Init
    init(placeholder: String,
         icon: String? = nil,
         isSecure: Bool = false,
         keyboardType: UIKeyboardType = .default) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        textField.placeholder = placeholder
        textField.isSecureTextEntry = isSecure
        textField.keyboardType = keyboardType
        textField.autocapitalizationType = isSecure ? .none : .words

        if let icon = icon {
            iconView.image = UIImage(systemName: icon)
        }

        setupUI(hasIcon: icon != nil)
        setupFocusHandling()
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Setup UI
    private func setupUI(hasIcon: Bool) {
        addSubview(containerView)
        containerView.addSubview(iconView)
        containerView.addSubview(textField)

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])

        if hasIcon {
            NSLayoutConstraint.activate([
                iconView.leadingAnchor.constraint(
                    equalTo: containerView.leadingAnchor, constant: 16),
                iconView.centerYAnchor.constraint(
                    equalTo: containerView.centerYAnchor),
                iconView.widthAnchor.constraint(equalToConstant: 20),
                iconView.heightAnchor.constraint(equalToConstant: 20),

                textField.leadingAnchor.constraint(
                    equalTo: iconView.trailingAnchor, constant: 12),
                textField.trailingAnchor.constraint(
                    equalTo: containerView.trailingAnchor, constant: -16),
                textField.centerYAnchor.constraint(
                    equalTo: containerView.centerYAnchor),
            ])
        } else {
            NSLayoutConstraint.activate([
                iconView.widthAnchor.constraint(equalToConstant: 0),

                textField.leadingAnchor.constraint(
                    equalTo: containerView.leadingAnchor, constant: 16),
                textField.trailingAnchor.constraint(
                    equalTo: containerView.trailingAnchor, constant: -16),
                textField.centerYAnchor.constraint(
                    equalTo: containerView.centerYAnchor),
            ])
        }
    }

    // MARK: - Focus Handling
    private func setupFocusHandling() {
        textField.addTarget(
            self, action: #selector(didBeginEditing), for: .editingDidBegin)
        textField.addTarget(
            self, action: #selector(didEndEditing), for: .editingDidEnd)
    }

    @objc private func didBeginEditing() {
        UIView.animate(withDuration: 0.2) {
            self.containerView.layer.borderColor = UIColor.primaryBlue.cgColor
            self.containerView.layer.borderWidth = 2
            self.iconView.tintColor = .primaryBlue
        }
    }

    @objc private func didEndEditing() {
        UIView.animate(withDuration: 0.2) {
            self.containerView.layer.borderColor = UIColor.inputBorder.cgColor
            self.containerView.layer.borderWidth = 1.5
            self.iconView.tintColor = .textSecondary
        }
    }
}
