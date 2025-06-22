//
//  KodiaryApp.swift
//  Kodiary
//
//  Created by Niko on 6/19/25.
//

import SwiftUI

@main
struct KodiaryApp: App {
    let dataManager = DataManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataManager)
                .environmentObject(LanguageManager.shared)
        }
    }
}
