//
//  PodcastIndexAPI.swift
//  podcast
//
//  Created by Matt Wittbrodt on 11/12/25.
//

import Foundation
import CryptoKit

enum SearcherError: Error {
    case invalidURL(String)
    case invalidResponse(String)
    case decodingError(String)
}

struct PodcastIndexInfo: Identifiable, Hashable, Codable, PresentationPodcast {
    let id: Int
    let title: String
    let image: String
    let author: String
    let description: String
    let url: String
    
    func rssUrl() -> String { url }
}

extension PodcastIndexInfo {
        
    static var example: PodcastIndexInfo {
        PodcastIndexInfo (
            id: 41504,
            title: "No Agenda Show",
            image: "https://noagendaassets.com/enc/1760304785.269_na-1807-art-feed.jpg",
            author: "Adam Curry & John C. Dvorak",
            description: "A show about politics with No Agenda, by Adam Curry and John C. Dvorak",
            url: "http://feed.nashownotes.com/rss.xml"
        )
    }
}

struct SearchResponses: Codable {
    let feeds: [PodcastIndexInfo]
}

protocol PodcastSearchService {
    func searchByTerm(term: String) async throws -> [PodcastIndexInfo]
}

class PodcastIndexAPI: PodcastSearchService {
    private var baseURL: String = "https://api.podcastindex.org/api/1.0/"
    private var API_KEY = "3SGJBHDZ3RCWT7HFLJSW"
    private var API_SECRET = "a5qfGcrZkQu^rMYax8d2^US#J^yXXwHW7fg9fGXd"
    
    func createRequest(url: URL) -> URLRequest {
        let timeInSeconds: TimeInterval = Date().timeIntervalSince1970
        let apiHeaderTime = Int(timeInSeconds)
        let dataForHash = self.API_KEY + self.API_SECRET + "\(apiHeaderTime)"
        let inputData = Data(dataForHash.utf8)
        let hashed = Insecure.SHA1.hash(data: inputData)
        let hashString = hashed.compactMap { String(format: "%02x", $0) }.joined()
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue( "\(apiHeaderTime)", forHTTPHeaderField: "X-Auth-Date")
        request.addValue( API_KEY, forHTTPHeaderField: "X-Auth-Key")
        request.addValue( hashString, forHTTPHeaderField: "Authorization")
        request.addValue( "matt", forHTTPHeaderField: "User-Agent")
        
        return request
    }
    
    func searchByTerm(term: String) async throws -> [PodcastIndexInfo] {
        guard let encodedTerm = term.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: self.baseURL + "/search/byterm?q=\(encodedTerm)") else {
            throw SearcherError.invalidURL(term)
        }
        let request = self.createRequest(url: url)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw SearcherError.invalidResponse("\(response)")
        }
        
        do {
            let indexDecoded = try JSONDecoder().decode(SearchResponses.self, from: data)
            return indexDecoded.feeds
        } catch {
            throw SearcherError.decodingError("\(error)")
        }
    }
}
