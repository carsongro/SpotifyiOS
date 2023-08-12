//
//  PlaybackPresenter.swift
//  Spotify
//
//  Created by Carson Gross on 7/4/23.
//

import Foundation
import UIKit
import AVFoundation

protocol PlayerDataSource: AnyObject {
    var songName: String? { get }
    var subtitle: String? { get }
    var trackImage: UIImage? { get }
    var viewModels: [TrackLabelCollectionViewCellViewModel?] { get }
}


//TODO: if current playlist id is not different from the one they selected then don't load new tracks
//TODO: Get info from userdefaults to load from the start
final class PlaybackPresenter: NSObject {
    static let shared = PlaybackPresenter()
    
    // MARK: - Spotify Authorization & Configuration
    
    public var responseCode: String? {
        didSet {
            AuthManager.shared.exchangeCodeForToken(
                code: responseCode ?? ""
            ) { success in
                if success {
                    DispatchQueue.main.async {
                        self.appRemote.connectionParameters.accessToken = AuthManager.shared.accessToken
                        self.appRemote.connect()
                    }
                } else {
                    print("Failure to exchange code for token")
                }
            }
        }
    }
    
    public lazy var appRemote: SPTAppRemote = {
        let appRemote = SPTAppRemote(configuration: configuration, logLevel: .debug)
        appRemote.connectionParameters.accessToken = self.accessToken
        return appRemote
    }()
    
    public lazy var configuration: SPTConfiguration = {
        let configuration = SPTConfiguration(clientID: AuthManager.Constants.spotifyClientId, redirectURL: AuthManager.Constants.redirectUri)
        // Set the playURI to a non-nil value so that Spotify plays music after authenticating
        // otherwise another app switch will be required
        configuration.playURI = ""
        // Set these url's to your backend which contains the secret to exchange for an access token
        // You can use the provided ruby script spotify_token_swap.rb for testing purposes
        configuration.tokenSwapURL = URL(string: "http://localhost:1234/swap")
        configuration.tokenRefreshURL = URL(string: "http://localhost:1234/refresh")
        return configuration
    }()
    
    
    public lazy var sessionManager: SPTSessionManager? = {
        let manager = SPTSessionManager(configuration: configuration, delegate: self)
        return manager
    }()
    
    var accessToken = UserDefaults.standard.string(forKey: AuthManager.Constants.accessTokenKey) {
        didSet {
            let defaults = UserDefaults.standard
            defaults.set(accessToken, forKey: AuthManager.Constants.accessTokenKey)
        }
    }
    public var lastPlayerState: SPTAppRemotePlayerState?
    public var currentSPTTrack: SPTAppRemoteTrack? {
        lastPlayerState?.track
    }
    
    //TODO: Save the track info of the track and load that up on start
    private var loadedTracks = [AudioTrack]()
    
    private var recommendedTracks = [AudioTrack]()
    
    private var currentImage: UIImage?
    private var currentTrack: AudioTrack? {
        if !loadedTracks.isEmpty {
            return loadedTracks[index]
        }
        return nil
    }
    
    private var currentPlaylist: Playlist?
    private var pageIsLoaded = [Int: Bool]() // The offset [(100, 200...): (already in tracks)]
    private var currentPage = 0
    private var numberOfPages = 0
    private var pageSize = 10
    private var tracksAddedAtEnd = 0
    
    private var trueIndex = 0 {
        didSet {
            if trueIndex > 0 {
                currentPage = Int(floor(Double(index + trueIndex) / Double(pageSize)))
            } else {
                currentPage = (numberOfPages) + Int(floor(Double(trueIndex) / Double(pageSize)))
            }
        }
    }
    
    var playerVC: PlayerViewController?
    private var miniPlayerVC: MiniPlayerViewController?
    
    private var index = 0
    
