//
//  MainCoordinator.swift
//  Spotify
//
//  Created by Carson Gross on 7/17/23.
//

import UIKit

class MainCoordinator: Coordinator {
    var childCoordinators = [Coordinator]()
    
    var navigationController: UINavigationController
    
    init(
         navigationController: UINavigationController
    ) {
        self.navigationController = navigationController
        self.navigationController.isNavigationBarHidden = true
    }
    
    func start() {
        if AuthManager.shared.isSignedIn {
            AuthManager.shared.refreshIfNeeded(completion: nil)
            let tabBarVC = TabBarViewController()
            PlaybackPresenter.shared.configureAppRemote()
            navigationController.pushViewController(tabBarVC, animated: false)
        } else {
            let vc = WelcomeViewController()
            vc.coordinator = self
            navigationController.pushViewController(vc, animated: false)
        }
        
        AuthManager.shared.getCurrentUser()
    }
    
    func signIn() {
        let mainAppTabBarVC = TabBarViewController()
        mainAppTabBarVC.modalPresentationStyle = .fullScreen
        navigationController.present(mainAppTabBarVC, animated: true)
        PlaybackPresenter.shared.configureAppRemote()
    }
}

