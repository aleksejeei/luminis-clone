import UIKit

final class ScheduleHeader: UIView {
    
    let timeLabel: UILabel = {
        let label = UILabel()
        label.font = .Montserrat.Medium.size(of: 14)
        label.textColor = AccentColors.normalColor
        label.text = "Time"
        return label
    }()
    
    let courseLabel: UILabel = {
        let label = UILabel()
        label.font = .Montserrat.Medium.size(of: 14)
        label.textColor = AccentColors.normalColor
        label.text = "Course"
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = AccentColors.bgColor
        configure()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ScheduleHeader {
    private func configure() {
        setupTimeLabel()
        setupCourseLabel()
    }
    
    func setupTimeLabel() {
        addSubview(timeLabel)
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            timeLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 28),
            timeLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -6)
        ])
    }
    
    func setupCourseLabel() {
        addSubview(courseLabel)
        courseLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            courseLabel.leadingAnchor.constraint(equalTo: timeLabel.trailingAnchor, constant: 34 + 4),
            courseLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -6)
        ])
    }
}

