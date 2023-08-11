//
//  MonitorStatusApp.swift
//  MonitorStatus
//
//  Created by zhangjiguo on 2023/08/11.
//

import os.log
import SwiftUI

@main
struct MonitorStatusApp: App {
    @State private var sc = NSScreen.screens.count
    let a = KeyPressedController()
    func execute() {
        sc = NSScreen.screens.count
        os_log("屏幕数量: %d", sc)
        if (sc < 2) {
            return
        }
        let task = Process()
        task.launchPath = "/usr/bin/env"
        task.arguments = ["/Applications/auto_screen_setup.sh"]
        task.launch()
    }
    
    var body: some Scene {
        MenuBarExtra {
            Button("Quit") {NSApplication.shared.terminate(nil)}.keyboardShortcut("q")
            
        } label: {
            Image(systemName: "display.2").onReceive(NotificationCenter.default.publisher(for: NSApplication.didChangeScreenParametersNotification)) { _ in
                self.execute()}
            Text(String(sc))
        }
        
    }
}

// https://github.com/rustdesk/rustdesk/blob/master/libs/enigo/src/macos/keycodes.rs
class KeyPressedController: ObservableObject {
    var keyseq: [Int] = []
    let flagkeys: [Int] = [55,56,57,58,59]
    init() {
        NSEvent.addGlobalMonitorForEvents(matching: [.keyUp, .keyDown, .flagsChanged], handler: { [self] (event: NSEvent) in
            let kc = Int(event.keyCode)
            os_log("==START== %d", kc)
            switch event.type {
            case .keyUp:
                os_log("KC-keyUP %d", kc)
            case .keyDown:
                os_log("KC-keyDOWN %d", kc)
                if (kc == 48 && keyseq.count > 0 && keyseq[keyseq.count-1] == 55) {
                    os_log("==app-switcher-start==")
                }
            case .flagsChanged:
                os_log("KC-flagsChanged %d %d", kc, (keyseq.contains(kc)))
                if let index = keyseq.firstIndex(of: kc) {
                    // keyseq.removeSubrange(index...keyseq.count-1)
                    keyseq.remove(at: index)
                    os_log("flagsUP %d | %d %d %d", kc, index, keyseq.count, kc == 56)
                    if index == 0 && keyseq.count == 0 { // 单击flags
                        if kc == 56 {
                            shift_change()
                        }
                    } else if (keyseq.count > 0 && !flagkeys.contains(keyseq[0])) {
                        keyseq.removeSubrange(0...keyseq.count-1)
                    }
                } else {
                    os_log("flagsDown %d | %d", kc, keyseq.count)
                    keyseq.append(kc)
                }
            default:
                break
            }
            let ks = keyseq.map { String($0) }.joined(separator: ",")
            os_log("KC-EVENT %d | %d %d %d | %{public}s{public}", kc, AXIsProcessTrusted(), CGPreflightListenEventAccess(), CGRequestListenEventAccess(), ks)
        }
        )
    }
    
    func shift_change() {
        let src = CGEventSource(stateID: .privateState)
        let ctrl_down = CGEvent(keyboardEventSource: src, virtualKey: 0x3b, keyDown: true)
        let ctrl_up = CGEvent(keyboardEventSource: src, virtualKey: 0x3b, keyDown: false)
        let space_down = CGEvent(keyboardEventSource: src, virtualKey: 0x31, keyDown: true)
        let space_up = CGEvent(keyboardEventSource: src, virtualKey: 0x31, keyDown: false)
        
        space_down?.flags = CGEventFlags.maskControl // 代表control已被按下
        
        ctrl_down?.post(tap: CGEventTapLocation.cghidEventTap)
        space_down?.post(tap: CGEventTapLocation.cghidEventTap)
        space_up?.post(tap: CGEventTapLocation.cghidEventTap)
        ctrl_up?.post(tap: CGEventTapLocation.cghidEventTap)
    }
}
