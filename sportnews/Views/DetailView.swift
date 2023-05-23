//
//  DetailView.swift
//  sportnews
//
//  Created by Jan Sallads on 23.05.23.
//

import SwiftUI
import Kingfisher

struct DetailView: View {
    
    let news: SportWrangler.ShortNews
    @State var open: Bool = false
    @State var detailNews: DetailNews? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                KFImage(news.img)
                Text(news.title)
            }
            
            if open {
                if let detailNews = detailNews {
                    VStack(alignment: .leading, spacing: 10) {
                        KFImage(URL(string: detailNews.image.url))
                            .resizable()
                            .scaledToFit()
                        Text(detailNews.image.caption)
                            .fontWidth(.condensed)
                            .font(.caption2)
                        Text(detailNews.headline)
                            .font(.headline)
                        
                        ForEach(detailNews.articleElements ?? []) { el in
                            if el.type == .HEADLINE {
                                Text(el.text)
                                    .font(.headline)
                            } else if el.type == .PARAGRAPH {
                                Text(el.text)
                            }
                        }
                    }
                    .frame(minHeight: 200)
                    .transition(.move(edge: .bottom))
                } else {
                    HStack {
                        ProgressView()
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if detailNews == nil {
                Task {
                    await self.detailNews = SportWrangler.loadDetail(news.link)
                    print("downloaded article")
                }
            }
            withAnimation {
                open.toggle()
            }
        }
        Divider()
    }
}
