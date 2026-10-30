//
//  MarkCell.swift
//  YSTU_APP
//

import UIKit

final class MarkCell: UITableViewCell {

    static let identifier = "MarkCell"

    private let cardView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 16
        view.backgroundColor = AccentColors.interfaceColor
        return view
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .Montserrat.SemiBold.size(of: 16)
        label.textColor = AccentColors.ordinaryTextColor
        label.numberOfLines = 0
        return label
    }()

    private let infoLabel: UILabel = {
        let label = UILabel()
        label.font = .Montserrat.Medium.size(of: 12)
        label.textColor = AccentColors.normalColor
        label.numberOfLines = 0
        return label
    }()

    private let badgeView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 17
        return view
    }()

    private let badgeLabel: UILabel = {
        let label = UILabel()
        label.font = .Montserrat.Bold.size(of: 16)
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        configureLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with mark: Mark) {
        nameLabel.text = mark.lessonName ?? mark.markName ?? "—"

        var infoParts: [String] = []
        if let control = mark.controlTypeName, !control.isEmpty { infoParts.append(control) }
        if let years = mark.years, !years.isEmpty { infoParts.append(years) }
        if let credits = mark.creditUnit, credits > 0 {
            infoParts.append("\(Self.formatNumber(credits)) cr.")
        }
        infoLabel.text = infoParts.joined(separator: " • ")

        badgeLabel.text = Self.markText(mark)
        badgeView.backgroundColor = Self.markColor(mark)
        badgeLabel.textColor = mark.markName == nil ? AccentColors.normalColor : .white
    }

    static func markText(_ mark: Mark) -> String {
        guard mark.markName != nil else { return "—" }
        guard let value = mark.mark, value > 0 else { return "✓" }
        return formatNumber(value)
    }

    static func markColor(_ mark: Mark) -> UIColor {
        guard mark.markName != nil else { return AccentColors.normalColor.withAlphaComponent(0.2) }
        guard let value = mark.mark else { return AccentColors.normalColor }
        switch value {
        case ..<1: return .systemGreen      // pass
        case ..<2.5: return .systemRed      // 2
        case ..<3.5: return .systemBlue     // 3
        case ..<4.5: return .systemYellow   // 4
        default: return .systemGreen        // 5
        }
    }

    private static func formatNumber(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(value))
            : String(format: "%.1f", value)
    }

    private func configureLayout() {
        contentView.addSubview(cardView)
        cardView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6)
        ])

        cardView.addSubview(badgeView)
        cardView.addSubview(nameLabel)
        cardView.addSubview(infoLabel)
        badgeView.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        infoLabel.translatesAutoresizingMaskIntoConstraints = false

        badgeView.addSubview(badgeLabel)
        badgeLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            badgeView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            badgeView.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            badgeView.widthAnchor.constraint(equalToConstant: 34),
            badgeView.heightAnchor.constraint(equalToConstant: 34),

            badgeLabel.centerXAnchor.constraint(equalTo: badgeView.centerXAnchor),
            badgeLabel.centerYAnchor.constraint(equalTo: badgeView.centerYAnchor),

            nameLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(equalTo: badgeView.leadingAnchor, constant: -12),
            nameLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 16),

            infoLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            infoLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            infoLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            infoLabel.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -16)
        ])

        setShadow(cardView)
    }
}
