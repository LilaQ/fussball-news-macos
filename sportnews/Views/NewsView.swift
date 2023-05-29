//
//  NewsView.swift
//  sportnews
//
//  Created by Jan Sallads on 23.05.23.
//

import SwiftUI
import Kingfisher
import SFSafeSymbols

struct FilterView: View {
    @State var show: Bool = true
    let comp: String
    @Binding var filteredComps: [String]
    
    var body: some View {
        HStack {
            Text(comp)
            Spacer()
            Toggle(isOn: $show, label: {
                Text("Show")
            })
        }
        .onChange(of: show) { _show in
            if _show {
                removeFilter(comp)
            } else {
                addFilter(comp)
            }
        }
        .onAppear {
            self.show = !filteredComps.contains(comp)
        }
    }
    
    func addFilter(_ str: String) {
        self.filteredComps.append(str)
        filteredComps = Array(Set(filteredComps))
        UserDefaults.standard.set(filteredComps, forKey: "filteredComps")
    }
    
    func removeFilter(_ str: String) {
        self.filteredComps = self.filteredComps.filter({ $0 != str })
        filteredComps = Array(Set(filteredComps))
        UserDefaults.standard.set(filteredComps, forKey: "filteredComps")
    }
}

struct NewsView: View {
        
    let shortNews: [ShortNews]
    var newsId: String? = nil
    let statusBarController: StatusBarController
    @State var filteredComps: [String] = []
    @State var showFilter: Bool = false
    
    var availableComps: [String] {
        Array(Set(self.shortNews.map({
            if $0.competition.isEmpty {
                return "General"
            } else {
                return $0.competition
            }
        }))).sorted()
    }
    
    var body: some View {
        VStack {
            
            HStack {
                Text("News")
                    .font(.headline)
                Spacer()
                Button(action: {
                    withAnimation {
                        showFilter.toggle()
                    }
                }, label: {
                    HStack {
                        Image(systemSymbol: .popcornFill)
                        Text("Filter")
                            .font(.subheadline)
                    }
                })
            }
            Divider()
            
            //  filter
            if showFilter {
                VStack {
                    ForEach(availableComps, id: \.self) { comp in
                        FilterView(comp: comp, filteredComps: $filteredComps)
                        Divider()
                    }
                }
            }
            
            //  news
            ScrollViewReader { reader in
                ScrollView {
                    VStack(alignment: .leading) {
                        ForEach(shortNews) { news in
                            if !filteredComps.contains(news.competition) {
                                DetailView(news: news, statusBarController: statusBarController, open: news.id == newsId, onToggle: {
                                    withAnimation {
                                        reader.scrollTo(news.id, anchor: .top)
                                    }
                                })
                                .id(news.id)
                            }
                        }
                    }
                }
                .onAppear {
                    //  news Id passed to view, scroll there
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        if let newsId = newsId {
                            print("found a newsId to scroll to: \(newsId)")
                            withAnimation {
                                reader.scrollTo(newsId, anchor: .top)
                            }
                        }
                    }
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            //  load filtered comps from UserDefaults
            self.filteredComps = (UserDefaults.standard.array(forKey: "filteredComps") ?? []) as? [String] ?? []
        }
    }
}
