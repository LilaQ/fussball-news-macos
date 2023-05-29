//
//  StatusBarController.swift
//
//  Created by Jan Sallads on 20.06.21.
//

import AppKit
import SwiftUI
import UserNotifications
import AVFoundation
import Combine

var player: AVAudioPlayer?

func tintedImage(_ image: NSImage, color: NSColor) -> NSImage {
    let newImage = NSImage(size: image.size)
    newImage.lockFocus()

    // Draw with specified transparency
    let imageRect = NSRect(origin: .zero, size: image.size)
    image.draw(in: imageRect, from: imageRect, operation: .sourceOver, fraction: color.alphaComponent)

    // Tint with color
    color.withAlphaComponent(1).set()
    imageRect.fill(using: .sourceAtop)

    newImage.unlockFocus()
    return newImage
}

class StatusBarController {
    
    private var statusBar: NSStatusBar
    private var mainMenuItem: NSStatusItem
    private var updateText: NSStatusItem?
    private var newsText: NSStatusItem?
    
    public var newsButton: NSStatusBarButton
    public var newsToPush: String? = nil
    
    private var mainMenuPopover: NSPopover
    public var newsPopover: NSPopover
    
    var clicked: NSStatusItem?
    var shortNews: [ShortNews] = []
    
    var timer:Timer!
    
    static let WINDOW_WIDTH = "windowWidth"
    static let WINDOW_HEIGHT = "windowHeight"
    
