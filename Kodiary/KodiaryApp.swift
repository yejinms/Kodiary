//
//  KodiaryApp.swift
//  Kodiary
//
//  Created by Niko on 6/19/25.
//

import SwiftUI

@main
struct KodiaryApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
