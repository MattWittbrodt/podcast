//
//  Errors.swift
//  podcast
//
//  Created by Matt Wittbrodt on 5/15/25.
//

import Foundation

enum PodcastFetchError: Error {
    case badUpdate(String)
}

enum ImageError: Error {
    case badUrl(String)
    case fetchImage(Error)
}

enum ChapterError: Error {
    case badChapters(String)
    case badUrl(String)
    case noData(String)
    case decoderError(String,String)
}

enum DownloadError: Error {
    case invalidURL(String)
    case invalidImageURL(String)
    case invalidResponse
    case fileAlreadyExists
    case fileMoveFailed
    case downloadFailed(Error)
    case deleteFailed
}

enum RSSParserError: Error {
    case invalidUrl(String)
    case parseError(String)
}
