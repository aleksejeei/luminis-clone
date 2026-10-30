//
//  ScheduleController.swift
//  YSTU_APP
//
//  Created by Alex Neumark on 10.09.2024.
//

import UIKit

final class ScheduleController: BaseController {
    
    private let navBar = ScheduleNavBar()
    private var lessons: [Lesson] = []
    private var currentDate = Date()
    private var pendingSnapshot: UIView?
    private var pendingDirection: CGFloat = 0
    
    let scheduleFeedTable: UITableView = {
        let table = UITableView(frame: .zero, style: .grouped)
        table.register(ScheduleTableViewCell.self, forCellReuseIdentifier: ScheduleTableViewCell.identifier)
        table.backgroundColor = AccentColors.bgColor
        return table
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navBar.delegate = self
        setupNavBarGlass()
        getSchedule(for: Date())
//        getGruopList()
    }

    private func setupNavBarGlass() {
        let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
        blur.layer.cornerRadius = 24
        blur.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        blur.clipsToBounds = true
        navBar.insertSubview(blur, at: 0)
        navBar.backgroundColor = .clear

        blur.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            blur.topAnchor.constraint(equalTo: navBar.topAnchor),
            blur.leadingAnchor.constraint(equalTo: navBar.leadingAnchor),
            blur.trailingAnchor.constraint(equalTo: navBar.trailingAnchor),
            blur.bottomAnchor.constraint(equalTo: navBar.bottomAnchor)
        ])
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navBar.scrollToCurrentWeek()
        navBar.selectToday()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        navBar.translatesAutoresizingMaskIntoConstraints = false
        navBar.layer.cornerRadius = 24
        navBar.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        navBar.layer.shadowColor = AccentColors.shadowColor?.cgColor
        navBar.layer.shadowOpacity = 0.16
        navBar.layer.shadowRadius = 14
        navBar.layer.shadowOffset = CGSize(width: 0, height: 6)
        navBar.layer.masksToBounds = false
        
        NSLayoutConstraint.activate([
            navBar.topAnchor.constraint(equalTo: view.topAnchor),
            navBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            navBar.heightAnchor.constraint(equalToConstant: 134 + view.safeAreaInsets.top)
        ])
    }
    
    private func getSchedule(for date: Date) {
        APICaller.shared.getSchedule(for: date) { result in
            switch result {
            case .success(let lessons):
                // Обновляем UI с полученными уроками
                self.updateUI(with: lessons)
            case .failure(let error):
                print("Error: \(error)")
                self.updateUI(with: [], message: "Failed to load schedule")
            }
        }
    }

    private func updateUI(with lessons: [Lesson], message: String = "No lessons for this day") {
        print("Updating UI with \(lessons.count) lessons")
        self.lessons = lessons
        DispatchQueue.main.async {
            if lessons.isEmpty {
                // Показываем сообщение, что расписание пустое
                let label = UILabel(frame: self.scheduleFeedTable.bounds)
                label.text = message
                label.textAlignment = .center
                label.textColor = .gray
                self.scheduleFeedTable.backgroundView = label
            } else {
                self.scheduleFeedTable.backgroundView = nil
            }
            self.scheduleFeedTable.reloadData()
            self.scheduleFeedTable.layoutIfNeeded()
            self.playTransition()
        }
    }

    private func captureSnapshot() {
        pendingSnapshot?.removeFromSuperview()
        guard let snapshot = scheduleFeedTable.snapshotView(afterScreenUpdates: false) else { return }
        snapshot.frame = scheduleFeedTable.frame
        view.insertSubview(snapshot, aboveSubview: scheduleFeedTable)
        pendingSnapshot = snapshot
    }

    private func playTransition() {
        guard let snapshot = pendingSnapshot else { return }
        pendingSnapshot = nil
        let width = max(scheduleFeedTable.bounds.width, 1)

        scheduleFeedTable.transform = CGAffineTransform(translationX: width * pendingDirection, y: 0)
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: {
            snapshot.transform = CGAffineTransform(translationX: -width * self.pendingDirection, y: 0)
            snapshot.alpha = 0.4
            self.scheduleFeedTable.transform = .identity
        }, completion: { _ in
            snapshot.removeFromSuperview()
        })
    }
    
    private func getGruopList() {
        APICaller.shared.getGroupsList { results in
            switch results {
            case .success(let items):
                print(items)
            case .failure(let error):
                print(error)
            }
        }
    }
    
    private func addHeaderView() {
        let header = ScheduleHeader(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 50))
        scheduleFeedTable.tableHeaderView = header
    }
    
    override func addViews() {
        super.addViews()
        view.addSubview(scheduleFeedTable)
        view.addSubview(navBar)
    }
    
    override func layoutViews() {
        super.layoutViews()
        addHeaderView()
        scheduleFeedTable.translatesAutoresizingMaskIntoConstraints = false
        scheduleFeedTable.contentInsetAdjustmentBehavior = .never
         
        NSLayoutConstraint.activate([
            scheduleFeedTable.topAnchor.constraint(equalTo: navBar.bottomAnchor, constant: -12),
            scheduleFeedTable.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scheduleFeedTable.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scheduleFeedTable.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -48)
        ])
    }
    
    override func configure() {
        super.configure()
        scheduleFeedTable.delegate = self
        scheduleFeedTable.dataSource = self
        scheduleFeedTable.separatorStyle = .none
        scheduleFeedTable.estimatedRowHeight = 137 // Примерное значение для улучшения производительности
        scheduleFeedTable.rowHeight = UITableView.automaticDimension
        scheduleFeedTable.showsVerticalScrollIndicator = false
        scheduleFeedTable.showsHorizontalScrollIndicator = false

        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(daySwiped(_:)))
        swipeLeft.direction = .left
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(daySwiped(_:)))
        swipeRight.direction = .right
        scheduleFeedTable.addGestureRecognizer(swipeLeft)
        scheduleFeedTable.addGestureRecognizer(swipeRight)
    }

    @objc private func daySwiped(_ gesture: UISwipeGestureRecognizer) {
        var components = DateComponents()
        components.day = gesture.direction == .left ? 1 : -1
        guard let next = Calendar.current.date(byAdding: components, to: navBar.selectedDate) else { return }
        navBar.selectDate(next)
    }

    static func lessonTypeName(_ type: Int?) -> String {
        switch type {
        case 2: return "Lecture"
        case 4: return "Practice"
        case 8: return "Lab work"
        case 256: return "Exam"
        default: return "Other"
        }
    }
}

