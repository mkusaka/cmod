//
//  CmodApp.swift
//  Cmod
//
//  Created by masatomo.kusaka on 2026/05/10.
//

import SwiftUI

@main
@MainActor
struct CmodApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    private let runtime = CmodRuntime.shared

    var body: some Scene {
        WindowGroup {
            ContentView(state: runtime.state)
        }
        .defaultSize(width: 420, height: 180)
        .windowResizability(.contentSize)
    }
}
