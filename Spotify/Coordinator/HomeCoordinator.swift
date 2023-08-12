//
//  HomeCoordinator.swift
//  Spotify
//
//  Created by Carson Gross on 7/17/23.
//

import UIKit

class HomeCoordinator: Coordinator {
    var childCoordinators = [Coordinator]()
    
    var navigationController: UINavigationController
    
    init(
         navigationController: UINavigationController = UINavigationController(rootViewController: HomeViewController())
    ) {
        self.navigationController = navigationController
        
        let viewController = HomeViewController()
        viewController.tabBarItem = UITabBarItem(title: "Home", image: UIImage(systemName: "house"), tag: 1)
        navigationController.navigationBar.tintColor = .label
        navigationController.navigationBar.prefersLargeTitles = true
        viewController.coordinator = self
        
        navigationController.viewControllers = [viewController]
    }
    
    func pushSettingsViewController() {
        let vc = SettingsViewController()
        vc.title = "Settings"
        vc.navigationItem.largeTitleDisplayMode = .never
        vc.coordinator = self
        navigationController.pushViewController(vc, animated: true)
    }
    
    func handleSignOut() {
        let welcomeVC = WelcomeViewController()
        let navVC = UINavigationController(rootViewController: welcomeVC)
        navVC.navigationBar.prefersLargeTitles = true
        navVC.viewControllers.first?.navigationItem.largeTitleDisplayMode = .always
        navVC.modalPresentationStyle = .fullScreen
        navigationController.present(navVC, animated: false) {
            self.navigationController.popToRootViewController(animated: false)
        }
    }
    
    func pushProfileViewController() {
        let vc = ProfileViewController()
        vc.title = "Profile"
        vc.navigationItem.largeTitleDisplayMode = .never
        navigationController.pushViewController(vc, animated: true)
    }
    
    func pushPlaylistViewController(playlist: Playlist) {
        let vc = PlaylistViewController(playlist: playlist)
        vc.title = playlist.name
        vc.navigationItem.largeTitleDisplayMode = .never
        navigationController.pushViewController(vc, animated: true)
    }
    
    func pushAlbumViewController(album: Album) {
        let vc = AlbumViewController(album: album)
        vc.title = album.name
        vc.navigationItem.largeTitleDisplayMode = .never
        navigationController.pushViewController(vc, animated: true)
    }
    
    func start() {
        
    }
}
