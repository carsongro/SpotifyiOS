//
//  LibraryCoordinator.swift
//  Spotify
//
//  Created by Carson Gross on 7/17/23.
//

import UIKit

class LibraryCoordinator: Coordinator {
    var childCoordinators = [Coordinator]()
    
    var navigationController: UINavigationController
    
    init(
         navigationController: UINavigationController = UINavigationController(rootViewController: LibraryViewController())
    ) {
        self.navigationController = navigationController
        
        let viewController = LibraryViewController()
        viewController.tabBarItem = UITabBarItem(title: "Library", image: UIImage(systemName: "music.note.list"), tag: 1)
        navigationController.navigationBar.tintColor = .label
        navigationController.navigationBar.prefersLargeTitles = true
        viewController.coordinator = self
        
        navigationController.viewControllers = [viewController]
    }
    
    func pushPlaylistController(playlist: Playlist) {
        let vc = PlaylistViewController(playlist: playlist)
        vc.navigationItem.largeTitleDisplayMode = .never
        vc.isOwner = (playlist.owner.id == AuthManager.shared.currentUserId)
        navigationController.pushViewController(vc, animated: true)
    }
    
    func pushAlbumController(album: Album) {
        let vc = AlbumViewController(album: album)
        vc.navigationItem.largeTitleDisplayMode = .never
        navigationController.pushViewController(vc, animated: true)
    }
    
    func start() {
        
    }
}
