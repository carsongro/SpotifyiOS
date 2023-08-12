//
//  TabBarViewController.swift
//  Spotify
//
//  Created by Carson Gross on 6/25/23.
//

import UIKit

class TabBarViewController: UITabBarController {
    let home = HomeCoordinator()
    let search = SearchCoordinator()
    let library = LibraryCoordinator()
    
    private let miniPlayer = MiniPlayerViewController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewControllers = [home.navigationController,
                           search.navigationController,
                           library.navigationController]
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        addChild(miniPlayer)
        view.addSubview(miniPlayer.view)
        miniPlayer.view.frame = CGRect(x: 6,
                                       y: tabBar.top - 60,
                                       width: view.width - 12,
                                       height: 60)
        miniPlayer.didMove(toParent: self)
    }
}
