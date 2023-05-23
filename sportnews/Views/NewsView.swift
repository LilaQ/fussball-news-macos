//
//  NewsView.swift
//  sportnews
//
//  Created by Jan Sallads on 23.05.23.
//

import SwiftUI
import Kingfisher

struct NewsView: View {
        
    let shortNews: [SportWrangler.ShortNews]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Text("News")
                    .font(.headline)
                ForEach(shortNews) { news in
                    DetailView(news: news)
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
