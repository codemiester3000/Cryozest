//
//  ContentView.swift
//  Cryozest WatchKit App Watch App
//
//  Created by Robert Amarin on 6/21/23.
//

import SwiftUI
import HealthKit
import WatchConnectivity

class WatchConnectivityController: NSObject, ObservableObject, WCSessionDelegate {
    var session: WCSession

    override init() {
        session = WCSession.default
        super.init()
        session.delegate = self
        session.activate()
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) { }
}

struct ContentView: View {
    @EnvironmentObject var wcController: WatchConnectivityController
    let healthStore = HKHealthStore()

    @State private var timerLabel: String = "00:00"
    @State private var timer: Timer?
    @State private var timerDuration: TimeInterval = 0
    @State private var timerStartDate: Date?
    @State private var therapyType: TherapyType = .sauna

    var body: some View {
        VStack {
            Text("CryoZest")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .padding(.top, 5)
            
            VStack {
                HStack {
                    therapyButton(therapyType: .sauna)
                    therapyButton(therapyType: .coldPlunge)
                }
                
                HStack {
                    therapyButton(therapyType: .hotYoga)
                    therapyButton(therapyType: .meditation)
                }
            }.padding(.horizontal, 10)
            .padding(.vertical, 5)

            Text(timerLabel)
                .font(.system(size: 35, weight: .bold, design: .monospaced))
                .padding(.vertical, 5)
            
            Button(action: startStopButtonPressed) {
                Text(timer == nil ? "Start" : "Stop")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .frame(width: 80, height: 30)
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding(.top, 5)
        }
    }
    
    func therapyButton(therapyType: TherapyType) -> some View {
        Button(action: {
            self.therapyType = therapyType
            if WCSession.default.isReachable {
                WCSession.default.sendMessage(["therapyType": therapyType.rawValue], replyHandler: nil, errorHandler: nil)
            }
        }) {
            Text(therapyType.rawValue)
                .font(.system(size: 10))
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 30)
                .padding(.vertical, 5)
                .background(self.therapyType == therapyType ? Color.orange : Color.gray)
                .foregroundColor(.white)
        }
        .cornerRadius(8)
        .buttonStyle(PlainButtonStyle()) // Added this to remove default button styles
    }
    
    func startStopButtonPressed() {
        if timer == nil {
            timerStartDate = Date()
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                self.timerDuration = Date().timeIntervalSince(self.timerStartDate!)
                let minutes = Int(self.timerDuration) / 60
                let seconds = Int(self.timerDuration) % 60
                self.timerLabel = String(format: "%02d:%02d", minutes, seconds)
            }
            if WCSession.default.isReachable {
                WCSession.default.sendMessage(["command": "start"], replyHandler: nil, errorHandler: nil)
            }
        } else {
            timer?.invalidate()
            timer = nil
            self.timerLabel = "00:00"
            if WCSession.default.isReachable {
                WCSession.default.sendMessage(["command": "stop"], replyHandler: nil, errorHandler: nil)
            }
        }
    }
}

struct CryoZestWatchApp: App {
    @StateObject var wcController = WatchConnectivityController()

    var body: some Scene {
        WindowGroup {
            ContentView().environmentObject(wcController)
        }
    }
}

enum TherapyType: String, CaseIterable {
    case sauna = "Sauna"
    case coldPlunge = "Cold Plunge"
    case hotYoga = "Hot Yoga"
    case meditation = "Meditation"
}
