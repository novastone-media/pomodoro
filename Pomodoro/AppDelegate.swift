//
//  AppDelegate.swift
//  Pomodoro
//
//  Created by Kirk Northrop on 31/07/2018.
//  Copyright © 2018 Novastone Media. All rights reserved.
//

import Cocoa
import AVFoundation
import UserNotifications

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    let statusItem = NSStatusBar.system.statusItem(withLength:80)
    let calendar = Calendar.current
    var audioPlayer:AVAudioPlayer!
    var enableSounds:NSMenuItem!
    var enableNotifications:NSMenuItem!
    
    var soundOn = true
    var notificationOn = true
    
    func makeStartNoise() {
        makeANoise(filename: "start")
    }
    
    func makeEndNoise() {
        makeANoise(filename: "end")
    }
    
    @objc func toggleSounds() {
        soundOn = !soundOn
        if (soundOn) {
            enableSounds.state = .on
        } else {
            enableSounds.state = .off
        }
    }
    
    @objc func toggleNotifications() {
        notificationOn = !notificationOn
        if (notificationOn) {
            enableNotifications.state = NSControl.StateValue.on
        } else {
            enableNotifications.state = NSControl.StateValue.off
        }
    }
    
    func makeANoise(filename: String) {
        if (soundOn) {
            let bundle = Bundle.main
            let audioFilePath = bundle.path(forResource:filename, ofType: "caf")
            
            if audioFilePath != nil {
                let audioFileUrl = NSURL.fileURL(withPath:audioFilePath!)
                
                do {
                    try audioPlayer = AVAudioPlayer(contentsOf: audioFileUrl)
                    audioPlayer.play()
                } catch {
                }
            }
        }
    }
    
    func userNotificationCenter(center: NSUserNotificationCenter, shouldPresentNotification notification: NSUserNotification) -> Bool {
        return true
    }
    
    func sendANotification(text: String) {
        if (notificationOn) {
            // Create the notification and setup information
            let notification = NSUserNotification()
            notification.identifier = "pomodoro" + String(NSDate().timeIntervalSince1970)
            notification.title = text
            notification.soundName = nil
            let notificationCenter = NSUserNotificationCenter.default
            notificationCenter.deliver(notification)
        }
    }
    
    @objc func updateCounters() {
        let date = Date()
        let minutes = calendar.component(.minute, from: date)
        let seconds = calendar.component(.second, from: date)
        let secondsLeft = 59 - seconds
        let count = minutes % 30
        
        if (count > 24 && count < 30) {
            let minutesLeft = 29 - count
            updateMenuBarCounter(minutesLeft: minutesLeft, secondsLeft: secondsLeft, isBreak: true)
        } else {
            let minutesLeft = 24 - count
            updateMenuBarCounter(minutesLeft: minutesLeft, secondsLeft: secondsLeft, isBreak: false)
        }
    }

    func updateMenuBarCounter(minutesLeft: Int, secondsLeft: Int, isBreak: Bool) {
        statusItem.button?.appearsDisabled = !isBreak

        if (isBreak) {
            statusItem.button?.title =  String(format: "☕️ %02d:%02d", minutesLeft, secondsLeft)
            if (isBreak && minutesLeft == 4 && secondsLeft == 59) {
                 makeEndNoise()
                 sendANotification(text: "Break Time!")
            }
        } else {
            statusItem.button?.title =  String(format: "🍅 %02d:%02d", minutesLeft, secondsLeft)
            if (minutesLeft == 24 && secondsLeft == 59) {
                makeStartNoise()
                sendANotification(text: "Work Time!")
            }
        }
    }
    
    func constructMenu() {
        let menu = NSMenu()
        
        enableSounds = NSMenuItem(title: "Sounds", action: #selector(toggleSounds), keyEquivalent: "s")
        menu.addItem(enableSounds)
        enableNotifications = NSMenuItem(title: "Notifications", action: #selector(AppDelegate.toggleNotifications), keyEquivalent: "n")
        menu.addItem(enableNotifications)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        enableSounds.state = NSControl.StateValue.on
        enableNotifications.state = NSControl.StateValue.on
        statusItem.menu = menu
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let timer = Timer(timeInterval: 1, target: self, selector: #selector(updateCounters), userInfo: nil, repeats: true)
        
        updateCounters()
        constructMenu()
        
        RunLoop.main.add(timer, forMode: .common)
    }
}
