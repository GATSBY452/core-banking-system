//
//  OnboardingViewController.swift
//  CoreBankingApp
//
//  Created by Yusuf Abbas on 07/06/2026.
//

import Foundation
import UIKit

// MARK: - Onboarding Data Model
struct OnboardingPage {
    let imageName: String    // SF Symbol name
    let title: String
    let subtitle: String
}

// MARK: - Onboarding View Controller
// Shows 3 slides matching your AllPay design
// Blue background, illustration, title, subtitle, Next button

class OnboardingViewController: UIViewController {

    // MARK: - Data
    private let pages: [OnboardingPage] = [
        OnboardingPage(
            imageName:  "creditcard.fill",
            title:      "The best app for finance, banking & e-wallet today",
            subtitle:   "We bring financial services closer to you"
        ),
        OnboardingPage(
            imageName:  "lock.shield.fill",
            title:      "Manage finances easily with secure payments",
            subtitle:   "Your money is protected with bank-level security"
        ),
        OnboardingPage(
            imageName:  "star.fill",
            title:      "Have an amazing experience with CoreBank!",
            subtitle:   "Fast, simple and reliable banking at your fingertips"
        ),
    ]

    private var currentIndex = 0

    // MARK: - UI
    private let gradientLayer = CAGradientLayer()

    private let illustrationView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFit
        iv.tintColor = .white
        return iv
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = .systemFont(ofSize: 26, weight: .bold)
        l.textColor = .white
        l.textAlignment = .center
        l.numberOfLines = 3
        return l
    }()

    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = .systemFont(ofSize: 15, weight: .regular)
        l.textColor = UIColor.white.withAlphaComponent(0.75)
        l.textAlignment = .center
        l.numberOfLines = 2
        return l
    }()

    // Page dots
    private let pageStackView: UIStackView = {
        let sv = UIStackView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.axis = .horizontal
        sv.spacing = 8
        sv.alignment = .center
        return sv
    }()

    private var dotViews: [UIView] = []

    private let nextButton = CBButton(title: "Next")

    private let skipButton: UIButton = {
        let b = UIButton(type: .system)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.setTitle("Skip", for: .normal)
        b.setTitleColor(UIColor.white.withAlphaComponent(0.7), for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 15)
        return b
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupGradient()
        setupUI()
        setupDots()
        updatePage(animated: false)
        setupActions()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer.frame = view.bounds
    }

    // MARK: - Gradient
    private func setupGradient() {
        gradientLayer.colors = [
            UIColor(red: 0.14, green: 0.22, blue: 0.98, alpha: 1).cgColor,
            UIColor(red: 0.18, green: 0.38, blue: 0.98, alpha: 1).cgColor,
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint   = CGPoint(x: 1, y: 1)
        view.layer.insertSublayer(gradientLayer, at: 0)
    }

    // MARK: - Setup UI
    private func setupUI() {
        [illustrationView, titleLabel, subtitleLabel,
         pageStackView, nextButton, skipButton].forEach { view.addSubview($0) }

        NSLayoutConstraint.activate([
            // Illustration — top half of screen
            illustrationView.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60),
            illustrationView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            illustrationView.widthAnchor.constraint(equalToConstant: 200),
            illustrationView.heightAnchor.constraint(equalToConstant: 200),

            // Title
            titleLabel.topAnchor.constraint(
                equalTo: illustrationView.bottomAnchor, constant: 40),
            titleLabel.leadingAnchor.constraint(
                equalTo: view.leadingAnchor, constant: 32),
            titleLabel.trailingAnchor.constraint(
                equalTo: view.trailingAnchor, constant: -32),

            // Subtitle
            subtitleLabel.topAnchor.constraint(
                equalTo: titleLabel.bottomAnchor, constant: 16),
            subtitleLabel.leadingAnchor.constraint(
                equalTo: view.leadingAnchor, constant: 32),
            subtitleLabel.trailingAnchor.constraint(
                equalTo: view.trailingAnchor, constant: -32),

            // Page dots
            pageStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            pageStackView.bottomAnchor.constraint(
                equalTo: nextButton.topAnchor, constant: -24),

            // Next button
            nextButton.leadingAnchor.constraint(
                equalTo: view.leadingAnchor, constant: Constants.UI.padding),
            nextButton.trailingAnchor.constraint(
                equalTo: view.trailingAnchor, constant: -Constants.UI.padding),
            nextButton.bottomAnchor.constraint(
                equalTo: skipButton.topAnchor, constant: -12),
            nextButton.heightAnchor.constraint(
                equalToConstant: Constants.UI.buttonHeight),

            // Skip button
            skipButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            skipButton.bottomAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
        ])
    }

    // MARK: - Page Dots
    private func setupDots() {
        for i in 0..<pages.count {
            let dot = UIView()
            dot.translatesAutoresizingMaskIntoConstraints = false
            dot.layer.cornerRadius = 4
            dot.backgroundColor = i == 0
                ? .white
                : UIColor.white.withAlphaComponent(0.35)

            let widthConstraint = dot.widthAnchor.constraint(
                equalToConstant: i == 0 ? 24 : 8)
            widthConstraint.isActive = true
            dot.heightAnchor.constraint(equalToConstant: 8).isActive = true

            pageStackView.addArrangedSubview(dot)
            dotViews.append(dot)
        }
    }

    private func updateDots() {
        for (i, dot) in dotViews.enumerated() {
            UIView.animate(withDuration: 0.3) {
                if i == self.currentIndex {
                    dot.backgroundColor = .white
                    dot.constraints.first?.constant = 24
                } else {
                    dot.backgroundColor = UIColor.white.withAlphaComponent(0.35)
                    dot.constraints.first?.constant = 8
                }
            }
        }
    }

    // MARK: - Update Content
    private func updatePage(animated: Bool) {
        let page = pages[currentIndex]

        let isLast = currentIndex == pages.count - 1
        nextButton.setTitle(isLast ? "Get Started" : "Next", for: .normal)
        skipButton.isHidden = isLast

        if animated {
            UIView.transition(with: view, duration: 0.3,
                              options: .transitionCrossDissolve) {
                self.illustrationView.image = UIImage(systemName: page.imageName)
                self.titleLabel.text    = page.title
                self.subtitleLabel.text = page.subtitle
            }
        } else {
            illustrationView.image = UIImage(systemName: page.imageName)
            titleLabel.text    = page.title
            subtitleLabel.text = page.subtitle
        }

        updateDots()
    }

    // MARK: - Actions
    private func setupActions() {
        nextButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
        skipButton.addTarget(self, action: #selector(skipTapped), for: .touchUpInside)
    }

    @objc private func nextTapped() {
        if currentIndex < pages.count - 1 {
            currentIndex += 1
            updatePage(animated: true)
        } else {
            // Last page — go to register
            finishOnboarding()
        }
    }

    @objc private func skipTapped() {
        finishOnboarding()
    }

    private func finishOnboarding() {
        // Mark that user has seen onboarding on this device
        DeviceStorage.shared.hasSeenOnboarding = true
        // Go to register screen
        let vc = RegisterViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
}
