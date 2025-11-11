//
//  PodcastIndexModel.swift
//  podcast
//
//  Created by Matt Wittbrodt on 6/18/25.
//

import Foundation
import CryptoKit

struct PodcastIndexModel {
    
    var baseURL: String = "https://api.podcastindex.org/api/1.0/"
    private var API_KEY = "3SGJBHDZ3RCWT7HFLJSW"
    private var API_SECRET = "a5qfGcrZkQu^rMYax8d2^US#J^yXXwHW7fg9fGXd"
    private var context = PersistenceManager().viewContext
    
    func createRequest(url:URL) -> URLRequest {
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
    
    func searchByTerm(searchTerm: String) async throws -> [PodcastInfo] {
        // 1. Safely construct the URL
        guard let encodedTerm = searchTerm.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: self.baseURL + "/search/byterm?q=\(encodedTerm)") else {
            throw SearcherError.invalidURL(searchTerm)
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
