//
//  Chapter+helper.swift
//  podcast
//
//  Created by Matt Wittbrodt on 5/31/25.
//

import Foundation
import CoreData

extension Chapter {
    
    @discardableResult
    convenience init(imageData: Data?,
                     imageUrl: String?,
                     startTime: Int16,
                     title: String?,
                     context: NSManagedObjectContext) {
        
        Thread.callStackSymbols.forEach { print($0) }
        self.init(context: context)
        Thread.callStackSymbols.forEach { print($0) }
        self.imageData = imageData
        self.title = title
        self.imageUrl = imageUrl
        self.startTime = startTime
    }
    
    static func fromWeb(chapter: ChapterInfo, context: NSManagedObjectContext) -> Chapter {
        
        let entity = NSEntityDescription.entity(forEntityName: "Chapter", in: context)!
        let chapterObj = Chapter(entity: entity, insertInto: context)
        
        chapterObj.imageUrl = chapter.img
        chapterObj.startTime = Int16(chapter.startTime)
        chapterObj.title = chapter.title
        
        if let imgData = chapter.imgData {
            chapterObj.imageData = imgData
        }
        
        return chapterObj
    }
    
//    static var example: Chapter {
//        let context = PersistenceController.shared.container.viewContext
//        return Chapter(
//            imageData: nil,
//            imageUrl: "https://static.noagendaartgenerator.com/thumbnails/2025/05/blue-acorn-best-of-memorial-day-edition_5KF3VssP.jpg",
//            startTime: 315,
//            title: "Sample Chapter",
//            context: context)
//    }
}

