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
    let statusBarController: StatusBarController
    @State var open: Bool = false
    @State var detailNews: DetailNews? = nil
    @State var galleryNews: GalleryNews? = nil
    @State var matchups: [MatchupElement] = []
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
                
                //  matchups overview
                else if !matchups.isEmpty {
                    MatchupsOverviewView(link: news.link, matchups: matchups, statusBarController: statusBarController)
                        .frame(maxWidth: .infinity, alignment: .center)
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
            loadData()
            withAnimation {
                open.toggle()
                onToggle()
            }
        }
        .onAppear {
            //  used when opening the app from a local notification
            if open {
                loadData()
            }
        }
        Divider()
    }
    
    func loadData() {
        if detailNews == nil && news.id.contains("news") {
            Task {
                await self.detailNews = SportWrangler.loadDetail(news.link)
                print("downloaded article")
            }
        } else if galleryNews == nil && news.id.contains("diashow") {
            Task {
                await self.galleryNews = SportWrangler.loadGallery(news.link)
                print("downloaded gallery")
            }
        } else if matchups.isEmpty && news.id.contains("liveticker") {
            Task {
                await self.matchups = SportWrangler.loadNewsticker(news.link)
                print("downloaded matchups overview1")
            }
        }
    }
}

struct MatchupsOverviewView: View {
    
    let link: String
    @State var matchups: [MatchupElement]
    let statusBarController: StatusBarController
    @ObservedObject var timer = StopWatchManager()
    
    var body: some View {
        VStack {
            //  refresh timer
            HStack {
                Text("Refresh in ... \(String(format: "%2.f", 10 - timer.ellapsedTime))s")
            }
            
            ForEach(matchups) { matchup in
                MatchupsOverviewSingleView(matchup: matchup)
                Divider()
                    .frame(width: 500)
                    .padding(.horizontal, 10)
            }
        }
        .onAppear {
            print("appear")
            timer.start()
        }
        .onDisappear {
            print("disappear")
            timer.stop()
        }
        .onChange(of: timer.ellapsedTime) { val in
            if val > 10 {
                timer.stop()
                if statusBarController.newsPopover.isShown {
                    Task {
                        await matchups = SportWrangler.loadNewsticker(link)
                        timer.start()
                        print("downloaded matchups overview2")
                        print("timer: \(val)")
                    }
                } else {
                    print("Popover not showing, disabling timers")
                }
            }
        }
    }
}

struct MatchupsOverviewSingleView: View {
    
    @Environment(\.openWindow) var openWindow
    let matchup: MatchupElement
    @State var showPopover: Bool = false
    let columns = [
        GridItem(.flexible(minimum: 200)),
        GridItem(.fixed(50)),
        GridItem(.flexible(minimum: 200))
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 20) {
            HStack {
                KFImage(URL(string: matchup.home.image))
                Text(matchup.home.name)
                Spacer()
            }
            VStack(spacing: 3) {
                Text(matchup.result)
                Text(matchup.status == .LIVE ? "LIVE" : "Ended")
                    .foregroundColor(matchup.status == .LIVE ? Color.yellow : Color.white)
                    .font(.caption2)
            }
            HStack {
                Spacer()
                Text(matchup.away.name)
                KFImage(URL(string: matchup.away.image))
            }
        }
        .onTapGesture {
            self.showPopover = true
            //  TODO:   Continue here, new window should open
            openWindow(id: matchup.id)
        }
        .frame(width: 500)
        .background(PopoverView(isVisible: $showPopover) {
            VStack {
                KFImage(URL(string: matchup.home.image))
                Text(matchup.home.name)
            }
            .padding()
        })
    }
}

//struct MatchupsDetailView: View {
//
//    let link: String
//    @State var matchups: MatchupElement
//    let statusBarController: StatusBarController
//    let columns = [
//        GridItem(.flexible(minimum: 200)),
//        GridItem(.fixed(50)),
//        GridItem(.flexible(minimum: 200))
//    ]
//    @ObservedObject var timer = StopWatchManager()
//
//    var body: some View {
//        VStack {
//            //  refresh timer
//            HStack {
//                Text("Refresh in ... \(String(format: "%2.f", 10 - timer.ellapsedTime))s")
//            }
//
//            ForEach(matchups) { matchup in
//                LazyVGrid(columns: columns, spacing: 20) {
//                    HStack {
//                        KFImage(URL(string: matchup.home.image))
//                        Text(matchup.home.name)
//                        Spacer()
//                    }
//                    VStack(spacing: 3) {
//                        Text(matchup.result)
//                        Text(matchup.status == .LIVE ? "LIVE" : "Ended")
//                            .foregroundColor(matchup.status == .LIVE ? Color.yellow : Color.white)
//                            .font(.caption2)
//                    }
//                    HStack {
//                        Spacer()
//                        Text(matchup.away.name)
//                        KFImage(URL(string: matchup.away.image))
//                    }
//                }
//                .onTapGesture {
//                    print("open \(matchup.link)")
//                }
//                .frame(width: 500)
//                Divider()
//                    .frame(width: 500)
//                    .padding(.horizontal, 10)
//            }
//        }
//        .onAppear {
//            print("appear")
//            timer.start()
//        }
//        .onDisappear {
//            print("disappear")
//            timer.stop()
//        }
//        .onChange(of: timer.ellapsedTime) { val in
//            if val > 10 {
//                timer.stop()
//                if statusBarController.newsPopover.isShown {
//                    Task {
//                        await matchups = SportWrangler.loadNewsticker(link)
//                        timer.start()
//                        print("downloaded matchups overview2")
//                        print("timer: \(val)")
//                    }
//                } else {
//                    print("Popover not showing, disabling timers")
//                }
//            }
//        }
//    }
//}

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

