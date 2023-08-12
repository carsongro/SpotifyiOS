//
//  SearchCoordinator.swift
//  Spotify
//
//  Created by Carson Gross on 7/17/23.
//

import UIKit

class SearchCoordinator: Coordinator {
    var childCoordinators = [Coordinator]()
    
    var navigationController: UINavigationController
    
    init(
         navigationController: UINavigationController = UINavigationController(rootViewController: SearchViewController())
    ) {
        self.navigationController = navigationController
        
        let viewController = SearchViewController()
        viewController.tabBarItem = UITabBarItem(title: "Search", image: UIImage(systemName: "magnifyingglass"), tag: 1)
        navigationController.navigationBar.tintColor = .label
        navigationController.navigationBar.prefersLargeTitles = true
        viewController.coordinator = self
        
        navigationController.viewControllers = [viewController]
    }
    
    func pushCategoryViewController(category: Category) {
        let vc = CategoryViewController(category: category)
        vc.navigationItem.largeTitleDisplayMode = .never
        vc.coordinator = self
        navigationController.pushViewController(vc, animated: true)
    }
    
    func pushPlaylistViewController(playlist: Playlist) {
        let vc = PlaylistViewController(playlist: playlist)
        vc.navigationItem.largeTitleDisplayMode = .never
        navigationController.pushViewController(vc, animated: true)
    }
    
    func pushAlbumViewController(album: Album) {
        let vc = AlbumViewController(album: album)
        vc.navigationItem.largeTitleDisplayMode = .never
        navigationController.pushViewController(vc, animated: true)
    }
    
    func start() {
        
    }
}
