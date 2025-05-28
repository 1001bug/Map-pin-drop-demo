//
//  MapTest321App.swift
//  MapTest321
//
//  Created by Alex Yer on 5/28/25.
//

import SwiftUI

@main
struct MapTest321App: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
