//
//  DateUtils.swift
//  Planecast
//
//  Created by Matt Wittbrodt on 7/14/26.
//

import Foundation

extension Date {
    func bookmarkFormatted() -> String {
        let calendar = Calendar.current
        let now = Date()
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"
        let timeString = timeFormatter.string(from: self)
        
        let dayFormatter = DateFormatter()
        
        if calendar.isDate(self, equalTo: now, toGranularity: .weekOfYear) {
            // Same week — "Wednesday at 3:45 PM"
            dayFormatter.dateFormat = "EEEE"
            return "\(dayFormatter.string(from: self)) at \(timeString)"
            
        } else if calendar.isDate(self, equalTo: now, toGranularity: .year) {
            // Same year — "June 14 at 3:45 PM"
            dayFormatter.dateFormat = "MMMM d"
            return "\(dayFormatter.string(from: self)) at \(timeString)"
            
        } else {
            // Older than a year — "June 14, 2026"
            dayFormatter.dateFormat = "MMMM d, yyyy"
            return dayFormatter.string(from: self)
        }
    }
}
