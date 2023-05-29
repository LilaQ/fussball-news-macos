//
//  PopoverView.swift
//  sportnews
//
//  Created by Jan Sallads on 28.05.23.
//

import SwiftUI

//  this is only used in SwiftUI to open child-Popovers that then can be detached
struct PopoverView<T: View>: NSViewRepresentable {
    @Binding private var isVisible: Bool
    private let content: () -> T
    
    init(isVisible: Binding<Bool>, @ViewBuilder content: @escaping () -> T) {
        self._isVisible = isVisible
        self.content = content
    }
    
    func makeNSView(context: Context) -> NSView {
        .init()
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.visibilityDidChange(isVisible, in: nsView)
        context.coordinator.contentDidChange(content: content)
    }
    
    func makeCoordinator() -> Coordinator {
        .init(isVisible: $isVisible)
    }
    
    @MainActor
    final class Coordinator: NSObject, NSPopoverDelegate {
        private let popover: NSPopover = .init()
        private let isVisible: Binding<Bool>
        
        init(isVisible: Binding<Bool>) {
            self.isVisible = isVisible
            super.init()
            
            popover.delegate = self
            popover.behavior = .semitransient
        }
        
        fileprivate func visibilityDidChange(_ isVisible: Bool, in view: NSView) {
            if isVisible {
                if !popover.isShown {
                    popover.show(relativeTo: view.bounds, of: view, preferredEdge: .maxX)
                }
            } else {
                if popover.isShown {
                    popover.close()
                }
            }
        }
        
        fileprivate func contentDidChange<T: View>(@ViewBuilder content: () -> T) {
            popover.contentViewController = NSHostingController(rootView: content())
        }
        
        func popoverDidClose(_ notification: Notification) {
            isVisible.wrappedValue = false
        }
        
        func popoverShouldDetach(_ popover: NSPopover) -> Bool {
            true
        }
    }
}
