//
//  FeaturedPlaylistCollectionViewCell.swift
//  Spotify
//
//  Created by Carson Gross on 7/2/23.
//

import UIKit

class FeaturedPlaylistCollectionViewCell: UICollectionViewCell {
    static let identifier = "FeaturedPlaylistCollectionViewCell"
    
    private let playlistCoverImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "photo")
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    private let playlistNameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .bold)
        label.textColor = .label
        label.numberOfLines = 0
        return label
    }()
    
    private let totalTracksLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(playlistCoverImageView)
        contentView.addSubview(playlistNameLabel)
        contentView.addSubview(totalTracksLabel)
        contentView.clipsToBounds = true
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let imageSize = contentView.width - 12
        playlistCoverImageView.frame = CGRect(x: (contentView.width-imageSize) / 2,
                                              y: 0,
                                              width: imageSize,
                                              height: imageSize)
        
        playlistNameLabel.frame = CGRect(x: playlistCoverImageView.left,
                                         y: playlistCoverImageView.bottom + 8,
                                         width: contentView.width - 6,
                                         height: 15)
        
        totalTracksLabel.frame = CGRect(x: playlistCoverImageView.left,
                                        y: playlistNameLabel.bottom + 3,
                                        width: contentView.width - 6,
                                        height: 15)
        
        
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        playlistNameLabel.text = nil
        totalTracksLabel.text = nil
        playlistCoverImageView.image = nil
    }
    
    func configure(with viewModel: FeaturedPlaylistCellViewModel) {
        playlistNameLabel.text = viewModel.name
        totalTracksLabel.text = "\(viewModel.tracks) tracks"
        playlistCoverImageView.sd_setImage(with: viewModel.artworkURL)
    }
}
