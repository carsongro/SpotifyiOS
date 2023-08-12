//
//  WelcomeViewController.swift
//  Spotify
//
//  Created by Carson Gross on 6/25/23.
//

import UIKit
import SwiftUI

class WelcomeViewController: UIViewController, SPTAppRemotePlayerStateDelegate {
    
    weak var coordinator: MainCoordinator?

    var accessToken = UserDefaults.standard.string(forKey: AuthManager.Constants.accessTokenKey) {
        didSet {
            let defaults = UserDefaults.standard
            defaults.set(accessToken, forKey: AuthManager.Constants.accessTokenKey)
        }
    }

    private let connectLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Connect your Spotify account"
        label.font = UIFont.systemFont(ofSize: UIFont.systemFontSize, weight: .heavy)
        label.textColor = .label
        label.textAlignment = .center
        return label
    }()

    private let connectButton: UIButton = {
        let button = UIButton()
        button.setTitle("Connect", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: UIFont.systemFontSize, weight: .heavy)
        button.layer.cornerRadius = 22
        button.backgroundColor = .systemGreen
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(connectLabel)
        view.addSubview(connectButton)
        connectButton.addTarget(self, action: #selector(didTapConnect), for: .touchUpInside)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        connectLabel.frame = CGRect(x: 10,
                                    y: view.height / 2,
                                    width: view.width - 10,
                                    height: 44)
        connectButton.frame = CGRect(x: 10,
                                     y: connectLabel.bottom + 5,
                                     width: view.width - 10,
                                     height: 44)
        PlaybackPresenter.shared.appRemote.delegate = self
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

    }

    //MARK: - Spotify Connection
    
    @objc func didTapConnect(_ button: UIButton) {
        guard let sessionManager = PlaybackPresenter.shared.sessionManager else { return }
        sessionManager.initiateSession(with: AuthManager.Constants.scopes, options: .clientOnly)
    }

    private func presentAlertController(title: String, message: String, buttonTitle: String) {
        DispatchQueue.main.async {
            let controller = UIAlertController(title: title, message: message, preferredStyle: .alert)
            let action = UIAlertAction(title: buttonTitle, style: .default, handler: nil)
            controller.addAction(action)
            self.present(controller, animated: true)
        }
    }
}

// MARK: Style & Layout
extension WelcomeViewController {

    func updateViewBasedOnConnected() {
        if PlaybackPresenter.shared.appRemote.isConnected == true {
            connectButton.isHidden = true
            connectLabel.isHidden = true
            let mainAppTabBarVC = TabBarViewController()
            mainAppTabBarVC.modalPresentationStyle = .fullScreen
            present(mainAppTabBarVC, animated: true)
            PlaybackPresenter.shared.configureAppRemote()
//            dismiss(animated: true)
//            coordinator?.signIn()
        }
        else { // show login
            connectButton.isHidden = false
            connectLabel.isHidden = false
        }
    }
}

// MARK: - SPTAppRemoteDelegate
extension WelcomeViewController: SPTAppRemoteDelegate {
    func appRemoteDidEstablishConnection(_ appRemote: SPTAppRemote) {
        updateViewBasedOnConnected()
    }

    func appRemote(_ appRemote: SPTAppRemote, didDisconnectWithError error: Error?) {
        updateViewBasedOnConnected()
    }

    func appRemote(_ appRemote: SPTAppRemote, didFailConnectionAttemptWithError error: Error?) {
        updateViewBasedOnConnected()
    }
    
    func playerStateDidChange(_ playerState: SPTAppRemotePlayerState) {
        
    }
}

// MARK: - SPTSessionManagerDelegate
extension WelcomeViewController: SPTSessionManagerDelegate {
    func sessionManager(manager: SPTSessionManager, didFailWith error: Error) {
        if error.localizedDescription == "The operation couldn’t be completed. (com.spotify.sdk.login error 1.)" {
            print("AUTHENTICATE with WEBAPI")
        } else {
            presentAlertController(title: "Authorization Failed", message: error.localizedDescription, buttonTitle: "Bummer")
        }
    }

    func sessionManager(manager: SPTSessionManager, didRenew session: SPTSession) {
        presentAlertController(title: "Session Renewed", message: session.description, buttonTitle: "Sweet")
    }

    func sessionManager(manager: SPTSessionManager, didInitiate session: SPTSession) {
        PlaybackPresenter.shared.appRemote.connectionParameters.accessToken = session.accessToken
        PlaybackPresenter.shared.appRemote.connect()
    }
}
