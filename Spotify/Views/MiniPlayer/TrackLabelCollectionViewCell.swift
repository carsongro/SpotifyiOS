//
//  TrackLabelCollectionViewCell.swift
//  Spotify
//
//  Created by Carson Gross on 7/11/23.
//

import UIKit

class TrackLabelCollectionViewCell: UICollectionViewCell {
    static let identifier = "TrackLabelCollectionViewCell"
    
    private let trackNameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: UIFont.systemFontSize, weight: .heavy)
        label.textColor = .label
        label.textAlignment = .left
        label.layer.masksToBounds = true
        label.sizeToFit()
        return label
    }()
    
    private let artistNameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: UIFont.systemFontSize, weight: .light)
        label.textColor = .label
        label.textAlignment = .left
        label.layer.masksToBounds = true
        label.sizeToFit()
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .clear
        backgroundColor = .clear
        contentView.addSubviews(trackNameLabel, artistNameLabel)
        contentView.clipsToBounds = true
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let viewSize: CGFloat = 44
        trackNameLabel.frame = CGRect(x: contentView.left + 18,
                                      y: contentView.height / 2 - viewSize / 2,
                                      width: contentView.width - 10 - 8 - viewSize,
                                      height: viewSize / 2)

        artistNameLabel.frame = CGRect(x: trackNameLabel.left,
                                       y: trackNameLabel.bottom,
                                       width: contentView.width - 10 - 8 - viewSize,
                                       height: viewSize / 2)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        trackNameLabel.text = nil
        artistNameLabel.text = nil
    }
    
    func configure(with viewModel: TrackLabelCollectionViewCellViewModel) {
        trackNameLabel.text = viewModel.trackName
        artistNameLabel.text = viewModel.trackArtistName
    }
}
