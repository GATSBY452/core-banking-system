//
//  MainTabBarController.swift
//  CoreBankingApp
//
//  Created by Yusuf Abbas on 07/06/2026.
//

import UIKit

class MainTabBarController: UIViewController {

    // MARK: - UI
    private let containerView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let tabBar: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .white
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.08
        v.layer.shadowOffset = CGSize(width: 0, height: -2)
        v.layer.shadowRadius = 8
        return v
    }()

    private let tabStack: UIStackView = {
        let sv = UIStackView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.axis = .horizontal
        sv.distribution = .fillEqually
        return sv
    }()

    // MARK: - Tabs
    private let tabs: [(title: String, icon: String, vc: UIViewController)] = [
        ("Home",     "house.fill",                   HomeViewController()),
        ("Accounts", "creditcard.fill",              PlaceholderViewController(title: "Accounts")),
        ("Transfer", "arrow.left.arrow.right",       PlaceholderViewController(title: "Transfer")),
        ("History",  "clock.fill",                   PlaceholderViewController(title: "History")),
        ("Settings", "gearshape.fill",               PlaceholderViewController(title: "Settings")),
    ]

    private var selectedIndex = 0
    private var tabButtons: [UIButton] = []

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .appBackground
        setupUI()
        select(index: 0)
    }

    // MARK: - Setup
    private func setupUI() {
        view.addSubview(containerView)
        view.addSubview(tabBar)
        tabBar.addSubview(tabStack)

        NSLayoutConstraint.activate([
            // Container fills everything above tab bar
            containerView.topAnchor.constraint(equalTo: view.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: tabBar.topAnchor),

            // Tab bar at bottom
            tabBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tabBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tabBar.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tabBar.heightAnchor.constraint(equalToConstant: 83),

            // Tab stack inside tab bar
            tabStack.topAnchor.constraint(equalTo: tabBar.topAnchor),
            tabStack.leadingAnchor.constraint(equalTo: tabBar.leadingAnchor),
            tabStack.trailingAnchor.constraint(equalTo: tabBar.trailingAnchor),
            tabStack.heightAnchor.constraint(equalToConstant: 60),
        ])

        // Create tab buttons
        for (index, tab) in tabs.enumerated() {
            let button = makeTabButton(
                title: tab.title,
                icon: tab.icon,
                index: index
            )
            tabStack.addArrangedSubview(button)
            tabButtons.append(button)
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return children.first?.preferredStatusBarStyle ?? .default
    }

    private func makeTabButton(
        title: String, icon: String, index: Int
    ) -> UIButton {
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tag = index

        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: icon)
        config.title = title
        config.imagePadding = 4
        config.imagePlacement = .top
        config.preferredSymbolConfigurationForImage =
            UIImage.SymbolConfiguration(pointSize: 20)
        config.titleTextAttributesTransformer =
            UIConfigurationTextAttributesTransformer { attrs in
                var updated = attrs
                updated.font = UIFont.systemFont(ofSize: 10)
                return updated
            }
        button.configuration = config
        button.tintColor = .textSecondary
        button.addTarget(self, action: #selector(tabTapped(_:)), for: .touchUpInside)
        return button
    }

    // MARK: - Tab Selection
    @objc private func tabTapped(_ sender: UIButton) {
        select(index: sender.tag)
    }

    private func select(index: Int) {
        // Remove current child
        children.forEach {
            $0.willMove(toParent: nil)
            $0.view.removeFromSuperview()
            $0.removeFromParent()
        }

        // Update button colors
        tabButtons.enumerated().forEach { i, button in
            button.tintColor = i == index ? .primaryBlue : .textSecondary
        }

        // Add new child
        let vc = tabs[index].vc
        addChild(vc)
        vc.view.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(vc.view)

        NSLayoutConstraint.activate([
            vc.view.topAnchor.constraint(equalTo: containerView.topAnchor),
            vc.view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            vc.view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            vc.view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
        ])

        vc.didMove(toParent: self)
        selectedIndex = index
    }
}

// MARK: - Placeholder for tabs not built yet
class PlaceholderViewController: UIViewController {
    private let title_: String

    init(title: String) {
        self.title_ = title
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .appBackground
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "\(title_) — Coming Soon"
        label.textColor = .textSecondary
        label.font = .systemFont(ofSize: 16)
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }
}
