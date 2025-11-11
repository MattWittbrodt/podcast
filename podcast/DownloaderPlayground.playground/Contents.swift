import Foundation

struct ChapterResponse: Decodable {
    let version: String
    let chapters: [ChapterInfo]
}

func saveChapters(urlString: String) async throws {
    guard let url = URL(string: urlString) else {
        return
    }
    
    let decoder = JSONDecoder()
    var request = URLRequest(url: url)
    request.httpMethod = "GET"

    let (data, _) = try await URLSession.shared.data(for: request)
    let loadedFile = try decoder.decode(ChapterResponse.self, from: data)
    print(loadedFile.chapters.count)
}

try? await saveChapters(urlString: "https://reflex.livewire.io/chapters/podcast/856cd618-7f34-57ea-9b84-3600f1f65e7f/item/http://1768.noagendanotes.com/chapters/https://chapters.hypercatcher.com/http:feed.nashownotes.comrss.xml/http:1768.noagendanotes.com")
