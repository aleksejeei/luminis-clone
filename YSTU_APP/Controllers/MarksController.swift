//
//  MarksController.swift
//  YSTU_APP
//
//  Created by Alex Neumark on 10.09.2024.
//

import UIKit

final class MarksController: BaseController {

    private var marks: [Mark] = []
    private var semesters: [Int] = []
    private var selectedSemester: Int?

    private lazy var pager: UIPageViewController = {
        let pager = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)
        pager.dataSource = self
        pager.delegate = self
        return pager
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .Montserrat.Bold.size(of: 28)
        label.textColor = AccentColors.ordinaryTextColor
        label.text = "Marks"
        return label
    }()

    private let averageLabel: UILabel = {
        let label = UILabel()
        label.font = .Montserrat.Medium.size(of: 14)
        label.textColor = AccentColors.normalColor
        return label
    }()

    private let semesterScroll: UIScrollView = {
        let scroll = UIScrollView()
        scroll.showsHorizontalScrollIndicator = false
        return scroll
    }()

    private let semesterStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        return stack
    }()

    private let messageLabel: UILabel = {
        let label = UILabel()
        label.font = .Montserrat.Medium.size(of: 15)
        label.textColor = AccentColors.normalColor
        label.textAlignment = .center
        label.numberOfLines = 0
        label.isHidden = true
        return label
    }()

    private let loginButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Sign in", for: .normal)
        button.titleLabel?.font = .Montserrat.SemiBold.size(of: 15)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = AccentColors.blueColor
        button.layer.cornerRadius = 14
        button.isHidden = true
        return button
    }()

    private let activity = UIActivityIndicatorView(style: .medium)

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
        reloadState()
    }

    private func reloadState() {
        guard AccountManager.shared.isAuthorized else {
            marks = []
            applySemesters()
            showMessage("Sign in to your profile\nto see your marks", showLogin: true)
            return
        }
        fetchMarks()
    }

    private func fetchMarks() {
        showMessage(nil, showLogin: false)
        activity.startAnimating()

        AccountManager.shared.fetchMarks { [weak self] result in
            DispatchQueue.main.async {
                self?.activity.stopAnimating()
                switch result {
                case .success(let marks):
                    self?.marks = marks
                    self?.applySemesters()
                    self?.updateAverage()
                    if marks.isEmpty {
                        self?.showMessage("No marks yet", showLogin: false)
                    }
                case .failure(let error):
                    self?.marks = []
                    self?.applySemesters()
                    if (error as? AuthError) == .notAuthorized {
                        self?.showMessage("Session expired.\nPlease sign in again", showLogin: true)
                    } else {
                        self?.showMessage("Failed to load marks", showLogin: false)
                    }
                }
            }
        }
    }

    private func applySemesters() {
        semesters = Array(Set(marks.compactMap { $0.semester })).sorted(by: >)
        if selectedSemester == nil || !semesters.contains(selectedSemester!) {
            selectedSemester = semesters.first
        }
        rebuildSemesterChips()
        showCurrentSemester(animated: false)
    }

    private func showCurrentSemester(animated: Bool, direction: UIPageViewController.NavigationDirection = .forward) {
        guard let selectedSemester else {
            pager.setViewControllers(nil, direction: direction, animated: false)
            return
        }
        pager.setViewControllers([SemesterMarksController(semester: selectedSemester, marks: marks)], direction: direction, animated: animated)
    }

    private func rebuildSemesterChips() {
        semesterStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        for semester in semesters {
            let button = UIButton(type: .system)
            button.setTitle("Semester \(semester)", for: .normal)
            button.titleLabel?.font = .Montserrat.Medium.size(of: 13)
            button.layer.cornerRadius = 16
            button.contentEdgeInsets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)
            button.tag = semester
            button.addTarget(self, action: #selector(semesterTapped(_:)), for: .touchUpInside)
            semesterStack.addArrangedSubview(button)
        }
        updateSemesterChips()
    }

    private func updateSemesterChips() {
        for case let button as UIButton in semesterStack.arrangedSubviews {
            let isSelected = button.tag == selectedSemester
            button.backgroundColor = isSelected ? AccentColors.selectedColor : AccentColors.interfaceColor
            button.setTitleColor(isSelected ? AccentColors.buttonTextColor : AccentColors.normalColor, for: .normal)
        }
    }

    @objc private func semesterTapped(_ sender: UIButton) {
        guard sender.tag != selectedSemester else { return }
        let newIndex = semesters.firstIndex(of: sender.tag) ?? 0
        let currentIndex = selectedSemester.flatMap { semesters.firstIndex(of: $0) } ?? 0
        selectedSemester = sender.tag
        updateSemesterChips()
        updateAverage()
        showCurrentSemester(animated: true, direction: newIndex > currentIndex ? .forward : .reverse)
    }

    private func updateAverage() {
        let values = marks.compactMap { $0.mark }.filter { $0 > 0 }
        if values.isEmpty {
            averageLabel.text = nil
        } else {
            let avg = values.reduce(0, +) / Double(values.count)
            averageLabel.text = String(format: "Average grade: %.2f", avg)
        }
    }

    private func showMessage(_ text: String?, showLogin: Bool) {
        messageLabel.text = text
        messageLabel.isHidden = text == nil
        loginButton.isHidden = !showLogin
    }

    @objc private func loginTapped() {
        tabBarController?.selectedIndex = 2
    }

    override func addViews() {
        super.addViews()
        view.addSubview(titleLabel)
        view.addSubview(averageLabel)
        view.addSubview(semesterScroll)
        semesterScroll.addSubview(semesterStack)
        addChild(pager)
        view.addSubview(pager.view)
        pager.didMove(toParent: self)
        view.addSubview(messageLabel)
        view.addSubview(loginButton)
        view.addSubview(activity)
    }

    override func layoutViews() {
        super.layoutViews()

        [titleLabel, averageLabel, semesterScroll, semesterStack, messageLabel, loginButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        activity.translatesAutoresizingMaskIntoConstraints = false
        pager.view.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),

            averageLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            averageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),

            semesterScroll.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            semesterScroll.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            semesterScroll.topAnchor.constraint(equalTo: averageLabel.bottomAnchor, constant: 12),
            semesterScroll.heightAnchor.constraint(equalToConstant: 32),

            semesterStack.leadingAnchor.constraint(equalTo: semesterScroll.leadingAnchor),
            semesterStack.trailingAnchor.constraint(equalTo: semesterScroll.trailingAnchor),
            semesterStack.topAnchor.constraint(equalTo: semesterScroll.topAnchor),
            semesterStack.bottomAnchor.constraint(equalTo: semesterScroll.bottomAnchor),
            semesterStack.heightAnchor.constraint(equalTo: semesterScroll.heightAnchor),

            pager.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pager.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pager.view.topAnchor.constraint(equalTo: semesterScroll.bottomAnchor, constant: 8),
            pager.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            messageLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            messageLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            messageLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            messageLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),

            loginButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loginButton.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 16),
            loginButton.widthAnchor.constraint(equalToConstant: 180),
            loginButton.heightAnchor.constraint(equalToConstant: 44),

            activity.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activity.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    override func configure() {
        super.configure()
        loginButton.addTarget(self, action: #selector(loginTapped), for: .touchUpInside)
        view.backgroundColor = AccentColors.bgColor
    }
}

