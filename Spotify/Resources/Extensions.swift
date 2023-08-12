//
//  Extensions.swift
//  Spotify
//
//  Created by Carson Gross on 6/26/23.
//

import Foundation
import UIKit
import SwiftUI

extension UIView {
    var width: CGFloat {
        frame.size.width
    }
    
    var height: CGFloat {
        frame.size.height
    }
    
    var left: CGFloat {
        frame.origin.x
    }
    
    var right: CGFloat {
        left + width
    }
    
    var top: CGFloat {
        frame.origin.y
    }
    
    var bottom: CGFloat {
        top + height
    }
    
    func addSubviews(_ view: UIView...) {
        view.forEach({
            addSubview($0)
        })
    }
}

extension DateFormatter {
    static let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYY-MM-dd"
        return dateFormatter
    }()
    
    static let displayDateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        return dateFormatter
    }()
    
    static let trackDateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYY-dd-MM'T'HH:HH:SS'Z'"
        return dateFormatter
    }()
}

extension String {
    static func formattedDate(string: String) -> String {
        guard let date = DateFormatter.dateFormatter.date(from: string) else {
            return string
        }
        return DateFormatter.displayDateFormatter.string(from: date)
    }
}

extension Notification.Name {
    static let albumSavedNotification = Notification.Name("albumSavedNotification")
    static let selectedTrackNotification = Notification.Name("selectedTrackNotification")
}

extension Animation {
    static var edgeBounce: Animation {
        Animation.timingCurve(0.27, 0.13, 0.09, 1)
    }
    
    static func edgeBounce(duration: TimeInterval = 0.2) -> Animation {
        Animation.timingCurve(0.27, 0.13, 0.09, 1, duration: duration)
    }
    
    static var easeInOutBack: Animation {
        Animation.timingCurve(0.33, -0.28, 0.42, 0.96)
    }
    
    static func easeInOutBack(duration: TimeInterval = 0.2) -> Animation {
        Animation.timingCurve(0.33, -0.28, 0.42, 0.96, duration: duration)
    }
}
