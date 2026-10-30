//
//  TabBarController.swift
//  YSTU_APP
//
//  Created by Alex Neumark on 09.09.2024.
//

import UIKit

final class TabBarController: UITabBarController, UITabBarControllerDelegate {
    
    private var isTabBarCustomized = false
    
    init(controllers: [UINavigationController]) {
        super.init(nibName: nil, bundle: nil)
        controllers.forEach { self.addChild($0) }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !isTabBarCustomized {
            tabBar.setCustomStyle()
            isTabBarCustomized = true
        }
    }
    
    private func animate(_ imageView: UIImageView) {
        UIView.animate(withDuration: 0.1, animations: {
            imageView.transform = CGAffineTransform(scaleX: 1.2, y: 1.4)
        }) { _ in
            UIView.animate(withDuration: 0.2,
                           delay: 0.0,
                           usingSpringWithDamping: 0.3,
                           initialSpringVelocity: 7.0,
                           options: .curveEaseInOut,
                           animations: {
                imageView.transform = CGAffineTransform.identity
            })
        }
    }
    
    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        if let index = tabBar.items?.firstIndex(of: item), let imageView = getImageView(forIndex: index), index != selectedIndex {
            animate(imageView)
        }
    }
    
    private func getImageView(forIndex index: Int) -> UIImageView? {
        let buttons = tabBar.subviews
            .compactMap { $0 as? UIControl }
            .sorted { $0.frame.minX < $1.frame.minX }
        guard index < buttons.count else { return nil }

        return findImageView(in: buttons[index])
    }

    private func findImageView(in view: UIView) -> UIImageView? {
        for subview in view.subviews {
            if let imageView = subview as? UIImageView { return imageView }
            if let found = findImageView(in: subview) { return found }
        }
        return nil
    }
}


private extension UITabBar {
    func setCustomStyle() {
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()

        appearance.stackedLayoutAppearance.selected.iconColor = AccentColors.selectedColor
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .font: UIFont.Montserrat.Regular.size(of: 10),
            .foregroundColor: AccentColors.selectedColor
        ]

        appearance.stackedLayoutAppearance.normal.iconColor = AccentColors.normalColor
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .font: UIFont.Montserrat.Regular.size(of: 10),
            .foregroundColor: AccentColors.normalColor
        ]

        self.standardAppearance = appearance
        self.scrollEdgeAppearance = appearance
    }
}


