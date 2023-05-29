//
//  sportnewsApp.swift
//  sportnews
//
//  Created by Jan Sallads on 23.05.23.
//

import SwiftUI

@main
struct sportnewsApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
//        WindowGroup {
//            ContentView()
//        }
//        WindowGroup("Liveticker", for: String.self) { $tickerId in
//            VStack {
//                Text("Fart in my Face pls")
//            }
//        }
        Settings {
            EmptyView()
//          MainMenuView()
        }
    }
}
