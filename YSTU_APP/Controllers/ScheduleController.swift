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
    private var panInProgress = false
    private var panTriggered = false
    private var panCommitted = false
    private var incomingReady = false
    private var dateBeforePan = Date()
    
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

            if self.panCommitted || (self.panInProgress && self.panTriggered) {
                self.incomingReady = true
                if self.panCommitted {
                    let width = max(self.view.bounds.width, 1)
                    self.scheduleFeedTable.transform = CGAffineTransform(translationX: width * self.pendingDirection, y: 0)
                    self.animateTableToIdentity()
                }
            } else {
                self.playTransition()
            }
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

        let pan = UIPanGestureRecognizer(target: self, action: #selector(dayPanned(_:)))
        pan.delegate = self
        scheduleFeedTable.addGestureRecognizer(pan)
        scheduleFeedTable.panGestureRecognizer.require(toFail: pan)
    }

    @objc private func dayPanned(_ gesture: UIPanGestureRecognizer) {
        let tx = gesture.translation(in: view).x
        let width = max(view.bounds.width, 1)

        switch gesture.state {
        case .began:
            captureSnapshot()
            scheduleFeedTable.alpha = 0
            panInProgress = true
            panTriggered = false
            panCommitted = false
            incomingReady = false
            dateBeforePan = currentDate

        case .changed:
            guard panInProgress, let snapshot = pendingSnapshot else { return }
            pendingDirection = tx < 0 ? 1 : -1
            snapshot.transform = CGAffineTransform(translationX: tx, y: 0)

            if !panTriggered, abs(tx) > width * 0.2 {
                panTriggered = true
                advanceDay(by: pendingDirection)
            }

            if incomingReady {
                scheduleFeedTable.alpha = 1
                scheduleFeedTable.transform = CGAffineTransform(translationX: tx + pendingDirection * width, y: 0)
            }

        case .ended, .cancelled:
            guard panInProgress else { return }
            panInProgress = false
            let velocity = abs(gesture.velocity(in: view).x)
            let commit = panTriggered && (abs(tx) > width * 0.25 || velocity > 350)

            if commit {
                panCommitted = true
                commitInteractive()
            } else {
                cancelInteractive()
            }

        default:
            break
        }
    }

    private func advanceDay(by direction: CGFloat) {
        var components = DateComponents()
        components.day = Int(direction)
        guard let next = Calendar.current.date(byAdding: components, to: currentDate) else { return }
        navBar.selectDate(next)
    }

    private func commitInteractive() {
        let width = max(view.bounds.width, 1)
        if let snapshot = pendingSnapshot {
            UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut, animations: {
                snapshot.transform = CGAffineTransform(translationX: -width * self.pendingDirection, y: 0)
                snapshot.alpha = 0.4
            }, completion: { _ in
                snapshot.removeFromSuperview()
            })
        }
        if incomingReady {
            animateTableToIdentity()
        }
    }

    private func cancelInteractive() {
        panCommitted = false
        if panTriggered {
            navBar.selectDate(dateBeforePan)
        }
        scheduleFeedTable.transform = .identity
        scheduleFeedTable.alpha = 1
        if let snapshot = pendingSnapshot {
            pendingSnapshot = nil
            UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseOut, animations: {
                snapshot.transform = .identity
            }, completion: { _ in
                snapshot.removeFromSuperview()
            })
        }
    }

    private func animateTableToIdentity() {
        scheduleFeedTable.alpha = 1
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.85, initialSpringVelocity: 0.3, options: .curveEaseOut, animations: {
            self.scheduleFeedTable.transform = .identity
        }, completion: nil)
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


extension ScheduleController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let pan = gestureRecognizer as? UIPanGestureRecognizer else { return true }
        let t = pan.translation(in: view)
        return abs(t.x) > abs(t.y)
    }
}

extension ScheduleController: ScheduleNavBarDelegate {
    func didSelectDay(_ date: Date) {
        if date != currentDate, !panInProgress, !panCommitted {
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