    /// finishedFirstLoop is false when the user hasn't looped through their playlist
    /// at leats once so that there is a "wall" that they can't swipe backward
    /// but once they finished the first loop finishedFirstLoop is now true
    /// and they can go backward infinitely
    private var repeatCurrentTracks = false
    public var canSlideMiniPlayerWindow: Bool {
        index >= 2 || repeatCurrentTracks
    }
    
    /// indexesToShow is a window with a count of 5
    /// that treats tracks as a circular array.
    /// However, if the user hasn't yet completed their first loop
    /// then its only circular when moving forward but not backward,
    /// if they have completed the first loop then they can go backwards
    private var indexesToShow = [Int](repeating: 0, count: 5)
    var miniPlayerTracks = [TrackLabelCollectionViewCellViewModel?](repeating: nil, count: 5) // Should always be length 5
    
    
    public var isRepeatCurrentTracks: Bool {
        repeatCurrentTracks
    }
    
    public var correctMiniPlayerIndex: Int {
        canSlideMiniPlayerWindow ? 2 : index
    }
    
    private var tracksCount: Int {
        currentPlaylist?.tracks.total ?? 0
    }
    
    private var leftOffsetPointer = 0
    private var rightOffsetPointer = 0
    
    //MARK: - Methods
    
    private func setMiniPlayerTracks() {
        let leftLimit = max(index - 2, 0)
        
        if index < 2 && canSlideMiniPlayerWindow { // repeat is on and we can loop to the back of tracks
            for (idx, trackIdx) in ((loadedTracks.count - 2) + index...loadedTracks.count + (2 + index)).enumerated() {
                indexesToShow[idx] = trackIdx % loadedTracks.count
            }
        } else { // repeat is off and we want to stop the user from circling back
            for (idx, trackIdx) in (leftLimit...index + 2).enumerated() {
                indexesToShow[idx] = trackIdx % loadedTracks.count
            }
        }
        
        DispatchQueue.main.async {
            self.indexesToShow.enumerated().forEach { idx, val in
                self.miniPlayerTracks[idx] = TrackLabelCollectionViewCellViewModel(
                    trackName: self.loadedTracks[val].name,
                    trackArtistName: (self.loadedTracks[val].artists.compactMap({ $0.name })).joined(separator: ", ")
                )
            }
            
            if !self.repeatCurrentTracks && self.index >= self.loadedTracks.count - 3 {
                self.miniPlayerTracks[4] = TrackLabelCollectionViewCellViewModel(trackName: ".",
                                                                                 trackArtistName: "")
            }
            
            self.miniPlayerVC?.reloadCollectionView()
        
            if self.canSlideMiniPlayerWindow { // repeat is on and we can loop to the back of tracks
                self.miniPlayerVC?.scrollToMiddle()
            } else {
                self.miniPlayerVC?.scrollToCorrectIndex()
            }
        }
        
    }
    
    func startPlayback(
        tracks: [AudioTrack],
        setIndex: Int? = nil,
        fromPlaylist: Playlist? = nil
    ) {
        miniPlayerVC?.changeVisibility(isHidden: false)
        miniPlayerVC?.changeRepeatButtonState(isEnabled: true)
        
        if fromPlaylist == nil || currentPlaylist?.id != fromPlaylist?.id || tracks.count > loadedTracks.count {
            resetTrackPagination()
            currentPlaylist = fromPlaylist
            self.loadedTracks = tracks
            getLoadedOffsets()
            leftOffsetPointer = tracksCount // set initial left offset
            self.indexesToShow = [Int](repeating: 0, count: 5)
        }
        
        if let setIndex = setIndex {
            index = setIndex
        } else {
            index = 0
        }
        
        clearRecommendations()
        getRecommendedTracksIfNeeded()
        
        if index == 0 {
            loadAdditionalTracks(at: numberOfPages, goingForward: false, isInitialLoad: true)
            
            miniPlayerVC?.reloadCollectionView()
            
            if canSlideMiniPlayerWindow {
                miniPlayerVC?.scrollToMiddle()
            } else {
                miniPlayerVC?.scrollToCorrectIndex()
            }
        }
                
        guard let currentTrack = currentTrack else {
            return
        }
        if !appRemote.isConnected {
            configuration.playURI = currentTrack.uri
            connectToSpotify()
        }
    }
    
