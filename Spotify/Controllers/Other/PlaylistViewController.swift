//
//  PlaylistViewController.swift
//  Spotify
//
//  Created by Carson Gross on 6/25/23.
//

import UIKit

class PlaylistViewController: UIViewController, UIGestureRecognizerDelegate {
    
    //TODO: Add sorting

    private var playlist: Playlist
    
    public var isOwner = false
    
    private var playlistNextURL: String?
    private var isLoadingMoreSongs = false
    
    private let collectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: UICollectionViewCompositionalLayout(
            sectionProvider: { _, _ -> NSCollectionLayoutSection? in
                let item = NSCollectionLayoutItem(
                    layoutSize: NSCollectionLayoutSize(
                        widthDimension: .fractionalWidth(1.0),
                        heightDimension: .fractionalHeight(1.0)
                    )
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
    
    init(playlist: Playlist) {
        self.playlist = playlist
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    private var viewModels = [RecommendedTrackCellViewModel]()
    private var tracks = [AudioTrack]()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = playlist.name
        view.backgroundColor = .systemBackground
        
        view.addSubview(collectionView)
        
        collectionView.register(PlaylistHeaderCollectionReusableView.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                withReuseIdentifier: PlaylistHeaderCollectionReusableView.identifier)
        collectionView.register(RecommendedTrackCollectionViewCell.self,
                                forCellWithReuseIdentifier: RecommendedTrackCollectionViewCell.identifier)
        collectionView.backgroundColor = .systemBackground
        collectionView.delegate = self
        collectionView.dataSource = self
        
        fetchPlaylists()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .action,
                                                            target: self,
                                                            action: #selector(didTapShare))
        
        let gesture = UILongPressGestureRecognizer(target: self, action: #selector(didLongPress(_:)))
        gesture.delegate = self
        gesture.minimumPressDuration = 0.4
        
        if isOwner {
            collectionView.addGestureRecognizer(gesture)
        }
        
        HapticsManager.shared.prepareHaptics()
    }
    
    private func fetchPlaylists() {
        APICaller.shared.getPlaylistDetails(for: playlist) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let model):
                    self?.playlistNextURL = model.tracks.next
                    self?.tracks = model.tracks.items.compactMap { $0.track }
                    self?.viewModels = model.tracks.items.compactMap {
                        guard let track = $0.track else {
                            return nil
                        }
                        
                        return RecommendedTrackCellViewModel(
                            name: track.name,
                            artistName: (track.artists.compactMap({ $0.name })).joined(separator: ", "),
                            artworkURL: URL(string: track.album?.images.first?.url ?? "")
                        )
                    }
                    self?.collectionView.reloadData()
                case .failure(let error):
                    print(error.localizedDescription)
                }
            }
        }
    }
    
    @objc private func didLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else {
            return
        }
        
        let touchPoint = gesture.location(in: collectionView)
        guard let indexPath = collectionView.indexPathForItem(at: touchPoint) else {
            return
        }
        
        HapticsManager.shared.thunk()
        
        let trackToDelete = tracks[indexPath.row]
        
        let actionSheet = UIAlertController(title: trackToDelete.name,
                                            message: "Would you like to remove this from the playlist?",
                                            preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(
            title: "Remove",
            style: .destructive
        ) { [weak self] _ in
            guard let strongSelf = self else { return }
            APICaller.shared.removeTrackFromPlaylist(
                track: trackToDelete,
                playlist: strongSelf.playlist
            ) { success in
                DispatchQueue.main.async {
                    if success {
                        HapticsManager.shared.success()
                        strongSelf.tracks.remove(at: indexPath.row)
                        strongSelf.viewModels.remove(at: indexPath.row)
                        strongSelf.collectionView.reloadData()
                    } else {
                        print("Failed to removed")
                    }
                }
            }
        })
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(actionSheet, animated: true)
    }
    
    @objc private func didTapShare() {
        guard let url = URL(string: playlist.external_urls?["spotify"] ?? "") else {
            return
        }
        let vc = UIActivityViewController(activityItems: ["Check out this playlist I found!", url],
                                          applicationActivities: [])
        vc.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
        present(vc, animated: true)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        collectionView.frame = view.bounds
        collectionView.contentInset.bottom = 70
    }
    
    /// Paginate if additional songs are needed
    public func fetchAdditionalSongs(url: String) {
        guard !isLoadingMoreSongs else {
            return
        }
        isLoadingMoreSongs = true
        
        APICaller.shared.getAdditionalTracks(url: url) { [weak self] result in
            guard let strongSelf = self else {
                return
            }
            switch result {
            case .success(let model):
                strongSelf.playlistNextURL = model.next
                let moreResults = model.items.compactMap { $0.track }
                let moreModels: [RecommendedTrackCellViewModel] = model.items.compactMap {
                    guard let track = $0.track else {
                        return nil
                    }
                    
                    return RecommendedTrackCellViewModel(
                        name: track.name,
                        artistName: (track.artists.compactMap({ $0.name })).joined(separator: ", "),
                        artworkURL: URL(string: track.album?.images.first?.url ?? "")
                    )
                }

                let originalCount = strongSelf.tracks.count
                let newCount = moreResults.count
                let total = originalCount + newCount
                let startingIndex = total - newCount
                let indexPathsToAdd: [IndexPath] = Array(startingIndex..<total).compactMap({
                    return IndexPath(row: $0, section: 0)
                })
                DispatchQueue.main.async {
                    strongSelf.tracks.append(contentsOf: moreResults)
                    strongSelf.viewModels.append(contentsOf: moreModels)
                    strongSelf.didLoadMoreSongs(
                        with: indexPathsToAdd
                    )
                    strongSelf.isLoadingMoreSongs = false
                }
            case .failure(let failure):
                print(String(describing: failure))
                self?.isLoadingMoreSongs = false
            }
        }
    }
    
    private func didLoadMoreSongs(with newIndexPaths: [IndexPath]) {
        collectionView.performBatchUpdates {
            self.collectionView.insertItems(at: newIndexPaths)
        }
    }
    
    private var total = 0
}

extension PlaylistViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModels.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: RecommendedTrackCollectionViewCell.identifier,
            for: indexPath
        ) as? RecommendedTrackCollectionViewCell else {
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
            name: playlist.name,
            ownerName: playlist.owner.display_name,
            description: playlist.description,
            artworkURL: URL(string: playlist.images.first?.url ?? "")
        )
        header.configure(with: headerViewModel)
        header.delegate = self
        return header
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        // Play song
        let index = indexPath.row
        playlist.next = playlistNextURL
        PlaybackPresenter.shared.startPlayback(tracks: tracks, setIndex: index, fromPlaylist: playlist)
    }
}

extension PlaylistViewController: PlaylistHeaderCollectionReusableViewDelegate {
    func playlistHeaderCollectionReusableViewDidTapPlayAll(_ header: PlaylistHeaderCollectionReusableView) {
        playlist.next = playlistNextURL
        PlaybackPresenter.shared.startPlayback(
            tracks: tracks,
            fromPlaylist: playlist
        )
    }
}

extension PlaylistViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard !isLoadingMoreSongs,
              !viewModels.isEmpty,
              let url = playlistNextURL else {
            return
        }
        
        let offset = scrollView.contentOffset.y
        let totalContentHeight = scrollView.contentSize.height
        let totalScrollViewFixedHeight = scrollView.frame.size.height
        
        if offset >= ((totalContentHeight - totalScrollViewFixedHeight) / 2) {
            fetchAdditionalSongs(url: url)
        }
    }
}