    init() {
        
        statusBar = NSStatusBar.init()
        
        if UserDefaults.standard.value(forKey: StatusBarController.WINDOW_WIDTH) == nil {
            UserDefaults.standard.set(800, forKey: StatusBarController.WINDOW_WIDTH)
        }
        if UserDefaults.standard.value(forKey: StatusBarController.WINDOW_HEIGHT) == nil {
            UserDefaults.standard.set(1000, forKey: StatusBarController.WINDOW_HEIGHT)
        }
        
        // Creating popovers for Main menu
        mainMenuPopover = NSPopover()
        mainMenuPopover.contentSize = NSSize(width: 250, height: 50)
        mainMenuPopover.behavior = NSPopover.Behavior.transient
        newsPopover = NSPopover()
        newsPopover.contentSize = NSSize(
            width: UserDefaults.standard.integer(forKey: StatusBarController.WINDOW_WIDTH),
            height: UserDefaults.standard.integer(forKey: StatusBarController.WINDOW_HEIGHT))
        newsPopover.behavior = NSPopover.Behavior.transient
        
        //  init status bar items
        //        mainMenuItem = statusBar.statusItem(withLength: NSStatusItem.variableLength)
        mainMenuItem = statusBar.statusItem(withLength: NSStatusItem.variableLength)
        mainMenuItem.length = 30
        updateText = statusBar.statusItem(withLength: NSStatusItem.variableLength)
        newsText = statusBar.statusItem(withLength: NSStatusItem.variableLength)
        
        //  add icons
        let iconImage = NSImage(named: "icon")
        mainMenuItem.button?.layer = .init()
        mainMenuItem.button?.layer?.contentsGravity = .resizeAspect
        mainMenuItem.button?.layer?.contents = tintedImage(iconImage!, color: NSColor.black)
        mainMenuItem.button?.wantsLayer = true
        
        newsButton = (newsText?.button!)!
        newsButton.attributedTitle = NSAttributedString(string: "News")
        newsButton.action = #selector(toggleNewsPopover(sender:))
        newsButton.target = self
        
        //  set click handler
        if let mainBarButton = mainMenuItem.button {
            mainBarButton.attributedTitle = NSAttributedString(string: "Main Menu")
            mainBarButton.action = #selector(toggleMainMenuPopover(sender:))
            mainBarButton.target = self
        }
        
        timer = Timer.scheduledTimer(timeInterval: 600, target: self, selector: #selector(updateData), userInfo: nil, repeats: true)
        updateData()
    }
    
    @objc
    func toggleMainMenuPopover(sender: AnyObject) {
        if(!mainMenuPopover.isShown) {
            showPopover(sender, popover: mainMenuPopover, view: MainMenuView(statusBarController: self))
        }
        else {
            hidePopover(sender, popover: mainMenuPopover)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
    
    @objc
    func triggerFullUpdate(sender: AnyObject) {
        updateData()
    }
    
    func getData(from url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> ()) {
        URLSession.shared.dataTask(with: url, completionHandler: completion).resume()
    }
    
    func downloadImage(from url: URL, closure: @escaping (Data)->()) {
        getData(from: url) { data, response, error in
            guard let data = data, error == nil else { return }
            closure(data)
        }
    }
    
    func set(data: Data, ext: String) -> URL? {
        let randomFileName = UUID().uuidString + "." + ext
        let pathAndFilename = getDocumentsDirectory().appendingPathComponent(randomFileName)
        try? data.write(to: pathAndFilename)
        return pathAndFilename
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    @objc
    func toggleNewsPopover(sender: AnyObject) {
        if(!mainMenuPopover.isShown) {
            newsPopover.contentSize = NSSize(
                width: UserDefaults.standard.integer(forKey: StatusBarController.WINDOW_WIDTH),
                height: UserDefaults.standard.integer(forKey: StatusBarController.WINDOW_HEIGHT))
            showPopover(sender, popover: newsPopover, view: NewsView(shortNews: shortNews, newsId: newsToPush, statusBarController: self))
        }
        else {
            hidePopover(sender, popover: newsPopover)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
    
    
    private func showPopover(_ sender: AnyObject, popover: NSPopover, view: some View) {
        popover.contentViewController = NSHostingController(rootView: view)
        popover.show(relativeTo: sender.bounds, of: sender as! NSView, preferredEdge: NSRectEdge.maxY)
        popover.becomeFirstResponder()
        popover.contentViewController?.view.window?.makeKey()
    }
    
    private func hidePopover(_ sender: AnyObject, popover: NSPopover) {
        popover.performClose(sender)
    }
    
    func generateNotification(title: String, body: String, sound: String?, imageFileUrl: URL?, articleId: String) {
        let notificationCenter = UNUserNotificationCenter.current();
        notificationCenter.getNotificationSettings { settings in
            if settings.authorizationStatus == .authorized {
                let content = UNMutableNotificationContent()
                content.title = title
                content.body = ""
                if let imgUrl = imageFileUrl {
                    let att = try! UNNotificationAttachment(identifier: "img", url: imgUrl)
                    content.attachments = [att]
                } else {
                    let att = try! UNNotificationAttachment(identifier: "img", url: Bundle.main.url(forResource: "icon", withExtension: "png")!)
                    content.attachments = [att]
                }
                if sound != nil {
                    self.playSound(sound!)
                }
                content.userInfo = ["id": articleId]
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
                let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
                notificationCenter.add(request)
            }
        }
    }
    
    func playSound(_ name: String) {
        let path = Bundle.main.path(forResource: name, ofType: "caf")!
        let url = URL(fileURLWithPath: path)
        do {
            let sound = try AVAudioPlayer(contentsOf: url)
            player = sound
            sound.play()
        } catch {
            //
        }
    }
    
    @objc func updateData() {
        Task {
            let filteredComps: [String] = (UserDefaults.standard.array(forKey: "filteredComps") ?? []) as? [String] ?? []
            let newNews = await SportWrangler.updateAll()
            for news in newNews {
                
                //  if it already exists, we replace the time tag, since it might change from time to day
                if let index = self.shortNews.firstIndex(where: { $0.id == news.id }) {
                    self.shortNews[index].timeOrDate = news.timeOrDate
                }
                
                //  not found, insert
                else {
                    self.shortNews.insert(news, at: 0)
                    if UserDefaults.standard.bool(forKey: "showNotifications") && !filteredComps.contains(news.competition) {
                        if let uri = news.img {
                            downloadImage(from: uri, closure: { fileData in
                                let fileUri = self.set(data: fileData, ext: uri.lastPathComponent)
                                self.generateNotification(title: news.title, body: news.title, sound: nil, imageFileUrl: fileUri, articleId: news.id)
                            })
                        } else {
                            generateNotification(title: news.title, body: news.title, sound: nil, imageFileUrl: nil, articleId: news.id)
                        }
                    }
                }
            }
            
            //  cut-off, so we don't end up with thousands of news at once
            let maxNews = UserDefaults.standard.integer(forKey: "maxNews")
            if self.shortNews.count > maxNews {
                self.shortNews = Array(self.shortNews.prefix(maxNews))
            }
            print("we have a total of \(self.shortNews.count) news")
        }
    }
}
