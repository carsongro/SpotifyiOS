//
//  AlbumViewController.swift
//  Spotify
//
//  Created by Carson Gross on 7/2/23.
//

import UIKit

class AlbumViewController: UIViewController {
    
    private let album: Album
    private var tracks = [AudioTrack]()
    private var viewModels = [AlbumCollectionViewCellViewModel]()
    
    private var isSavedAlbum = false
    
    private var navigationBarButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "ellipsis"), for: .normal)
        button.tintColor = .label
        return button
    }()
    
    private let collectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: UICollectionViewCompositionalLayout(
            sectionProvider: { _, _ -> NSCollectionLayoutSection? in
                let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .fractionalHeight(1.0))
                )
                
                item.contentInsets = NSDirectionalEdgeInsets(top: 1,
                                                             leading: 2,
                                                             bottom: 1,
                                                             trailing: 2)
                
                let group = NSCollectionLayoutGroup.vertical (
                    layoutSize: NSCollectionLayoutSize(
                        widthDimension: .fractionalWidth(1),
                        heightDimension: .absolute(60)),
                    subitem: item,
                    count: 1
                )
                
                let section = NSCollectionLayoutSection(group: group)
                section.boundarySupplementaryItems = [
                    NSCollectionLayoutBoundarySupplementaryItem(
                        layoutSize: NSCollectionLayoutSize(
                            widthDimension: .fractionalWidth(1.0),
                            heightDimension: .fractionalWidth(1.0)
                        ),
                        elementKind: UICollectionView.elementKindSectionHeader,
                        alignment: .top)
                ]
                return section
            }
        )
    )
    
    init(album: Album) {
        self.album = album
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = album.name
        view.backgroundColor = .systemBackground
        
        view.addSubview(collectionView)
        
        collectionView.register(PlaylistHeaderCollectionReusableView.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                withReuseIdentifier: PlaylistHeaderCollectionReusableView.identifier)
        collectionView.register(AlbumTrackCollectionViewCell.self,
                                forCellWithReuseIdentifier: AlbumTrackCollectionViewCell.identifier)
        collectionView.backgroundColor = .systemBackground
        collectionView.delegate = self
        collectionView.dataSource = self
        
        fetchData()
        configureNavigationButtons()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        collectionView.frame = view.bounds
        collectionView.contentInset.bottom = 70
    }
    
    private func configureNavigationButtons() {
        navigationBarButton.addTarget(self, action: #selector(didTapActions), for: .touchUpInside)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: navigationBarButton)
    }
    
    private func fetchData() {
        APICaller.shared.getAlbumDetails(for: album) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let model):
                    self?.tracks = model.tracks.items
                    self?.viewModels = model.tracks.items.compactMap({
                        AlbumCollectionViewCellViewModel(
                            name: $0.name,
                            artistName: $0.artists.first?.name ?? ""
                        )
                    })
                    self?.collectionView.reloadData()
                case .failure(let error):
                    print(error.localizedDescription)
                }
            }
        }
        
        APICaller.shared.checkSavedAlbums(album: album) { [weak self] success in
            DispatchQueue.main.async {
                self?.isSavedAlbum = success
            }
        }
    }
    
    @objc private func didTapActions() {
        let actionSheet = UIAlertController(title: album.name,
                                            message: nil,
                                            preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        actionSheet.addAction(
            UIAlertAction(
                title: "Share Album",
                style: .default
            ) { [weak self] _ in
                self?.shareAlbum()
            }
        )
        
        if !isSavedAlbum {
            actionSheet.addAction(
                UIAlertAction(
                    title: "Save Album",
                    style: .default
                ) { [weak self] _ in
                    guard let strongSelf = self else { return }
                    APICaller.shared.saveAlbum(
                        album: strongSelf.album
                    ) { success in
                        if success {
                            DispatchQueue.main.async {
                                HapticsManager.shared.success()
                                NotificationCenter.default.post(name: .albumSavedNotification, object: nil)
                                strongSelf.isSavedAlbum = true
                                strongSelf.configureNavigationButtons()
                            }
                        }
                    }
                }
            )
        }
        
        present(actionSheet, animated: true)
    }
    
    private func shareAlbum() {
        guard let url = URL(string: album.external_urls["spotify"] ?? "") else {
            return
        }
        
        let vc = UIActivityViewController(activityItems: ["Check out this album I found!", url],
                                          applicationActivities: [])
        vc.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
        present(vc, animated: true)
    }
}

extension AlbumViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModels.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: AlbumTrackCollectionViewCell.identifier,
            for: indexPath
        ) as? AlbumTrackCollectionViewCell else {
            return UICollectionViewCell()
        }
        cell.configure(with: viewModels[indexPath.row])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard kind == UICollectionView.elementKindSectionHeader,
              let header = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: PlaylistHeaderCollectionReusableView.identifier,
                for: indexPath
              ) as? PlaylistHeaderCollectionReusableView else  {
            return UICollectionReusableView()
        }
        let headerViewModel = PlaylistHeaderViewViewModel(
            name: album.name,
            ownerName: (album.artists.compactMap({ $0.name })).joined(separator: ", "),
            description: "Release Date: \(String.formattedDate(string: album.release_date))",
            artworkURL: URL(string: album.images.first?.url ?? "")
        )
        header.configure(with: headerViewModel)
        header.delegate = self
        return header
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        var track = tracks[indexPath.row]
        track.album = album
        PlaybackPresenter.shared.startPlayback(tracks: tracks, setIndex: indexPath.row)
    }

}

extension AlbumViewController: PlaylistHeaderCollectionReusableViewDelegate {
    func playlistHeaderCollectionReusableViewDidTapPlayAll(_ header: PlaylistHeaderCollectionReusableView) {
        let tracksWithAlbum: [AudioTrack] = tracks.compactMap {
            var track = $0
            track.album = self.album
            return track
        }
        PlaybackPresenter.shared.startPlayback(tracks: tracksWithAlbum)
    }
    
    func playlistHeaderCollectionReusableViewDidTapRepeat(_ header: PlaylistHeaderCollectionReusableView) {
        
    }
}
