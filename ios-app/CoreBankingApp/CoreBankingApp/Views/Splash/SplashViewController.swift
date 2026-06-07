//
//  SplashViewController.swift
//  CoreBankingApp
//
//  Created by Yusuf Abbas on 07/06/2026.
//

import UIKit

class SplashViewController: UIViewController {

    // MARK: - UI
    private let logoImageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFit
        let config = UIImage.SymbolConfiguration(pointSize: 50, weight: .bold)
        iv.image = UIImage(systemName: "building.columns.fill",
                           withConfiguration: config)
        iv.tintColor = .white
        return iv
    }()

    private let bankNameLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.text = "CoreBank"
        l.font = .systemFont(ofSize: 32, weight: .bold)
        l.textColor = .white
        l.textAlignment = .center
        return l
    }()

    private let taglineLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.text = "Banking made simple"
        l.font = .systemFont(ofSize: 16, weight: .regular)
        l.textColor = UIColor.white.withAlphaComponent(0.8)
        l.textAlignment = .center
        return l
    }()

    private let loadingIndicator: UIActivityIndicatorView = {
        let i = UIActivityIndicatorView(style: .medium)
        i.translatesAutoresizingMaskIntoConstraints = false
        i.color = UIColor.white.withAlphaComponent(0.7)
        i.hidesWhenStopped = true
        return i
    }()

    private let gradientLayer = CAGradientLayer()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupGradient()
        setupUI()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer.frame = view.bounds
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        loadingIndicator.startAnimating()

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.loadingIndicator.stopAnimating()
            self.navigate()
        }
    }

    // MARK: - Setup
    private func setupGradient() {
        gradientLayer.colors = [
            UIColor.primaryDark.cgColor,
            UIColor.primaryBlue.cgColor,
            UIColor.primaryLight.cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint   = CGPoint(x: 1, y: 1)
        view.layer.insertSublayer(gradientLayer, at: 0)
    }

    private func setupUI() {
        [logoImageView, bankNameLabel, taglineLabel, loadingIndicator]
            .forEach { view.addSubview($0) }

        NSLayoutConstraint.activate([
            // Logo — centered slightly above middle
            logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoImageView.centerYAnchor.constraint(
                equalTo: view.centerYAnchor, constant: -60),
            logoImageView.widthAnchor.constraint(equalToConstant: 80),
            logoImageView.heightAnchor.constraint(equalToConstant: 80),

            // Bank name below logo
            bankNameLabel.topAnchor.constraint(
                equalTo: logoImageView.bottomAnchor, constant: 16),
            bankNameLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            // Tagline below name
            taglineLabel.topAnchor.constraint(
                equalTo: bankNameLabel.bottomAnchor, constant: 8),
            taglineLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            // Loading spinner at bottom
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.bottomAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40),
        ])
    }

    // MARK: - Navigation Logic
    // First time on device → Onboarding → Register
    // Returning user       → Login
    // Already logged in    → Dashboard
    private func navigate() {
        if DeviceStorage.shared.isLoggedIn {
            goToDashboard()
        } else if DeviceStorage.shared.hasSeenOnboarding {
            goToLogin()
        } else {
            goToOnboarding()
        }
    }

    private func goToOnboarding() {
        let vc = OnboardingViewController()
        navigationController?.pushViewController(vc, animated: true)
    }

    private func goToLogin() {
        let vc = LoginViewController()
        navigationController?.pushViewController(vc, animated: true)
    }

    private func goToDashboard() {
        let vc = MainTabBarController()
        navigationController?.setViewControllers([vc], animated: true)
    }
}
    