    private func getLoadedOffsets() {
        guard tracksCount > pageSize else {
            pageIsLoaded[0] = true
            return
        }
        
        numberOfPages = Int(floor(Double(tracksCount) / Double(pageSize)))

        for page in 1...numberOfPages {
            pageIsLoaded[page] = loadedTracks.count >= page * pageSize
        }
        
        rightOffsetPointer = numberOfPages
    }
    
    private func update(playerState: SPTAppRemotePlayerState) {
        if lastPlayerState?.track.uri != playerState.track.uri || lastPlayerState == nil {
            APICaller.shared.fetchArtwork(for: playerState.track) { [weak self] result in
                switch result {
                case .success(let image):
                    DispatchQueue.main.async {
                        self?.currentImage = image
                        self?.lastPlayerState = playerState
                        self?.miniPlayerVC?.configurePlayback(playerState: playerState)
                    }
                case .failure(let error):
                    print(error.localizedDescription)
                }
            }
        }
        DispatchQueue.main.async {
            self.lastPlayerState = playerState
            print(playerState.track)
            self.miniPlayerVC?.configurePlayback(playerState: playerState)
        }
    }
    
    public func configureAppRemote() {
        appRemote.connectionParameters.accessToken = self.accessToken
        appRemote.delegate = self
        appRemote.playerAPI?.delegate = self
        appRemote.playerAPI?.subscribe(toPlayerState: { (success, error) in
            if let error = error {
                print("Error subscribing to player state:" + error.localizedDescription)
            }
        })
    }
    
    public func connectToSpotify() {
        guard let sessionManager = sessionManager else { return }
        sessionManager.initiateSession(with: AuthManager.Constants.scopes, options: .clientOnly)
    }
    
    public func setMiniPlayerViewController(with vc: MiniPlayerViewController) {
        self.miniPlayerVC = vc
        self.miniPlayerVC?.changeVisibility(isHidden: !appRemote.isConnected)
    }
    
    private func didTapRepeat() {
        repeatCurrentTracks.toggle()
        
        DispatchQueue.main.async {
            self.clearRecommendations()
            self.miniPlayerVC?.updateRepeatButton(isRepeatEnabled: self.repeatCurrentTracks)
            if !self.loadedTracks.isEmpty {
                
                if self.repeatCurrentTracks || self.index >= 2 {
                    self.miniPlayerVC?.scrollToMiddle()
                } else if !self.canSlideMiniPlayerWindow {
                    self.miniPlayerVC?.scrollToCorrectIndex()
                }
                
                self.setMiniPlayerTracks()
            }
        }
        
        getRecommendedTracksIfNeeded(autoPlayTrack: false)
    }
    
    private func clearRecommendations() {
        if !recommendedTracks.isEmpty {
            loadedTracks.removeLast(recommendedTracks.count)
            recommendedTracks.removeAll()
        }
    }
    
