//
//  MainMenuView.swift
//  longAPStatusOSX
//
//  Created by Jan Sallads on 27.06.21.
//

import SwiftUI
import Combine

//  necessary extension for TextEditor hacks background color
extension NSTextView {
    open override var frame: CGRect {
        didSet {
            backgroundColor = .clear //<<here clear
            drawsBackground = true
        }
    }
}

struct MainMenuView: View {
    
    @State var selected: Set<String> = Set<String>()
    @State var newWallet: String = ""
    
    let statusBarController: StatusBarController
    @AppStorage("showNotifications") var showNotifications: Bool = true
    @AppStorage("maxNews") var maxNews: Int = 100
    @State var maxNewsString: String = ""
    
    var body: some View {
        VStack(alignment: .leading) {
            Toggle(isOn: $showNotifications, label: {
                Text("Show Notifications")
            })
            
            HStack {
                Text("Max News")
                TextField("Max news", text: $maxNewsString)
            }
            
            HStack {
                Button(action: {
                    statusBarController.updateData()
                }, label: {
                    Text("Refresh now")
                })
                Spacer()
                Button("Quit") {
                    exit(0)
                }
                .background(Color.red)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 5))
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            //  load from AppStorage to TextField
            self.maxNewsString = String(self.maxNews)
        }
        .onChange(of: self.maxNewsString) { val in
            self.maxNews = Int(val) ?? 100
        }
    }
}
