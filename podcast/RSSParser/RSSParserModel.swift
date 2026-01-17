import Foundation

// MARK: - RSS Parser with Async/Await
actor RSSFeedParser {
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
        return formatter
    }()
    
    func parse(from url: URL, data: Data? = nil) async throws -> RSSChannel {
        if let data {
            return try await parse(xmlData: data)
        }
        let (data, _) = try await URLSession.shared.data(from: url)
        return try await parse(xmlData: data)
    }
    
    func parse(xmlData: Data) async throws -> RSSChannel {
        try await withCheckedThrowingContinuation { continuation in
            let parser = XMLParser(data: xmlData)
            parser.shouldProcessNamespaces = true
            parser.shouldReportNamespacePrefixes = true
            let delegate = ParserDelegate(dateFormatter: dateFormatter) { result in
                continuation.resume(with: result)
            }
            parser.delegate = delegate
            parser.parse()
        }
    }
    
    private class ParserDelegate: NSObject, XMLParserDelegate {
        private var currentElement = ""
        private var currentItemBuilder: RSSEpisodeBuilder?
        private var channelBuilder = RSSChannelBuilder()
        private let dateFormatter: DateFormatter
        private let completion: (Result<RSSChannel, Error>) -> Void
        
        init(dateFormatter: DateFormatter, completion: @escaping (Result<RSSChannel, Error>) -> Void) {
            self.dateFormatter = dateFormatter
            self.completion = completion
        }
        
        func parser(_ parser: XMLParser, didStartElement elementName: String,
                   namespaceURI: String?, qualifiedName qName: String?,
                   attributes attributeDict: [String : String] = [:]) {
            let element = qName ?? elementName
            currentElement = element
            
            // If we are in an item, then instantiate an item builder
            if elementName == "item" {
                currentItemBuilder = RSSEpisodeBuilder(dateFormatter: dateFormatter)
            } else if element == "podcast:chapters" || qName?.contains("podcast:chapters") == true {
                currentItemBuilder?.setChapters(url: attributeDict["url"])
            } else if element == "enclosure" {
                currentItemBuilder?.setEnclosure(url: attributeDict["url"])
            } else if element == "itunes:image" {
                let imageUrl = attributeDict["href"]
                
                // Sometimes this field can occur in the channel section as well
                if currentItemBuilder != nil {
                    currentItemBuilder?.setImage(url: imageUrl)
                } else if let imageUrl = imageUrl {
                    channelBuilder.addValue(imageUrl, for: elementName)
                }
            } else if element == "atom:link" {
                if let href = attributeDict["href"] {
                    if currentItemBuilder == nil {
                        channelBuilder.addValue(href, for: element)
                    }
                }
            }
        }
        
        func parser(_ parser: XMLParser, foundCharacters string: String) {
            if currentElement == "item" { return }
            
            let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return }
            if currentItemBuilder != nil {
                currentItemBuilder?.addValue(trimmed, for: currentElement)
            } else {
                channelBuilder.addValue(trimmed, for: currentElement)
            }
        }
        
        func parser(_ parser: XMLParser, didEndElement elementName: String,
                   namespaceURI: String?, qualifiedName qName: String?) {
            if elementName == "item", let item = currentItemBuilder?.build() {
                channelBuilder.addItem(item)
                currentItemBuilder = nil
            }
            currentElement = ""
        }
        
        func parserDidEndDocument(_ parser: XMLParser) {
            completion(.success(channelBuilder.build()))
        }
        
        func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
            completion(.failure(parseError))
        }
    }
}

// MARK: - Builder Pattern for Cleaner Construction
private struct RSSChannelBuilder {
    private var title = ""
    private var link = ""
    private var description = ""
    private var imageUrl = ""
    private var author = ""
    private var items: [RSSEpisode] = []
    private var currentElement: String?
    private var itunesImage = ""
    private var usedatomLink: Bool = false
    
    mutating func addValue(_ value: String, for element: String) {
        if element == "title" && title != "" {
            return
        }
                
        switch element {
        case "title": title += value
        case "itunes:author": author += value
        case "link":
            if value != link && !usedatomLink {
                link += value
            }
        case "atom:link":
            if !value.isEmpty {
                link = value
            }
            usedatomLink = true
        case "description": description += value
        case "url": imageUrl += value
        case "itunes:image": itunesImage += value
        default: break
        }
    }
    
    // Call this when starting an XML element
    mutating func startElement(_ name: String) {
        currentElement = name
    }
    
    // Call this when ending an XML element
    mutating func endElement(_ name: String) {
        currentElement = nil
    }
    
    mutating func addItem(_ item: RSSEpisode) {
        items.append(item)
    }
    
    func build() -> RSSChannel {
        let imageLocation = imageUrl.isEmpty ? itunesImage : imageUrl
        
        return RSSChannel(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            link: link.trimmingCharacters(in: .whitespacesAndNewlines),
            author: author.trimmingCharacters(in: .whitespacesAndNewlines),
            description: description.trimmingCharacters(in: .whitespacesAndNewlines),
            imageUrl: imageLocation.trimmingCharacters(in: .whitespacesAndNewlines),
            items: items
        )
    }
}

private struct RSSEpisodeBuilder {
    private var title = ""
    private var link = ""
    private var description = ""
    private var publishedDate = ""
    private var guid = ""
    private var imageUrl = ""
    private var duration = ""
    private var chaptersUrl: String?
    private var enclosureUrl: String?
    private let dateFormatter: DateFormatter
    private var imageData: Data? = nil
    
    init(dateFormatter: DateFormatter) {
        self.dateFormatter = dateFormatter
    }
    
    mutating func addValue(_ value: String, for element: String) {
        switch element {
        case "title": title += value
        case "link": link += value
        case "description": description += value
        case "pubDate": publishedDate += value
        case "guid": guid += value
        case "itunes:duration": duration += value
        default: break
        }
    }
    
    mutating func setChapters(url: String?) {
        chaptersUrl = url
    }
    
    mutating func setEnclosure(url: String?) {
        enclosureUrl = url
    }
    
    mutating func setImage(url: String?) {
        imageUrl = url ?? ""
    }
    
    mutating func build() -> RSSEpisode {
        let chapters: PodcastChapters?
        if let urlString = chaptersUrl, let url = URL(string: urlString) {
            chapters = PodcastChapters(url: url)
        } else {
            chapters = nil
        }
        
        // check if we need to convert duration into a different value
        if duration.contains(":") {
            let new_duration = DateUtils.durationStringToSeconds(duration) ?? 0
            duration = String(new_duration)
        }
        
        return RSSEpisode(
            episodeTitle: title.trimmingCharacters(in: .whitespacesAndNewlines),
            link: link.trimmingCharacters(in: .whitespacesAndNewlines),
            displayDescription: description.trimmingCharacters(in: .whitespacesAndNewlines),
            guid: guid.trimmingCharacters(in: .whitespacesAndNewlines),
            imageUrl: imageUrl,
            episodeDate: dateFormatter.date(from: publishedDate) ?? Date.distantPast,
            episodeDuration: Int16(duration) ?? 0,
            chapters: chapters,
            enclosureUrl: enclosureUrl,
            imageData: imageData,
            chaptersUrl: chaptersUrl,
        )
    }
}
