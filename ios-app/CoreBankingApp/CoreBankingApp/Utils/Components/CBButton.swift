//
//  CBButton.swift
//  CoreBankingApp
//
//  Created by Yusuf Abbas on 07/06/2026.
//

import Foundation
import UIKit

// MARK: - The Blue Gradient Button
// Used on every screen — login, register, transfer etc

class CBButton: UIButton {

    // MARK: - Properties
    private let gradientLayer = CAGradientLayer()

    var isLoading: Bool = false {
        didSet { updateLoadingState() }
    }

    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.color = .white
        indicator.hidesWhenStopped = true
        return indicator
    }()

    // MARK: - Init
    init(title: String) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        setTitle(title, for: .normal)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Setup
    private func setupUI() {
        setTitleColor(.white, for: .normal)
        titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        layer.cornerRadius = Constants.UI.cornerRadius
        clipsToBounds = true

        // Gradient background
        gradientLayer.colors = [
            UIColor.primaryBlue.cgColor,
            UIColor.primaryLight.cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint   = CGPoint(x: 1, y: 0.5)
        layer.insertSublayer(gradientLayer, at: 0)

        // Activity indicator
        addSubview(activityIndicator)
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }

    // MARK: - Loading State
    private func updateLoadingState() {
        if isLoading {
            setTitle(nil, for: .normal)
            activityIndicator.startAnimating()
            isEnabled = false
            alpha = 0.8
        } else {
            activityIndicator.stopAnimating()
            isEnabled = true
            alpha = 1.0
        }
    }

    // MARK: - Press Animation
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        UIView.animate(withDuration: 0.1) {
            self.transform = CGAffineTransform(scaleX: 0.97, y: 0.97)
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        UIView.animate(withDuration: 0.1) {
            self.transform = .identity
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        UIView.animate(withDuration: 0.1) {
            self.transform = .identity
        }
    }
}