    private func loadAdditionalTracks(at page: Int, goingForward: Bool, isInitialLoad: Bool = false) {
        let offset = page * pageSize
        
        APICaller.shared.getPlaylistTracksAtOffset(
            playlistId: currentPlaylist?.id ?? "",
            offset: offset
        ) { [weak self] result in
            guard let strongSelf = self else {
                return
            }
            
            switch result {
            case .success(let model):
                let newTracks = model.items.compactMap { $0.track }
                DispatchQueue.main.async {
                    strongSelf.loadedTracks.insert(contentsOf:newTracks,
                                                   at: strongSelf.loadedTracks.count - strongSelf.tracksAddedAtEnd)
                    
                    if goingForward {
                        strongSelf.pageIsLoaded[strongSelf.leftOffsetPointer] = true
                        strongSelf.leftOffsetPointer += 1
                    } else {
                        strongSelf.pageIsLoaded[strongSelf.rightOffsetPointer] = true
                        strongSelf.rightOffsetPointer -= 1
                        if !isInitialLoad {
                            strongSelf.index += newTracks.count // Adjust the index to account for the new tracks
                        }
                    }
                    
                    strongSelf.tracksAddedAtEnd += newTracks.count
                    
                    if isInitialLoad && strongSelf.tracksAddedAtEnd < strongSelf.pageSize {
                        /// if the lat page is only a couple of tracks, we need to make sure that the miniPlayer
                        /// displays the correct previous tracks, so we may need to get more
                        strongSelf.loadAdditionalTracks(at: strongSelf.rightOffsetPointer,
                                                        goingForward: false,
                                                        isInitialLoad: true)
                    }
                    
                    strongSelf.setMiniPlayerTracks()
                    
//                    strongSelf.loadedTracks.enumerated().forEach({ idx, track in
//                        print("\(track.name) \(idx)")
//                    })
                }
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
    
    private func resetTrackPagination() {
        leftOffsetPointer = 0
        rightOffsetPointer = 0
        loadedTracks.removeAll()
        pageIsLoaded.removeAll()
        tracksAddedAtEnd = 0
    }
    
    private func getRecommendedTracks(autoPlayTrack: Bool = true) {
        // Recommended Tracks
        APICaller.shared.getRecommendedGenres { result in
            switch result {
            case .success(let model):
                let genres = model.genres
                var seeds = Set<String>()
                while seeds.count < 5 {
                    if let random = genres.randomElement() {
                        seeds.insert(random)
                    }
                }
                
                APICaller.shared.getRecommendations(genres: seeds) { [weak self] recommendedResult in
                    
                    switch recommendedResult {
                    case .success(let model):
                        DispatchQueue.main.async {
                            guard let self = self else { return }
                            self.recommendedTracks.append(contentsOf: model.tracks)
                            self.loadedTracks.append(contentsOf: self.recommendedTracks)
                            self.setMiniPlayerTracks()
                            if autoPlayTrack {
                                self.appRemote.playerAPI?.play(self.loadedTracks[self.index].uri)
                            }
                        }
                    case .failure(let error):
                        print(error.localizedDescription)
                    }
                }
                
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
    
    private func getRecommendedTracksIfNeeded(autoPlayTrack: Bool = true) {
        if pageIsLoaded[numberOfPages] ?? false &&
            !repeatCurrentTracks &&
            index >= loadedTracks.count - 3 {
            getRecommendedTracks(autoPlayTrack: autoPlayTrack)
        } else {
            setMiniPlayerTracks()
            if autoPlayTrack {
                appRemote.playerAPI?.play(loadedTracks[index].uri)
            }
        }
    }
}

//MARK: - PlayerViewControllerDelegate

extension PlaybackPresenter: PlayerViewControllerDelegate {
    
    func didTapPlayPause() {
        if let lastPlayerState = lastPlayerState, lastPlayerState.isPaused {
            appRemote.playerAPI?.resume(nil)
        } else {
            appRemote.playerAPI?.pause(nil)
        }
    }
    
    func didTapForward() {
        guard !loadedTracks.isEmpty else {
            appRemote.playerAPI?.skip(toNext: nil)
            return
        }
        
        trueIndex += 1
        
        if canSlideMiniPlayerWindow {
            /// Populate the middle collectionView cell with the next song's data
            /// then reset the scroll so that it appears like we are staying on the next cell
            miniPlayerTracks[2] = miniPlayerTracks[3]
            miniPlayerVC?.reloadCollectionView()
        }
    
        if index == loadedTracks.count - 1 && repeatCurrentTracks {
            index = 0
        } else {
            index += 1
        }
        
        if currentPage + 1 == leftOffsetPointer && recommendedTracks.isEmpty {
            loadAdditionalTracks(at: leftOffsetPointer, goingForward: true)
        }
        
        getRecommendedTracksIfNeeded()
        
        miniPlayerVC?.changeRepeatButtonState(isEnabled: index < loadedTracks.count - recommendedTracks.count)
        
    }
    
    func didTapBackward() {
        guard !loadedTracks.isEmpty else {
            appRemote.playerAPI?.skip(toPrevious: nil)
            return
        }
        
        if canSlideMiniPlayerWindow {
            /// Populate the middle collectionView cell with the previous song's data
            /// then reset the scroll so that it appears like we are staying on the previous cell
            miniPlayerTracks[2] = miniPlayerTracks[1]
            miniPlayerVC?.reloadCollectionView()
        }
        
        trueIndex -= 1
        if currentPage - 1 == rightOffsetPointer && recommendedTracks.isEmpty {
            loadAdditionalTracks(at: rightOffsetPointer, goingForward: false)
        }
        
        if index == 0 && repeatCurrentTracks {
            index = loadedTracks.count - 1
        } else {
            index -= 1
        }
        
        miniPlayerVC?.changeRepeatButtonState(isEnabled: index < loadedTracks.count - recommendedTracks.count)
        
        setMiniPlayerTracks()
        appRemote.playerAPI?.play(loadedTracks[index].uri)
    }
    
    func didTapRepeatButton() {
        didTapRepeat()
    }
}

//MARK: - PlayerDataSource

extension PlaybackPresenter: PlayerDataSource {
    var songName: String? {
        currentSPTTrack?.name
    }
    
    var subtitle: String? {
        currentSPTTrack?.artist.name
    }
    
    var trackImage: UIImage? {
        currentImage
    }
    
    var viewModels: [TrackLabelCollectionViewCellViewModel?] {
        miniPlayerTracks
    }
}

// MARK: - SPTAppRemoteDelegate

extension PlaybackPresenter: SPTAppRemoteDelegate {
    func appRemoteDidEstablishConnection(_ appRemote: SPTAppRemote) {
        appRemote.playerAPI?.delegate = self
        appRemote.playerAPI?.subscribe(toPlayerState: { (success, error) in
            if let error = error {
                print("Error subscribing to player state:" + error.localizedDescription)
            }
        })
        fetchPlayerState()
    }
    
    func appRemote(_ appRemote: SPTAppRemote, didDisconnectWithError error: Error?) {
        lastPlayerState = nil
    }
    
    func appRemote(_ appRemote: SPTAppRemote, didFailConnectionAttemptWithError error: Error?) {
        lastPlayerState = nil
    }
}

// MARK: - SPTAppRemotePlayerAPIDelegate
extension PlaybackPresenter: SPTAppRemotePlayerStateDelegate {
    func playerStateDidChange(_ playerState: SPTAppRemotePlayerState) {
//        debugPrint("Spotify Track name: %@", playerState.track.name)
        update(playerState: playerState)
    }
}

// MARK: - SPTSessionManagerDelegate
extension PlaybackPresenter: SPTSessionManagerDelegate {
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
        appRemote.connectionParameters.accessToken = session.accessToken
        appRemote.connect()
    }
    
    private func presentAlertController(title: String, message: String, buttonTitle: String) {
        DispatchQueue.main.async {
            let controller = UIAlertController(title: title, message: message, preferredStyle: .alert)
            let action = UIAlertAction(title: buttonTitle, style: .default, handler: nil)
            controller.addAction(action)
            self.miniPlayerVC?.present(controller, animated: true)
        }
    }
}

// MARK: - Networking
extension PlaybackPresenter {
    func fetchPlayerState() {
        appRemote.playerAPI?.getPlayerState({ [weak self] (playerState, error) in
            if let error = error {
                print("Error getting player state:" + error.localizedDescription)
            } else if let playerState = playerState as? SPTAppRemotePlayerState {
                self?.update(playerState: playerState)
                self?.miniPlayerVC?.changeVisibility(isHidden: playerState.track.uri == "")
            }
        })
    }
}
