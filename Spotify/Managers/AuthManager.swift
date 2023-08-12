//
//  AuthManager.swift
//  Spotify
//
//  Created by Carson Gross on 6/25/23.
//

import Foundation

final class AuthManager {
    static let shared = AuthManager()
    
    private var refreshingToken = false
    
    public var currentUserId: String?
    
    struct Constants {
        static let tokenAPIURL = "https://accounts.spotify.com/api/token"
        static let accessTokenKey = "access-token-key"
        static let redirectUri = URL(string:"spotify-ios-quick-start://")!
        static let spotifyClientId = ""
        static let spotifyClientSecretKey = ""
        static let scopes: SPTScope = [
                                    .userReadEmail, .userReadPrivate,
                                    .userReadPlaybackState, .userModifyPlaybackState, .userReadCurrentlyPlaying,
                                    .streaming, .appRemoteControl,
                                    .playlistReadCollaborative, .playlistModifyPublic, .playlistReadPrivate, .playlistModifyPrivate,
                                    .userLibraryModify, .userLibraryRead,
                                    .userTopRead, .userReadPlaybackState, .userReadCurrentlyPlaying,
                                    .userFollowRead, .userFollowModify,
                                ]
        static let stringScopes = [
                                "user-read-email", "user-read-private",
                                "user-read-playback-state", "user-modify-playback-state", "user-read-currently-playing",
                                "streaming", "app-remote-control",
                                "playlist-read-collaborative", "playlist-modify-public", "playlist-read-private", "playlist-modify-private",
                                "user-library-modify", "user-library-read",
                                "user-top-read", "user-read-playback-position", "user-read-recently-played",
                                "user-follow-read", "user-follow-modify",
                            ]
    }
    
    private init() {}
    
    public var signInURL: URL? {
        let base = "https://accounts.spotify.com/authorize"
        let string = "\(base)?response_type=code&client_id=\(Constants.spotifyClientId)&scope=\(Constants.stringScopes)&redirect_uri=\(Constants.redirectUri)&show_dialog=TRUE"
        return URL(string: string)
    }
    
    var isSignedIn: Bool {
        return accessToken != nil
    }
    
    public var accessToken: String? {
        return UserDefaults.standard.string(forKey: "access_token")
    }
    
    private var refreshToken: String? {
        return UserDefaults.standard.string(forKey: "refresh_token")
    }
    
    private var tokenExpirationDate: Date? {
        return UserDefaults.standard.object(forKey: "expirationDate") as? Date
    }
    
    private var shouldRefreshToken: Bool {
        guard let expirationDate = tokenExpirationDate else {
            return false
        }
        let currentDate = Date()
        let fiveMinutes: TimeInterval = 300
        return currentDate.addingTimeInterval(fiveMinutes) >= expirationDate
    }
    
    public func exchangeCodeForToken(
        code: String,
        completion: @escaping (Bool) -> Void
    ) {
        // Get Token
        guard let url = URL(string: Constants.tokenAPIURL) else {
            return
        }
        
        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "grant_type",
                         value: "authorization_code"),
            URLQueryItem(name: "code",
                         value: code),
            URLQueryItem(name: "redirect_uri",
                         value: Constants.redirectUri.absoluteString),
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded",
                         forHTTPHeaderField: "Content-Type")
        request.httpBody = components.query?.data(using: .utf8)
        
        let basicToken = Constants.spotifyClientId+":"+Constants.spotifyClientSecretKey
        let data = basicToken.data(using: .utf8)
        guard let base64String = data?.base64EncodedString() else {
            print("Failure to get base64")
            completion(false)
            return
        }
        request.setValue("Basic \(base64String)",
                         forHTTPHeaderField: "Authorization")
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            guard let data = data, error == nil else {
                completion(false)
                return
            }
            
            do {
                let result = try JSONDecoder().decode(AuthResponse.self, from: data)
                self?.cacheToken(result: result)
                completion(true)
            } catch {
                print(error.localizedDescription)
                completion(false)
            }
        }
        task.resume()
    }
    
    private var onRefreshBlocks = [((String) -> Void)]()
    
    /// Supplies valid token to be used with API Calls
    public func withValidToken(completion: @escaping (String) -> Void) {
        guard !refreshingToken else {
            // Append the completion
            onRefreshBlocks.append(completion)
            return
        }
        
        if shouldRefreshToken {
            // Refresh
            refreshIfNeeded { [weak self] success in
                if let token = self?.accessToken, success {
                    completion(token)
                }
            }
        } else if let token = accessToken {
            completion(token)
        }
    }
    
    public func refreshIfNeeded(completion: ((Bool) -> Void)?) {
        guard !refreshingToken else {
            return
        }
        
        guard shouldRefreshToken else {
            completion?(true)
            return
        }
        
        guard let refreshToken = self.refreshToken else {
            return
        }
        
        // Get Token
        guard let url = URL(string: Constants.tokenAPIURL) else {
            return
        }
        
        refreshingToken = true
        
        // Refresh the token
        
        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "grant_type",
                         value: "refresh_token"),
            URLQueryItem(name: "refresh_token",
                         value: refreshToken),
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded",
                         forHTTPHeaderField: "Content-Type")
        request.httpBody = components.query?.data(using: .utf8)
        
        let basicToken = Constants.spotifyClientId+":"+Constants.spotifyClientSecretKey
        let data = basicToken.data(using: .utf8)
        guard let base64String = data?.base64EncodedString() else {
            print("Failure to get base64")
            completion?(false)
            return
        }
        request.setValue("Basic \(base64String)",
                         forHTTPHeaderField: "Authorization")
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            self?.refreshingToken = false
            guard let data = data, error == nil else {
                completion?(false)
                return
            }
            
            do {
                let result = try JSONDecoder().decode(AuthResponse.self, from: data)
                
                self?.onRefreshBlocks.forEach { $0(result.access_token) }
                self?.onRefreshBlocks.removeAll()
                self?.cacheToken(result: result)
                completion?(true)
            } catch {
                print(error.localizedDescription)
                completion?(false)
            }
        }
        task.resume()
        
    }
    
    private func cacheToken(result: AuthResponse) {
        UserDefaults.standard.setValue(result.access_token,
                                       forKey: "access_token")
        if let refresh_token = result.refresh_token {
            UserDefaults.standard.setValue(refresh_token,
                                           forKey: "refresh_token")
        }
        UserDefaults.standard.setValue(Date().addingTimeInterval(TimeInterval(result.expires_in)),
                                       forKey: "expirationDate")
    }
    
    public func getCurrentUser() {
        guard UserDefaults.standard.string(forKey: "id") == nil else {
            currentUserId = UserDefaults.standard.string(forKey: "id")
            return
        }
        
        APICaller.shared.getCurrentUserProfile { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let model):
                    self?.currentUserId = model.id
                    UserDefaults.standard.set(self?.currentUserId,
                                              forKey: "id")
                case .failure(let error):
                    print(error.localizedDescription)
                }
            }
        }
    }
    
    public func signOut(completion: (Bool) -> Void) {
        UserDefaults.standard.set(nil,
                                  forKey: "id")
        UserDefaults.standard.setValue(nil,
                                       forKey: "access_token")
        UserDefaults.standard.setValue(nil,
                                       forKey: "refresh_token")
        UserDefaults.standard.setValue(nil,
                                       forKey: "expirationDate")
        completion(true)
    }
}
