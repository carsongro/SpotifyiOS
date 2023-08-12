//
//  Coordinator.swift
//  Spotify
//
//  Created by Carson Gross on 7/17/23.
//

import UIKit

protocol Coordinator {
    var childCoordinators: [Coordinator] { get set }
    var navigationController: UINavigationController { get set }
}
