//
//  ScheduleTableViewCell.swift
//  YSTU_APP
//
//  Created by Alex Neumark on 12.12.2024.
//

import UIKit

class ScheduleTableViewCell: UITableViewCell {
    
    static let identifier = "ScheduleTableViewCell"
    
    private let cellView: UIView = {
        let view = UIView()
        view.backgroundColor = AccentColors.bgColor
        return view
    }()

    private let railView: UIView = {
        let view = UIView()
        view.backgroundColor = AccentColors.normalColor.withAlphaComponent(0.2)
        return view
    }()

    private let topDot: UIView = {
        let view = UIView()
        view.backgroundColor = AccentColors.normalColor
        view.layer.cornerRadius = 3
        view.isHidden = true
        return view
    }()

    private let bottomDot: UIView = {
        let view = UIView()
        view.backgroundColor = AccentColors.normalColor
        view.layer.cornerRadius = 3
        view.isHidden = true
        return view
    }()

    private var timeView = TimeView()
    private var courseView = CourseView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.backgroundColor = .clear
        configureCellView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        cellView.frame = contentView.bounds
    }
    
    func configureTimeView(start: String?, end: String?) {
        timeView.updateView(start: Self.formatTime(start), end: Self.formatTime(end))
    }

    private static func formatTime(_ iso: String?) -> String? {
        guard let iso = iso, !iso.isEmpty else { return nil }
        let parser = ISO8601DateFormatter()
        parser.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = parser.date(from: iso) else { return iso }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    func configureCourseView(name: String?, type: String?, room: String?, teacher: String?) {
        courseView.updateView(name: name, type: type, room: room, teacher: teacher)
    }

    func setRailEnds(isFirst: Bool, isLast: Bool) {
        topDot.isHidden = !isFirst
        bottomDot.isHidden = !isLast
    }
}

private extension ScheduleTableViewCell {
    func configureCellView() {
        contentView.addSubview(cellView)
        cellView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            cellView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            cellView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            cellView.topAnchor.constraint(equalTo: contentView.topAnchor),
            cellView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
        
        cellView.addSubview(timeView)
        timeView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            timeView.leadingAnchor.constraint(equalTo: cellView.leadingAnchor, constant: 16),
            timeView.topAnchor.constraint(equalTo: cellView.topAnchor, constant: 8),
            timeView.bottomAnchor.constraint(equalTo: cellView.bottomAnchor, constant: -8),
            timeView.widthAnchor.constraint(equalToConstant: 82)
        ])

        cellView.addSubview(railView)
        railView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            railView.leadingAnchor.constraint(equalTo: timeView.trailingAnchor, constant: 3),
            railView.topAnchor.constraint(equalTo: cellView.topAnchor),
            railView.bottomAnchor.constraint(equalTo: cellView.bottomAnchor),
            railView.widthAnchor.constraint(equalToConstant: 2)
        ])

        cellView.addSubview(topDot)
        cellView.addSubview(bottomDot)
        topDot.translatesAutoresizingMaskIntoConstraints = false
        bottomDot.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            topDot.centerXAnchor.constraint(equalTo: railView.centerXAnchor),
            topDot.topAnchor.constraint(equalTo: cellView.topAnchor, constant: 8),
            topDot.widthAnchor.constraint(equalToConstant: 6),
            topDot.heightAnchor.constraint(equalToConstant: 6),

            bottomDot.centerXAnchor.constraint(equalTo: railView.centerXAnchor),
            bottomDot.bottomAnchor.constraint(equalTo: cellView.bottomAnchor, constant: -8),
            bottomDot.widthAnchor.constraint(equalToConstant: 6),
            bottomDot.heightAnchor.constraint(equalToConstant: 6)
        ])

        cellView.addSubview(courseView)
        courseView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            courseView.leadingAnchor.constraint(equalTo: railView.trailingAnchor, constant: 4),
            courseView.trailingAnchor.constraint(equalTo: cellView.trailingAnchor, constant: -16),
            courseView.topAnchor.constraint(equalTo: cellView.topAnchor, constant: 8),
            courseView.bottomAnchor.constraint(equalTo: cellView.bottomAnchor, constant: -8),
        ])
    }
}

//#Preview("Cell", traits: .fixedLayout(width: 375, height: 137)) {
//    var table = ScheduleTableViewCell(style: .default, reuseIdentifier: "ScheduleTableViewCell")
//    
//    table.configureTimeView(start: "8:30", end: "10:00")
//    table.cofigureCourceView(name: "Математика", type: "Лекция", room: "А-409", teacher: "Ройтенберг В. Ш.")
//    return table
//    
//}
