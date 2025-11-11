//
//  Podcast2API.swift
//  podcast
//
//  Created by Matt Wittbrodt on 2/16/25.
//
import Foundation
import CryptoKit
import CoreData
import UIKit

enum ApiError: Error {
    case podcastFeedIdFetchError
    case episodeFetchError(String)
}

struct NetworkManager  {
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
    
    // frome le chat
    func fetchPodcasts(id: Int, completion: @escaping (Result<[PodcastInfo], Error>) -> Void) {
        // Construct the URL for the API request
        guard let url = URL(string: "https://api.example.com/podcasts") else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1, userInfo: nil)))
            return
        }

        // Create the URL request
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        // Start the data task
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            // Check for errors
            if let error = error {
                completion(.failure(error))
                return
            }

            // Ensure data is not nil
            guard let data = data else {
                completion(.failure(NSError(domain: "No data received", code: -1, userInfo: nil)))
                return
            }

            do {
                // Decode the JSON response
                let apiResponse = try JSONDecoder().decode(SearchResponses.self, from: data)
                completion(.success(apiResponse.feeds))
            } catch {
                // Handle decoding errors
                completion(.failure(error))
            }
        }

        // Resume the task to start the request
        task.resume()
    }
    
    func fetchPodcastByFeed(feed: Int) async -> Result<PodcastInfo,ApiError> {
        let url = URL(string: self.baseURL+"podcasts/byfeedid?id=\(feed)")
        let request = self.createRequest(url: url!)
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let apiResponse = try JSONDecoder().decode(FeedResponse.self, from: data)
            return .success(apiResponse.feed)
        } catch {
            return .failure(ApiError.podcastFeedIdFetchError)
        }
    }
    
    func fetchEpisodesByFeedId(id: Int) async throws -> [EpisodeInfo] {
        guard let url = URL(string: self.baseURL + "episodes/byfeedid?id=\(id)") else {
            throw NSError(domain: "Invalid URL", code: -1, userInfo: nil)
        }
        let request = self.createRequest(url: url)
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Validates response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ApiError.episodeFetchError("Failure with http response")
        }
        
        switch httpResponse.statusCode {
        case 200..<300:
            do {
                let apiResponse = try JSONDecoder().decode(EpisodeByFeedResponse.self, from: data)
                return apiResponse.items
            } catch {
                throw ApiError.episodeFetchError("\(error.localizedDescription) - \(id)")
            }
        default:
            throw ApiError.episodeFetchError("Default error")
        }
    }
    
    func savePodcastByFeedId(feed: Int) {
        // Check if podcast has already been saved
        let podRequest: NSFetchRequest<Podcast> = Podcast.fetchRequest()
        podRequest.predicate = NSPredicate(format: "feedId == %@", NSNumber(value: feed))
        do {
            let results = try context.fetch(podRequest)
            if results.count == 0 {
                let url = URL(string: self.baseURL+"/podcasts/byfeedid?id=\(feed)")
                let request = self.createRequest(url: url!)
                let task = URLSession.shared.dataTask(with: request) { data, response, error in
                    if error != nil {
                        return
                    }
                    guard let data = data else {
                        return
                    }
                    do {
                        // Decode the JSON response
                        let apiResponse = try JSONDecoder().decode(FeedResponse.self, from: data)
                        let podcast = Podcast(context: context)
                        //podcast.feedId = Int32(apiResponse.feed.id)
                        podcast.title = apiResponse.feed.title
                        podcast.imageUrl = apiResponse.feed.image
                        podcast.podcastDescription = apiResponse.feed.description
                        podcast.author = apiResponse.feed.author
                        
                        do {
                            try context.save()
                            saveEpisodes(feed: feed)
                        } catch {
                            return
                        }
                    } catch {
                        return
                    }
                }
                task.resume()
            } else {
                print("error")
            }
        } catch {
            print("\(error)")
        }
    }
    
    func saveEpisodes(feed: Int) {
        let url = URL(string: self.baseURL+"/episodes/byfeedid?id=\(feed)")
        let request = self.createRequest(url: url!)
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("\(error)")
                return
            }
            guard let data = data else {
                print("\(String(describing: error))")
                return
            }
            do {
                let apiResponse = try! JSONDecoder().decode(EpisodeByFeedResponse.self, from: data)
                for episode in apiResponse.items {
                    print(episode.title)
                    let saveEpisode = Episode(context: context)
                    //saveEpisode.id = Int64(episode.id)
                    saveEpisode.title = episode.title
                    saveEpisode.guid = episode.guid
                    saveEpisode.image = episode.image
                    saveEpisode.enclosureUrl = episode.enclosureUrl
                    saveEpisode.downloaded = false
                    saveEpisode.episodeDescription = episode.description
                    do {try context.save()} catch {print("ERRROR")}
                }
            }
        }
        task.resume()
    }
}
