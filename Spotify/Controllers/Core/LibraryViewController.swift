//
//  LibraryViewController.swift
//  Spotify
//
//  Created by Carson Gross on 6/25/23.
//

import UIKit

class LibraryViewController: UIViewController {
    
    weak var coordinator: LibraryCoordinator?
    
    private let playlistsVC = LibraryPlaylistsViewController()
    private let albumsVC = LibraryAlbumsViewController()
    
    private let toggleView = LibraryToggleView()
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.isPagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        return scrollView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Library"
        view.backgroundColor = .systemBackground
        view.addSubview(scrollView)
        view.addSubview(toggleView)
        toggleView.delegate = self
        scrollView.contentSize = CGSize(width: view.width * 2, height: scrollView.height)
        addChildren()
        updateBarButtons()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.delegate = self
        scrollView.frame = CGRect(x: 0,
                                  y: view.safeAreaInsets.top + 55,
                                  width: view.width,
                                  height: view.height - view.safeAreaInsets.top - additionalSafeAreaInsets.bottom - 55)
        
        toggleView.frame = CGRect(x: 0,
                                  y: view.safeAreaInsets.top,
                                  width: 200,
                                  height: 55)
    }
    
    private func updateBarButtons() {
        switch toggleView.state {
        case .playlist:
            navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(didTapAdd))
        case .album:
            navigationItem.rightBarButtonItem = nil
        }
    }
    
    @objc private func didTapAdd() {
        playlistsVC.showCreatePlaylistAlert()
    }
    
    private func addChildren() {
        addChild(playlistsVC)
        scrollView.addSubview(playlistsVC.view)
        playlistsVC.view.frame = CGRect(x: 0,
                                        y: 0,
                                        width: scrollView.width,
                                        height: scrollView.height)
        playlistsVC.didMove(toParent: self)
        playlistsVC.coordinator = coordinator
        
        addChild(albumsVC)
        scrollView.addSubview(albumsVC.view)
        albumsVC.view.frame = CGRect(x: view.width,
                                     y: 0,
                                     width: scrollView.width,
                                     height: scrollView.height)
        albumsVC.didMove(toParent: self)
        albumsVC.coordinator = coordinator
    }

}

extension LibraryViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // Get the ratio of the toggle view to scroll view
        // The scroll view is multiplied by 2 because it's two equal width sections
        // This is so that the indicator follows the user's finger
        let ratio = toggleView.width / (scrollView.width * 2)
        toggleView.update(for: scrollView.contentOffset.x * ratio)
        toggleView.state = scrollView.contentOffset.x > scrollView.width / 2 ? .album : .playlist
        self.updateBarButtons()
    }
}

extension LibraryViewController: LibraryToggleViewDelegate {
    func libraryToggleViewDidTapPlaylists(_ toggleView: LibraryToggleView) {
        UIView.animate(withDuration: 0.4, delay: .zero, usingSpringWithDamping: 1, initialSpringVelocity: 6, options: .curveEaseInOut) {
            self.scrollView.setContentOffset(.zero, animated: false)
        }
        self.updateBarButtons()
    }
    
    func libraryToggleViewDidTapAlbums(_ toggleView: LibraryToggleView) {
        UIView.animate(withDuration: 0.4, delay: .zero, usingSpringWithDamping: 1, initialSpringVelocity: 6, options: .curveEaseInOut) {
            self.scrollView.setContentOffset(CGPoint(x: self.view.width, y: 0), animated: false)
        }
        self.updateBarButtons()
    }
    
}
