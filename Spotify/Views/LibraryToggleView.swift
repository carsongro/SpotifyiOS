//
//  LibraryToggleView.swift
//  Spotify
//
//  Created by Carson Gross on 7/6/23.
//

import UIKit

protocol LibraryToggleViewDelegate: AnyObject {
    func libraryToggleViewDidTapPlaylists(_ toggleView: LibraryToggleView)
    func libraryToggleViewDidTapAlbums(_ toggleView: LibraryToggleView)
}

class LibraryToggleView: UIView {
    
    enum State {
        case playlist
        case album
    }
    
    var state: State = .playlist
    
    weak var delegate: LibraryToggleViewDelegate?
    
    private let playlistButton: UIButton = {
        let button = UIButton()
        button.setTitleColor(.label, for: .normal)
        button.setTitle("Playlists", for: .normal)
        return button
    }()
    
    private let albumsButton: UIButton = {
        let button = UIButton()
        button.setTitleColor(.label, for: .normal)
        button.setTitle("Albums", for: .normal)
        return button
    }()
    
    private let indicatorView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBlue
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 1.5
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(playlistButton)
        addSubview(albumsButton)
        addSubview(indicatorView)
        
        playlistButton.addTarget(self, action: #selector(didTapPlaylists), for: .touchUpInside)
        albumsButton.addTarget(self, action: #selector(didTapAlbums), for: .touchUpInside)

    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        playlistButton.frame = CGRect(x: 0,
                                      y: 0,
                                      width: 100,
                                      height: 40)
        albumsButton.frame = CGRect(x: playlistButton.right,
                                    y: 0,
                                    width: 100,
                                    height: 40)
        indicatorView.frame = CGRect(x: 0,
                                     y: playlistButton.bottom,
                                     width: 100,
                                     height: 3)
    }
    
    @objc private func didTapPlaylists() {
        state = .playlist
        delegate?.libraryToggleViewDidTapPlaylists(self)
    }
    
    @objc private func didTapAlbums() {
        state = .album
        delegate?.libraryToggleViewDidTapAlbums(self)
    }
    
    func update(for offset: CGFloat) {
        self.indicatorView.frame = CGRect(x: offset,
                                          y: self.playlistButton.bottom,
                                          width: 100,
                                          height: 3)
    }
}
