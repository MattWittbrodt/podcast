//
//  Errors.swift
//  podcast
//
//  Created by Matt Wittbrodt on 6/28/26.
//

import Foundation

enum RepositoryError: LocalizedError {
    case notFound
}

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
    case noData(String, String)
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
