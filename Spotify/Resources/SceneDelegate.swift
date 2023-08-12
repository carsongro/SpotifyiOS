//
//  SceneDelegate.swift
//  Spotify
//
//  Created by Carson Gross on 6/25/23.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
//    var coordinator: MainCoordinator?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(frame: UIScreen.main.bounds)
        window!.makeKeyAndVisible()
        window!.windowScene = windowScene
        
        if AuthManager.shared.isSignedIn {
            AuthManager.shared.refreshIfNeeded(completion: nil)
            let tabBarVC = TabBarViewController()
            PlaybackPresenter.shared.configureAppRemote()
            window?.rootViewController = tabBarVC
        } else {
            let navVC = UINavigationController(rootViewController: WelcomeViewController())
            navVC.navigationBar.prefersLargeTitles = true
            navVC.viewControllers.first?.navigationItem.largeTitleDisplayMode = .always
            window?.rootViewController = navVC
        }
        
        AuthManager.shared.getCurrentUser()
        
        window?.makeKeyAndVisible()
    }
    
//    guard let windowScene = (scene as? UIWindowScene) else { return }
//
//    let navController = UINavigationController()
//    navController.isNavigationBarHidden = true
//
//    coordinator = MainCoordinator(navigationController: navController)
//
//    coordinator?.start()
//
//    window = UIWindow(frame: UIScreen.main.bounds)
//    window!.windowScene = windowScene
//    window?.rootViewController = navController
//    window?.makeKeyAndVisible()

    // For spotify authorization and authentication flow
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else { return }
        let parameters = PlaybackPresenter.shared.appRemote.authorizationParameters(from: url)
        if let code = parameters?["code"] {
            PlaybackPresenter.shared.responseCode = code
        } else if let access_token = parameters?[SPTAppRemoteAccessTokenKey] {
            PlaybackPresenter.shared.accessToken = access_token
        } else if let error_description = parameters?[SPTAppRemoteErrorDescriptionKey] {
            print("No access token error =", error_description)
        }
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        if let accessToken = PlaybackPresenter.shared.appRemote.connectionParameters.accessToken {
            PlaybackPresenter.shared.appRemote.connectionParameters.accessToken = accessToken
            PlaybackPresenter.shared.appRemote.connect()
        }  else if let accessToken = AuthManager.shared.accessToken {
            PlaybackPresenter.shared.appRemote.connectionParameters.accessToken = accessToken
            PlaybackPresenter.shared.appRemote.connect()
        }
    }

    func sceneWillResignActive(_ scene: UIScene) {
        if PlaybackPresenter.shared.appRemote.isConnected {
            PlaybackPresenter.shared.appRemote.disconnect()
        }
    }
}

