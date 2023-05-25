//
//  DetailView.swift
//  sportnews
//
//  Created by Jan Sallads on 23.05.23.
//

import SwiftUI
import Kingfisher

struct DetailView: View {
    
    let news: ShortNews
    @State var open: Bool = false
    @State var detailNews: DetailNews? = nil
    @State var galleryNews: GalleryNews? = nil
    let onToggle: ()->()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                KFImage(news.img)
                    .resizable()
                    .placeholder({
                        Image("icon")
                            .resizable()
                            .frame(width: 26, height: 26)
                    })
                    .frame(width: 26, height: 26)
                Text(news.title)
                Spacer()
                Text(news.timeOrDate)
                    .font(.caption2)
            }
            .contentShape(Rectangle())
            
            if open {
                
                //  detail news
                if let detailNews = detailNews {
                    VStack(alignment: .leading, spacing: 10) {
                        if let url = URL(string: detailNews.image.url) {
                            KFImage(url)
                                .resizable()
                                .scaledToFit()
                        }
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
                }
                
                //  gallery
                else if let galleryNews = galleryNews {
                    GalleryView(galleryNews: galleryNews)
                }
                
                //  loading
                else {
                    HStack {
                        ProgressView()
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                }
            }
        }
        .onTapGesture {
            if detailNews == nil && !news.id.contains("diashow") {
                Task {
                    await self.detailNews = SportWrangler.loadDetail(news.link)
                    print("downloaded article")
                }
            } else if galleryNews == nil && news.id.contains("diashow") {
                Task {
                    await self.galleryNews = SportWrangler.loadGallery(news.link)
                    print("downloaded gallery")
                }
            }
            withAnimation {
                open.toggle()
                onToggle()
            }
        }
        Divider()
    }
}

struct GalleryView: View {
    
    let galleryNews: GalleryNews
    @State var selectedPage: Int = 0
    
    var body: some View {
        HStack {
            TabView(selection: $selectedPage, content: {
                ForEach(galleryNews.pages.indices, id: \.self) { pageIndex in
                    VStack {
                        Text(galleryNews.pages[pageIndex].title)
                            .font(.headline)
                        if let url = galleryNews.pages[pageIndex].img {
                            KFImage(url)
                                .resizable()
                                .scaledToFit()
                        }
                        Text(galleryNews.pages[pageIndex].subtitle)
                            .font(.caption2)
                    }
                    .tabItem {
                        Text("\(pageIndex)")
                    }
                    .padding(20)
                }
            })
        }
//        .frame(height: 400)
    }
}
