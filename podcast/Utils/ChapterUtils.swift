//
//  ChapterHandler.swift
//  podcast
//
//  Created by Matt Wittbrodt on 6/2/25.
//

import Foundation

struct ChapterResponse: Decodable {
    let version: String
    let chapters: [ChapterInfo]
}

struct ChapterInfo: Hashable, Codable {
    let startTime: Int16
    let title: String?
    let img: String?
}

func decodeChapters(urlString: String) async throws -> ChapterResponse {
    guard let url = URL(string: urlString) else {
        throw ChapterError.badUrl(urlString)
    }
    
    let decoder = JSONDecoder()
    var request = URLRequest(url: url)
    request.httpMethod = "GET"

    guard let (data, _) = try? await URLSession.shared.data(for: request) else {
        throw ChapterError.noData(urlString)
    }
    
    do {
        let decodedChapters = try decoder.decode(ChapterResponse.self, from: data)
        return decodedChapters
    } catch {
        throw ChapterError.decoderError(urlString,"\(error)")
    }
}