extension ScheduleController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
            return 1
        }

        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return lessons.count // Количество строк равно количеству уроков
        }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ScheduleTableViewCell.identifier, for: indexPath) as? ScheduleTableViewCell else {
            return UITableViewCell()
        }
        
        let lesson = lessons[indexPath.row] // Исправлено с indexPath.section на indexPath.row
//        print("Configuring cell with lesson: \(lesson)")
        cell.configureTimeView(start: lesson.startAt ?? "", end: lesson.endAt ?? "")
        cell.configureCourseView(name: lesson.lessonName ?? "", type: Self.lessonTypeName(lesson.type), room: lesson.auditoryName ?? "", teacher: lesson.teacherName ?? "")
        cell.setRailEnds(isFirst: indexPath.row == 0, isLast: indexPath.row == lessons.count - 1)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 16 // Создаст отступ перед секцией, тем самым увеличив расстояние между ячейками
    }
}


extension ScheduleController: ScheduleNavBarDelegate {
    func didSelectDay(_ date: Date) {
        if date != currentDate {
            pendingDirection = date > currentDate ? 1 : -1
            captureSnapshot()
        }
        currentDate = date
        self.getSchedule(for: date)
    }

    func didSelectGroup(_ group: String) {
        self.getSchedule(for: navBar.selectedDate)
    }
}

