//
//  ContentView.swift
//  TodoCalendar
//
//  Created by 송성욱 on 12/5/23.
//

import SwiftUI


struct ContentView: View {
    var body: some View {
        NavigationStack {
            Home()
                .navigationTitle("To-Do")
        }
    }

}

#Preview {
    ContentView()
}