extension MarksController: UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let current = viewController as? SemesterMarksController,
              let index = semesters.firstIndex(of: current.semester),
              index > 0 else { return nil }
        return SemesterMarksController(semester: semesters[index - 1], marks: marks)
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let current = viewController as? SemesterMarksController,
              let index = semesters.firstIndex(of: current.semester),
              index + 1 < semesters.count else { return nil }
        return SemesterMarksController(semester: semesters[index + 1], marks: marks)
    }

    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard completed,
              let current = pageViewController.viewControllers?.first as? SemesterMarksController else { return }
        selectedSemester = current.semester
        updateSemesterChips()
        updateAverage()
    }
}

private final class SemesterMarksController: UIViewController {

    let semester: Int
    private let allMarks: [Mark]

    private let table: UITableView = {
        let table = UITableView(frame: .zero, style: .plain)
        table.register(MarkCell.self, forCellReuseIdentifier: MarkCell.identifier)
        table.backgroundColor = .clear
        table.separatorStyle = .none
        table.showsVerticalScrollIndicator = false
        table.rowHeight = UITableView.automaticDimension
        table.estimatedRowHeight = 90
        return table
    }()

    init(semester: Int, marks: [Mark]) {
        self.semester = semester
        self.allMarks = marks
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AccentColors.bgColor

        view.addSubview(table)
        table.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            table.topAnchor.constraint(equalTo: view.topAnchor),
            table.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            table.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            table.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        table.delegate = self
        table.dataSource = self
    }

    private var visibleMarks: [Mark] {
        allMarks.filter { $0.semester == semester }
    }
}

extension SemesterMarksController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        visibleMarks.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: MarkCell.identifier, for: indexPath) as? MarkCell else {
            return UITableViewCell()
        }
        cell.configure(with: visibleMarks[indexPath.row])
        return cell
    }
}
