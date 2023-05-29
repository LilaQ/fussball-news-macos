//
//  OpenSeaAPI.swift
//  nifty
//
//  Created by Jan Sallads on 18.05.23.
//

import SwiftUI

class SportDeAPI {
    
    enum SportDeAPIError: Error {
        case GeneralError
        case URLError(String)
        case RequestError(String)
        case ResponseError(String)
    }
    
    private static func urlComponents() -> URLComponents {
        var urlComponents = URLComponents(string: "https://www.sport.de/fussball/news-archiv/")!
        urlComponents.queryItems = []
        return urlComponents
    }
    
    private static func request(urlComponents: URLComponents) async -> (Result<String, SportDeAPIError>) {
        guard let url = urlComponents.url else { return .failure(SportDeAPIError.URLError(urlComponents.path)) }
        Logger.log(.action, "Call: \(url.absoluteString)")
        let request = URLRequest(url: url)
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let response = response as? HTTPURLResponse, !(200...299).contains(response.statusCode) {
                return .failure(SportDeAPIError.ResponseError(response.description))
            } else {
                return .success(String(decoding: data, as: UTF8.self))
            }
        } catch(let error) {
            return .failure(SportDeAPIError.RequestError(error.localizedDescription))
        }
    }
    
    static func loadAllNews(_ page: Int = 1) async -> String {

        let urlComponents = URLComponents(string: "https://www.sport.de/widget_news_archiv-content/ty-sport/ir1/fn/tn/pa\(page)/")!
        
        let result: Result<String, SportDeAPIError> = await request(urlComponents: urlComponents)
        switch result {
        case .success(let success):
            return success
        case .failure(let error):
            Logger.log(.error, "loadAllNews error: \(error)")
            return ""
        }
    }
    
    static func loadSingleNews(urlStr: String) async -> String {
        var urlComponents = URLComponents(string: "https://www.sport.de\(urlStr)")!
        
        let result: Result<String, SportDeAPIError> = await request(urlComponents: urlComponents)
        switch result {
        case .success(let success):
            return success
        case .failure(let error):
            Logger.log(.error, "loadSingleNews error: \(error)")
            return ""
        }
    }
}
