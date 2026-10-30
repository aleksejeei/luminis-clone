//
//  ProfileController.swift
//  YSTU_APP
//
//  Created by Alex Neumark on 10.09.2024.
//

import UIKit

final class ProfileController: BaseController {

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    // MARK: - Login state

    private let loginCard: UIView = {
        let view = UIView()
        view.backgroundColor = AccentColors.interfaceColor
        view.layer.cornerRadius = 16
        return view
    }()

    private let loginTitleLabel: UILabel = {
        let label = UILabel()
        label.font = .Montserrat.Bold.size(of: 20)
        label.textColor = AccentColors.ordinaryTextColor
        label.text = "Вход в аккаунт"
        label.textAlignment = .center
        return label
    }()

    private let loginSubtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .Montserrat.Medium.size(of: 13)
        label.textColor = AccentColors.normalColor
        label.text = "Данные от личного кабинета ЯГТУ"
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private lazy var loginField: UITextField = {
        let field = makeField(placeholder: "Логин", secure: false)
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .next
        return field
    }()

    private lazy var passwordField: UITextField = {
        let field = makeField(placeholder: "Пароль", secure: true)
        field.returnKeyType = .go
        return field
    }()

    private func makeField(placeholder: String, secure: Bool) -> UITextField {
        let field = UITextField()
        field.placeholder = placeholder
        field.isSecureTextEntry = secure
        field.font = .Montserrat.Regular.size(of: 15)
        field.textColor = AccentColors.ordinaryTextColor
        field.backgroundColor = AccentColors.bgColor
        field.layer.cornerRadius = 12
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 14, height: 1))
        field.leftViewMode = .always
        field.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 14, height: 1))
        field.rightViewMode = .always
        field.delegate = self
        return field
    }

    private let signInButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Войти", for: .normal)
        button.titleLabel?.font = .Montserrat.SemiBold.size(of: 16)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = AccentColors.blueColor
        button.layer.cornerRadius = 14
        return button
    }()

    private let errorLabel: UILabel = {
        let label = UILabel()
        label.font = .Montserrat.Medium.size(of: 13)
        label.textColor = .systemRed
        label.textAlignment = .center
        label.numberOfLines = 0
        label.isHidden = true
        return label
    }()

    // MARK: - Profile state

    private let profileCard: UIView = {
        let view = UIView()
        view.backgroundColor = AccentColors.interfaceColor
        view.layer.cornerRadius = 16
        return view
    }()

    private let avatarView: UIImageView = {
        let view = UIImageView()
        view.layer.cornerRadius = 36
        view.clipsToBounds = true
        view.contentMode = .scaleAspectFill
        view.backgroundColor = AccentColors.selectedColor
        return view
    }()

    private let initialsLabel: UILabel = {
        let label = UILabel()
        label.font = .Montserrat.Bold.size(of: 24)
        label.textColor = AccentColors.buttonTextColor
        label.textAlignment = .center
        return label
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .Montserrat.Bold.size(of: 18)
        label.textColor = AccentColors.ordinaryTextColor
        label.numberOfLines = 0
        return label
    }()

    private let groupLabel: UILabel = {
        let label = UILabel()
        label.font = .Montserrat.Medium.size(of: 13)
        label.textColor = AccentColors.normalColor
        label.numberOfLines = 0
        return label
    }()

    private let infoCard: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 0
        stack.backgroundColor = AccentColors.interfaceColor
        stack.layer.cornerRadius = 16
        stack.clipsToBounds = true
        return stack
    }()

    private let logoutButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Выйти", for: .normal)
        button.titleLabel?.font = .Montserrat.SemiBold.size(of: 15)
        button.setTitleColor(.systemRed, for: .normal)
        button.backgroundColor = AccentColors.interfaceColor
        button.layer.cornerRadius = 14
        return button
    }()

    private let activity = UIActivityIndicatorView(style: .medium)

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Profile"
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        renderState()
    }

    private func renderState() {
        let authorized = AccountManager.shared.isAuthorized
        loginCard.isHidden = authorized
        profileCard.isHidden = !authorized
        infoCard.isHidden = !authorized
        logoutButton.isHidden = !authorized
        errorLabel.isHidden = true

        if authorized {
            loadProfile()
        }
    }

    // MARK: - Actions

    @objc private func signInTapped() {
        guard let login = loginField.text, !login.isEmpty,
              let password = passwordField.text, !password.isEmpty else {
            showError("Введите логин и пароль")
            return
        }

        errorLabel.isHidden = true
        signInButton.isEnabled = false
        signInButton.alpha = 0.6
        activity.startAnimating()

        AccountManager.shared.signIn(login: login, password: password) { [weak self] result in
            DispatchQueue.main.async {
                self?.activity.stopAnimating()
                self?.signInButton.isEnabled = true
                self?.signInButton.alpha = 1

                switch result {
                case .success:
                    self?.passwordField.text = nil
                    self?.renderState()
                case .failure(let error):
                    if (error as? AuthError) == .invalidCredentials {
                        self?.showError("Неверный логин или пароль")
                    } else {
                        self?.showError("Ошибка сети. Попробуйте позже")
                    }
                }
            }
        }
    }

    @objc private func logoutTapped() {
        activity.startAnimating()
        AccountManager.shared.signOut { [weak self] in
            DispatchQueue.main.async {
                self?.activity.stopAnimating()
                self?.renderState()
            }
        }
    }

    private func showError(_ text: String) {
        errorLabel.text = text
        errorLabel.isHidden = false
    }

    // MARK: - Data

    private func loadProfile() {
        activity.startAnimating()

        AccountManager.shared.fetchAuthUser { [weak self] result in
            DispatchQueue.main.async {
                self?.activity.stopAnimating()
                guard let self = self, case .success(let info) = result,
                      info.auth == 1, let user = info.user else { return }
                self.fillProfile(with: user)
            }
        }

        AccountManager.shared.fetchStudentDetails { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self, case .success(let details) = result else { return }
                self.fillDetails(details)
            }
        }
    }

    private func fillProfile(with user: CheckAuthResponse.User) {
        let first = user.firstName ?? ""
        let last = user.lastName ?? ""
        nameLabel.text = user.fullName ?? "\(first) \(last)".trimmingCharacters(in: .whitespaces)
        initialsLabel.text = user.initials ?? "\(first.prefix(1))\(last.prefix(1))"

        groupLabel.text = user.groupName
        if let group = user.groupName, !group.isEmpty {
            APICaller.shared.selectedGroup = group
        }

        if let urlString = user.photoUrl, let url = URL(string: urlString) {
            URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
                guard let data = data, let image = UIImage(data: data) else { return }
                DispatchQueue.main.async {
                    self?.avatarView.image = image
                    self?.initialsLabel.isHidden = true
                }
            }.resume()
        }
    }

    private func fillDetails(_ details: StudentDetails) {
        infoCard.arrangedSubviews.forEach { $0.removeFromSuperview() }

        var rows: [(String, String)] = []
        if let course = details.course { rows.append(("Курс", "\(course)")) }
        if let financing = details.sourceFinancingStr, !financing.isEmpty {
            rows.append(("Финансирование", financing))
        }
        if let book = details.recordBook, !book.isEmpty {
            rows.append(("Зачётная книжка", book))
        }
        if let email = details.man?.email, !email.isEmpty {
            rows.append(("Email", email))
        }
        if let phone = details.man?.telephone, !phone.isEmpty {
            rows.append(("Телефон", phone))
        }

        for (index, row) in rows.enumerated() {
            let rowView = makeInfoRow(title: row.0, value: row.1, isLast: index == rows.count - 1)
            infoCard.addArrangedSubview(rowView)
        }

        if let course = details.course, let financing = details.sourceFinancingStr {
            let group = groupLabel.text ?? ""
            groupLabel.text = group.isEmpty
                ? "\(course) курс • \(financing)"
                : "\(group) • \(course) курс • \(financing)"
        }
    }

    private func makeInfoRow(title: String, value: String, isLast: Bool) -> UIView {
        let container = UIView()

        let titleLabel = UILabel()
        titleLabel.font = .Montserrat.Medium.size(of: 13)
        titleLabel.textColor = AccentColors.normalColor
        titleLabel.text = title

        let valueLabel = UILabel()
        valueLabel.font = .Montserrat.Regular.size(of: 14)
        valueLabel.textColor = AccentColors.ordinaryTextColor
        valueLabel.text = value
        valueLabel.textAlignment = .right
        valueLabel.numberOfLines = 0

        container.addSubview(titleLabel)
        container.addSubview(valueLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        valueLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            titleLabel.widthAnchor.constraint(equalToConstant: 130),

            valueLabel.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 8),
            valueLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            valueLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
            valueLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -12)
        ])

        if !isLast {
            let separator = UIView()
            separator.backgroundColor = AccentColors.normalColor.withAlphaComponent(0.2)
            container.addSubview(separator)
            separator.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                separator.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
                separator.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                separator.bottomAnchor.constraint(equalTo: container.bottomAnchor),
                separator.heightAnchor.constraint(equalToConstant: 1)
            ])
        }

        return container
    }

    // MARK: - Layout

    override func addViews() {
        super.addViews()
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        contentView.addSubview(loginCard)
        loginCard.addSubview(loginTitleLabel)
        loginCard.addSubview(loginSubtitleLabel)
        loginCard.addSubview(loginField)
        loginCard.addSubview(passwordField)
        loginCard.addSubview(signInButton)
        loginCard.addSubview(errorLabel)

        contentView.addSubview(profileCard)
        profileCard.addSubview(avatarView)
        avatarView.addSubview(initialsLabel)
        profileCard.addSubview(nameLabel)
        profileCard.addSubview(groupLabel)

        contentView.addSubview(infoCard)
        contentView.addSubview(logoutButton)
        view.addSubview(activity)
    }

    override func layoutViews() {
        super.layoutViews()

        [scrollView, contentView, loginCard, loginTitleLabel, loginSubtitleLabel,
         loginField, passwordField, signInButton, errorLabel,
         profileCard, avatarView, initialsLabel, nameLabel, groupLabel,
         infoCard, logoutButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        activity.translatesAutoresizingMaskIntoConstraints = false

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

            // Login card
            loginCard.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 40),
            loginCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            loginCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            loginTitleLabel.topAnchor.constraint(equalTo: loginCard.topAnchor, constant: 24),
            loginTitleLabel.leadingAnchor.constraint(equalTo: loginCard.leadingAnchor, constant: 20),
            loginTitleLabel.trailingAnchor.constraint(equalTo: loginCard.trailingAnchor, constant: -20),

            loginSubtitleLabel.topAnchor.constraint(equalTo: loginTitleLabel.bottomAnchor, constant: 6),
            loginSubtitleLabel.leadingAnchor.constraint(equalTo: loginTitleLabel.leadingAnchor),
            loginSubtitleLabel.trailingAnchor.constraint(equalTo: loginTitleLabel.trailingAnchor),

            loginField.topAnchor.constraint(equalTo: loginSubtitleLabel.bottomAnchor, constant: 20),
            loginField.leadingAnchor.constraint(equalTo: loginCard.leadingAnchor, constant: 20),
            loginField.trailingAnchor.constraint(equalTo: loginCard.trailingAnchor, constant: -20),
            loginField.heightAnchor.constraint(equalToConstant: 48),

            passwordField.topAnchor.constraint(equalTo: loginField.bottomAnchor, constant: 12),
            passwordField.leadingAnchor.constraint(equalTo: loginField.leadingAnchor),
            passwordField.trailingAnchor.constraint(equalTo: loginField.trailingAnchor),
            passwordField.heightAnchor.constraint(equalToConstant: 48),

            signInButton.topAnchor.constraint(equalTo: passwordField.bottomAnchor, constant: 20),
            signInButton.leadingAnchor.constraint(equalTo: loginField.leadingAnchor),
            signInButton.trailingAnchor.constraint(equalTo: loginField.trailingAnchor),
            signInButton.heightAnchor.constraint(equalToConstant: 48),

            errorLabel.topAnchor.constraint(equalTo: signInButton.bottomAnchor, constant: 12),
            errorLabel.leadingAnchor.constraint(equalTo: loginField.leadingAnchor),
            errorLabel.trailingAnchor.constraint(equalTo: loginField.trailingAnchor),
            errorLabel.bottomAnchor.constraint(equalTo: loginCard.bottomAnchor, constant: -20),

            // Profile card
            profileCard.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            profileCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            profileCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            avatarView.leadingAnchor.constraint(equalTo: profileCard.leadingAnchor, constant: 20),
            avatarView.centerYAnchor.constraint(equalTo: profileCard.centerYAnchor),
            avatarView.widthAnchor.constraint(equalToConstant: 72),
            avatarView.heightAnchor.constraint(equalToConstant: 72),

            initialsLabel.centerXAnchor.constraint(equalTo: avatarView.centerXAnchor),
            initialsLabel.centerYAnchor.constraint(equalTo: avatarView.centerYAnchor),

            nameLabel.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(equalTo: profileCard.trailingAnchor, constant: -16),
            nameLabel.topAnchor.constraint(equalTo: profileCard.topAnchor, constant: 24),

            groupLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            groupLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            groupLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            groupLabel.bottomAnchor.constraint(equalTo: profileCard.bottomAnchor, constant: -24),

            infoCard.topAnchor.constraint(equalTo: profileCard.bottomAnchor, constant: 16),
            infoCard.leadingAnchor.constraint(equalTo: profileCard.leadingAnchor),
            infoCard.trailingAnchor.constraint(equalTo: profileCard.trailingAnchor),

            logoutButton.topAnchor.constraint(equalTo: infoCard.bottomAnchor, constant: 16),
            logoutButton.leadingAnchor.constraint(equalTo: profileCard.leadingAnchor),
            logoutButton.trailingAnchor.constraint(equalTo: profileCard.trailingAnchor),
            logoutButton.heightAnchor.constraint(equalToConstant: 48),
            logoutButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24),

            activity.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activity.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    override func configure() {
        super.configure()
        navigationController?.navigationBar.titleTextAttributes = [
            NSAttributedString.Key.font: UIFont.Montserrat.SemiBold.size(of: 17)
        ]
        signInButton.addTarget(self, action: #selector(signInTapped), for: .touchUpInside)
        logoutButton.addTarget(self, action: #selector(logoutTapped), for: .touchUpInside)
        setShadow(loginCard)
        setShadow(profileCard)
        setShadow(infoCard)
        setShadow(logoutButton)
    }
}

extension ProfileController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField === loginField {
            passwordField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
            signInTapped()
        }
        return true
    }
}
