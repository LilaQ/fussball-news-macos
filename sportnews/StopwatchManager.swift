//
//  StopwatchManager.swift
//  sportnews
//
//  Created by Jan Sallads on 28.05.23.
//

import SwiftUI

class StopWatchManager: ObservableObject {
    
    @Published var ellapsedTime: Double = 0.0
    @Published var isRunning: Bool = false
    var timer = Timer()
    
    init() { }
    
    func start() {
        self.isRunning = true
        ellapsedTime = 0
        timer.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            self.ellapsedTime += 0.1
        }
    }
    
    func stop() {
        self.isRunning = false
        timer.invalidate()
        ellapsedTime = 0
    }
    
}
