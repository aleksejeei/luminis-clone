//
//  ScheduleController.swift
//  YSTU_APP
//
//  Created by Alex Neumark on 10.09.2024.
//

import UIKit

final class ScheduleController: BaseController {
    
    private let navBar = ScheduleNavBar()
    private var currentDate = ScheduleNavBar.scheduleStartDate()
    
    private lazy var pager: UIPageViewController = {
        let pager = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)
        pager.dataSource = self
        pager.delegate = self
        return pager
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navBar.delegate = self
        setupNavBarGlass()
        pager.setViewControllers([DayScheduleController(date: currentDate)], direction: .forward, animated: false)
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
        navBar.selectDate(currentDate)
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
    
    override func addViews() {
        super.addViews()
        addChild(pager)
        view.addSubview(pager.view)
        pager.didMove(toParent: self)
        view.addSubview(navBar)
    }
    
    override func layoutViews() {
        super.layoutViews()
        pager.view.translatesAutoresizingMaskIntoConstraints = false
         
        NSLayoutConstraint.activate([
            pager.view.topAnchor.constraint(equalTo: navBar.bottomAnchor, constant: -12),
            pager.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pager.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pager.view.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -48)
        ])
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

extension ScheduleController: UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let day = viewController as? DayScheduleController,
              let previous = Calendar.current.date(byAdding: .day, value: -1, to: day.date) else { return nil }
        return DayScheduleController(date: previous)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let day = viewController as? DayScheduleController,
              let next = Calendar.current.date(byAdding: .day, value: 1, to: day.date) else { return nil }
        return DayScheduleController(date: next)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard completed,
              let day = pageViewController.viewControllers?.first as? DayScheduleController else { return }
        currentDate = day.date
        navBar.selectDate(day.date)
    }
}

extension ScheduleController: ScheduleNavBarDelegate {
    func didSelectDay(_ date: Date) {
        guard !Calendar.current.isDate(date, inSameDayAs: currentDate) else { return }
        let direction: UIPageViewController.NavigationDirection = date > currentDate ? .forward : .reverse
        currentDate = date
        pager.setViewControllers([DayScheduleController(date: date)], direction: direction, animated: true)
    }
    
    func didSelectGroup(_ group: String) {
        pager.setViewControllers([DayScheduleController(date: currentDate)], direction: .forward, animated: false)
    }
}

private final class DayScheduleController: UIViewController {
    let date: Date
    private var lessons: [Lesson] = []
    private var headerInstalled = false
    
    private let table: UITableView = {
        let table = UITableView(frame: .zero, style: .grouped)
        table.register(ScheduleTableViewCell.self, forCellReuseIdentifier: ScheduleTableViewCell.identifier)
        table.backgroundColor = AccentColors.bgColor
        table.separatorStyle = .none
        table.estimatedRowHeight = 137
        table.rowHeight = UITableView.automaticDimension
        table.showsVerticalScrollIndicator = false
        table.showsHorizontalScrollIndicator = false
        table.contentInsetAdjustmentBehavior = .never
        return table
    }()
    
    init(date: Date) {
        self.date = date
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
        
        loadLessons()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !headerInstalled, view.bounds.width > 0 {
            headerInstalled = true
            table.tableHeaderView = ScheduleHeader(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 50))
        }
    }
    
    private func loadLessons() {
        APICaller.shared.getSchedule(for: date) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                var emptyMessage = "No lessons for this day"
                switch result {
                case .success(let lessons):
                    self.lessons = lessons
                case .failure(let error):
                    print("Error: \(error)")
                    self.lessons = []
                    emptyMessage = "Failed to load schedule"
                }
                if self.lessons.isEmpty {
                    let label = UILabel(frame: self.table.bounds)
                    label.text = emptyMessage
                    label.textAlignment = .center
                    label.textColor = .gray
                    self.table.backgroundView = label
                } else {
                    self.table.backgroundView = nil
                }
                self.table.reloadData()
            }
        }
    }
}

extension DayScheduleController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return lessons.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ScheduleTableViewCell.identifier, for: indexPath) as? ScheduleTableViewCell else {
            return UITableViewCell()
        }
        
        let lesson = lessons[indexPath.row]
        cell.configureTimeView(start: lesson.startAt ?? "", end: lesson.endAt ?? "")
        cell.configureCourseView(name: lesson.lessonName ?? "", type: ScheduleController.lessonTypeName(lesson.type), room: lesson.auditoryName ?? "", teacher: lesson.teacherName ?? "")
        cell.setRailEnds(isFirst: indexPath.row == 0, isLast: indexPath.row == lessons.count - 1)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 16
    }
}
