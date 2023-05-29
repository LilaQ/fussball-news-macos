//
//  AppDelegate.swift
//  sportnews
//
//  Created by Jan Sallads on 23.05.23.
//

import SwiftUI
import UserNotifications

class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {

    var statusBar: StatusBarController?
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        //Initialising the status bar
        statusBar = StatusBarController.init()
        NSApplication.shared.keyWindow?.close()
        
        //  no dock item / no menu bar
        NSApp.appearance = .none
        NSApp.setActivationPolicy(.prohibited)
        
        URLCache.shared.memoryCapacity = 1_000_000_000 // ~50 MB memory space
        URLCache.shared.diskCapacity = 1_000_000_000 // ~1GB disk cache space
        
        //  request notification permission
        requestNotificationPermission()
        UNUserNotificationCenter.current().delegate = self
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        await NSApplication.shared.keyWindow?.close()
        if statusBar != nil {
            DispatchQueue.main.async {
                self.statusBar?.newsToPush = response.notification.request.content.userInfo["id"] as? String ?? nil
                self.statusBar?.toggleNewsPopover(sender: self.statusBar!.newsButton)
            }
        }
    }

    func requestNotificationPermission() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization() { granted, error in
            if error != nil {
                print ("Request notifications permission Error");
            }
            if granted {
                print ("Notifications allowed")
            } else {
                print ("Notifications denied")
            }
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    func applicationWillResignActive(_ notification: Notification) {
    }
    
}
