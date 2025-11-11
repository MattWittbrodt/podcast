//
//  downloadDataResponse.swift
//  Planecast
//
//  Created by Matt Wittbrodt on 8/14/25.
//

import Foundation
import CoreData

class chapterDataUtils {
    
    static func processChapter(chapterInfo: ChapterInfo, context: NSManagedObjectContext) async -> Chapter {
        let mapped = Chapter.fromWeb(chapter: chapterInfo, context: context)
        let imageData: Data? = await {
            guard let url = chapterInfo.img else { print("No chapter img"); return nil }
            return try? await loadImageFromWeb(url: url)
        }()
        if let imageData = imageData {
            mapped.imageData = imageData
        }
        return mapped
    }
}
