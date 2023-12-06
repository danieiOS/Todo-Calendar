//
//  TodoCalendarApp.swift
//  TodoCalendar
//
//  Created by 송성욱 on 12/5/23.
//

import SwiftUI

@main
struct TodoCalendarApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
