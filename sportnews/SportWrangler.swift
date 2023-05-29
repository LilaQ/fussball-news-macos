//
//  SportWrangler.swift
//  sportnews
//
//  Created by Jan Sallads on 23.05.23.
//

import SwiftUI
import SwiftSoup

class SportWrangler: ObservableObject {
    
    static func updateAll() async -> [ShortNews] {
        let rawString = await SportDeAPI.loadAllNews()
        var news: [ShortNews] = []
        if let doc = try? parse(rawString)?.select(".module-newmon") {
            do {
                let elements: Elements = try doc.select("li")
                for element in elements {
                    let title = try element.select("h3").text()
                    print(title)
                    let linkStr = try element.select("a").attr("href")
                    let imgStr = try element.select("img").attr("src")
                    var comp = (try? element.select("div.news-object--name-competition").text()) ?? "General"
                    if comp.isEmpty {
                        comp = "General"
                    }
                    let timeOrDate = try element.select("div.hs-news-published-yearordateortime").text()
                    let imgUrl = URL(string: imgStr)
                    let shortNews = ShortNews(id: linkStr, title: title, img: imgUrl, link: linkStr, competition: comp, timeOrDate: timeOrDate)
                    news.append(shortNews)
                }
            } catch (let error) {
                Logger.log(.error, "Error while decoding HTML: \(error)")
            }
        }
        return news.sorted(by: {
            if $0.timeOrDate.isTime && !$1.timeOrDate.isTime {
                return true
            } else if !$0.timeOrDate.isTime && $1.timeOrDate.isTime {
                return false
            } else {
                return $0.timeOrDate < $1.timeOrDate
            }
        })
    }
    
    static func loadGallery(_ urlString: String) async -> GalleryNews? {
        let rawString = await SportDeAPI.loadSingleNews(urlStr: urlString)
        
        if let doc = parse(rawString) {
            do {
                var pages: [GalleryNews.Page] = []
                let elements: Elements = try doc.select("div.hs-slideshow li.item")
                for element in elements {
                    let image = URL(string: try element.select("img").attr("src"))
                    var title: String? = (try? element.select("h2.title").text())
                    if title == nil {
                        title = try? element.select("h1.title").text()
                    }
                    if let _title = title, _title.isEmpty {
                        title = try? element.select("h1.title").text()
                    }
                    let subtitle = try element.select("div.subtitle").text()
                    let page = GalleryNews.Page(img: image, title: title ?? "", subtitle: subtitle)
                    pages.append(page)
                }
                return GalleryNews(pages: pages)
            } catch(let error) {
                Logger.log(.error, "Error while decoding HTML: \(error)")
            }
        }
        return nil
    }
    
    static func loadNewsticker(_ urlString: String) async -> [MatchupElement] {
        let rawString = await SportDeAPI.loadSingleNews(urlStr: urlString)
        
        if let doc = parse(rawString) {
            do {
                var matchups: [MatchupElement] = []
                let elements: Elements = try doc.select("div.module-gameplan div.match")
                for element in elements {
                    let teamNameHome = try element.select("div.team-name-home").text()
                    let teamImageHome = try element.select("div.team-image-home img").attr("src")
                    let teamHome = MatchupElement.Team(name: teamNameHome, image: teamImageHome)
                    let teamNameAway = try element.select("div.team-name-away").text()
                    let teamImageAway = try element.select("div.team-image-away img").attr("src")
                    let teamAway = MatchupElement.Team(name: teamNameAway, image: teamImageAway)
                    let result = try element.select("div.match-result a").text()
                    let link = try element.select("div.match-result a").attr("href")
                    let status = try element.hasClass("finished") ? MatchupElement.STATUS.FINISHED : MatchupElement.STATUS.LIVE
                    let matchup = MatchupElement(link: link, home: teamHome, away: teamAway, result: result, status: status)
                    matchups.append(matchup)
                }
                return matchups
            } catch(let error) {
                Logger.log(.error, "Error while decoding HTML: \(error)")
            }
        }
        return []
    }
    
    static func loadDetail(_ urlString: String) async -> DetailNews? {
        let rawString = await SportDeAPI.loadSingleNews(urlStr: urlString)
        
        if let doc = parse(rawString) {
            do {
                let scriptElements: Elements = try doc.select("script[type=application/ld+json]")
                let jsonStr = scriptElements.first()?.data()
                if let jsonData = jsonStr?.data(using: .utf8) {
                    var detailNews = try? JSONDecoder().decode(DetailNews.self, from: jsonData)
                    let details = try doc.select("div.hs-news-single div.content")
                    let elements = try details.select("p,h1,h2,h3,li")
                    var artElements: [DetailNews.ArticleElement] = []
                    for el in elements {
                        let artType = ["p", "li"].contains(el.tag().getNameNormal()) ? DetailNews.ArticleElement.TYPE.PARAGRAPH : .HEADLINE
                        let artText = try el.text()
                        let artElement = DetailNews.ArticleElement(type: artType, text: artText)
                        if !artText.isEmpty {
                            artElements.append(artElement)
                        }
                    }
                    detailNews?.articleElements = artElements
                    return detailNews
                }
                return nil
            } catch(let error) {
                Logger.log(.error, "Error while decoding HTML: \(error)")
            }
        }
        return nil
    }
    
    fileprivate static func parse(_ string: String) -> Document? {
        do {
            let doc: Document = try SwiftSoup.parse(string)
            return doc
        } catch (let error) {
            Logger.log(.error, "Error while parsing html: \(error)")
        }
        return nil
    }
    
}

struct ShortNews: Identifiable {
    var id: String
    var title: String
    var img: URL?
    var link: String
    var competition: String
    var timeOrDate: String
}

struct GalleryNews: Decodable {
    
    struct Page: Decodable {
        let img: URL?
        let title: String
        let subtitle: String
    }
    
    let pages: [Page]
}


struct DetailNews: Decodable {
    
    struct Image: Decodable {
        let url: String
        let caption: String
    }
    
    struct ArticleElement: Decodable, Identifiable {
        
        enum TYPE: Codable {
            case HEADLINE, PARAGRAPH
        }
        var id: String = UUID().uuidString
        let type: TYPE
        let text: String
    }
    
    let description: String
    let headline: String
    let alternativeHeadline: String
    let image: DetailNews.Image
    let thumbnailUrl: String
    var articleBody: String
    var articleElements: [ArticleElement]? = []
}

struct MatchupElement: Decodable, Identifiable {
    
    enum STATUS: Decodable {
        case LIVE, FINISHED
    }
    
    struct Team: Decodable {
        let name: String
        let image: String
    }
    
    var id: String = UUID().uuidString
    let link: String
    let home: Team
    let away: Team
    let result: String
    let status: STATUS
}
