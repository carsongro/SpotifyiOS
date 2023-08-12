//
//  MiniPlayerViewController.swift
//  Spotify
//
//  Created by Carson Gross on 7/10/23.
//

import UIKit

/// The small player view that hovers above the tab bar
/// This view is as a child view to the tab bar, so the coordinates are relative to this views frame
class MiniPlayerViewController: UIViewController {
    
    weak var dataSource: PlayerDataSource?
    weak var playerDelegate: PlayerViewControllerDelegate?
    
    static var offset = CGPoint(x: 0, y: 0)
    
    private var currentCollectionViewIndex = PlaybackPresenter.shared.correctMiniPlayerIndex
    private var lastCollectionViewIndex = PlaybackPresenter.shared.correctMiniPlayerIndex
    
    private var collectionView: UICollectionView = {
        let configuration = UICollectionViewCompositionalLayoutConfiguration()
        configuration.scrollDirection = .horizontal
        let collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout: UICollectionViewCompositionalLayout (
                sectionProvider: { sectionIndex , _ -> NSCollectionLayoutSection? in
                    let item = NSCollectionLayoutItem(
                        layoutSize: NSCollectionLayoutSize(
                            widthDimension: .fractionalWidth(1),
                            heightDimension: .fractionalHeight(1)
                        )
                    )
                    
                    let group = NSCollectionLayoutGroup.horizontal(
                        layoutSize:
                            NSCollectionLayoutSize(
                                widthDimension: .fractionalWidth(1),
                                heightDimension: .fractionalHeight(1)
                            ),
                        subitem: item,
                        count: 1
                    )
                    
                    let section = NSCollectionLayoutSection(group: group)
                    section.orthogonalScrollingBehavior = .groupPaging
                    section.visibleItemsInvalidationHandler = { visibleItems, scrollOffset, _ in
                        offset = scrollOffset
                    }
                    return section
                },
                configuration: configuration
            )
        )
        return collectionView
    }()
    
    private let playPauseButton: UIButton = {
        let button = UIButton()
        button.setImage(
            UIImage(
                systemName: "play.fill",
                withConfiguration: UIImage.SymbolConfiguration(
                    pointSize: 20,
                    weight: .regular
                )
            ),
            for: .normal
        )
        button.tintColor = .label
        return button
    }()
    
    private let imageBackgroundView: UIView = {
        let view = UIView()
        view.clipsToBounds = false
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.8
        view.layer.shadowOffset = CGSize(width: 2, height: 2)
        view.layer.shadowRadius = 8
        return view
    }()
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 4
        imageView.layer.masksToBounds = true
        imageView.clipsToBounds = true
        return imageView
    }()
    
    private let connectButton: UIButton = {
        let button = UIButton()
        button.setTitle("Connect", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: UIFont.systemFontSize, weight: .heavy)
        button.layer.cornerRadius = 22
        button.backgroundColor = .systemGreen
        button.layer.masksToBounds = true
        return button
    }()
    
    private let backgroundBlur: UIVisualEffectView = {
        let blur = UIBlurEffect(style: .regular)
        let blurView = UIVisualEffectView(effect: blur)
        blurView.clipsToBounds = true
        return blurView
    }()
    
    private let repeatButton: UIButton = {
            let button = UIButton()
            let image = UIImage(systemName: "repeat", withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .regular))
            button.setImage(image, for: .normal)
            button.tintColor = .gray
            return button
        }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.playerDelegate = PlaybackPresenter.shared
        self.dataSource = PlaybackPresenter.shared
        PlaybackPresenter.shared.setMiniPlayerViewController(with: self)
        
        view.addSubview(backgroundBlur)
        configureCollectionView()
        view.addSubview(imageBackgroundView)
        imageBackgroundView.addSubview(imageView)
        view.addSubviews(playPauseButton, repeatButton)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let cornerRadius: CGFloat = 8
        let viewSize: CGFloat = 44
        view.layer.cornerRadius = cornerRadius
        
        imageBackgroundView.frame = CGRect(x: 8,
                                           y: view.height / 2 - viewSize / 2,
                                           width: viewSize,
                                           height: viewSize)
        imageBackgroundView.layer.shadowPath = UIBezierPath(roundedRect: imageBackgroundView.bounds, cornerRadius: cornerRadius).cgPath
        imageView.frame = imageBackgroundView.bounds
        
        backgroundBlur.frame = CGRect(x: 0,
                                      y: 0,
                                      width: view.width,
                                      height: view.height)
        
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = UIBezierPath(roundedRect: backgroundBlur.bounds, cornerRadius: cornerRadius).cgPath
        backgroundBlur.layer.mask = shapeLayer
        
        playPauseButton.addTarget(self, action: #selector(didTapPauseOrPlay(_:)), for: .touchUpInside)
        playPauseButton.frame = CGRect(x: view.width - 8 - viewSize,
                                       y: view.height / 2 - viewSize / 2,
                                       width: viewSize,
                                       height: viewSize)
        
        repeatButton.addTarget(self, action: #selector(didTapRepeatButton(_:)), for: .touchUpInside)
        repeatButton.frame = CGRect(x: playPauseButton.left - 4 - viewSize,
                                       y: view.height / 2 - viewSize / 2,
                                       width: viewSize,
                                       height: viewSize)

        collectionView.frame = CGRect(x: imageView.right,
                                      y: view.height / 2 - viewSize / 2,
                                      width: view.width - 12 - 8 - playPauseButton.width - imageView.width - 8,
                                      height: viewSize)
        if PlaybackPresenter.shared.isRepeatCurrentTracks {
            scrollToMiddle()
        }
    }
    
    private func configureCollectionView() {
        view.addSubview(collectionView)
        collectionView.register(TrackLabelCollectionViewCell.self,
                                forCellWithReuseIdentifier: TrackLabelCollectionViewCell.identifier)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.isPagingEnabled = true
        collectionView.backgroundColor = .clear
    }
    
    func configurePlayback(playerState: SPTAppRemotePlayerState) {
        DispatchQueue.main.async {
            self.imageView.image = self.dataSource?.trackImage
            self.reloadCollectionView()
            self.playPauseButton.setImage(UIImage(systemName: playerState.isPaused ? "play.fill" : "pause.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .regular)), for: .normal)
            self.scrollToCorrectIndex()
        }
    }
    
    func scrollToMiddle() {
        collectionView.scrollToItem(at: IndexPath(row: 0, section: 2), at: .left, animated: false)
        lastCollectionViewIndex = 2
    }
    
    func reloadCollectionView() {
        collectionView.reloadData()
    }
    
    func changeRepeatButtonState(isEnabled: Bool) {
        repeatButton.isEnabled = isEnabled
        repeatButton.alpha = isEnabled ? 1 : 0.6
    }
    
    func scrollToCorrectIndex() {
        if !(PlaybackPresenter.shared.canSlideMiniPlayerWindow) {
            self.collectionView.scrollToItem(
                at: IndexPath(
                    row: 0,
                    section: PlaybackPresenter.shared.correctMiniPlayerIndex),
                at: .left,
                animated: false
            )
        }
    }
    
    private func updateCurrentCollectionViewIndex() {
        let width = self.collectionView.width
        let scrollOffset = MiniPlayerViewController.offset.x
        let modulo = scrollOffset.truncatingRemainder(dividingBy: width)
        let tolerance = width / 5
        if modulo < tolerance {
            currentCollectionViewIndex = Int(scrollOffset / width)
        }
    }
    
    func updateRepeatButton(isRepeatEnabled: Bool) {
        repeatButton.tintColor = isRepeatEnabled ? .systemBlue : .gray
    }
    
    // MARK: - Actions
    
    @objc func didTapPauseOrPlay(_ button: UIButton) {
        playerDelegate?.didTapPlayPause()
    }
    
    @objc func didTapRepeatButton(_ button: UIButton) {
        playerDelegate?.didTapRepeatButton()
    }
    
    func changeVisibility(isHidden: Bool) {
        self.collectionView.isHidden = isHidden
        self.playPauseButton.isHidden = isHidden
        self.imageBackgroundView.isHidden = isHidden
        self.imageView.isHidden = isHidden
        self.backgroundBlur.isHidden = isHidden
        self.repeatButton.isHidden = isHidden
    }
}

extension MiniPlayerViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        1
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        dataSource?.viewModels.count ?? 5
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: TrackLabelCollectionViewCell.identifier,
            for: indexPath
        ) as? TrackLabelCollectionViewCell else {
            return UICollectionViewCell()
        }
        
        let viewModel = dataSource?.viewModels[indexPath.section] ??
        TrackLabelCollectionViewCellViewModel(
            trackName: dataSource?.songName ?? "",
            trackArtistName: dataSource?.subtitle ?? "."
        )
        
        cell.configure(with: viewModel)
        return cell
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        updateCurrentCollectionViewIndex()
        
        if !(PlaybackPresenter.shared.canSlideMiniPlayerWindow) {
            // When the windows isn't sliding we need to update the last index so that we know to go forward or backwards
            lastCollectionViewIndex = PlaybackPresenter.shared.correctMiniPlayerIndex
        }
        
        let difference: Int = currentCollectionViewIndex - lastCollectionViewIndex
        
        if difference > 0 {
            if difference > 1 {
                didTapForward()
                didTapForward()
            } else {
                didTapForward()
            }
        } else if difference < 0 {
            if difference < -1 {
                didTapBackward()
                didTapBackward()
            } else {
                didTapBackward()
            }
        }
        
        if PlaybackPresenter.shared.canSlideMiniPlayerWindow {
            scrollToMiddle()
        }
    }
}


extension MiniPlayerViewController: PlayerViewControllerDelegate {    
    func didTapPlayPause() {
        playerDelegate?.didTapPlayPause()
    }
    
    func didTapForward() {
        playerDelegate?.didTapForward()
    }
    
    func didTapBackward() {
        playerDelegate?.didTapBackward()
    }
    
    func didTapRepeatButton() {
        playerDelegate?.didTapRepeatButton()
    }
}
