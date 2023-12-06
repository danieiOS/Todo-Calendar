//
//  CustomFilteringDataView.swift
//  TodoCalendar
//
//  Created by 송성욱 on 12/5/23.
//

import SwiftUI

struct CustomFilteringDataView<Content: View>: View {
    var content: ([Task], [Task]) -> Content
    @FetchRequest private var result: FetchedResults<Task>
    @Binding private var filterDate: Date
    init(filterDate: Binding<Date>, @ViewBuilder content: @escaping ([Task], [Task]) -> Content) {
        /// Creating Predicate for Filtering Task`s`
        let calendar  = Calendar.current
        let startOfDay = calendar.startOfDay(for: filterDate.wrappedValue)
        let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: startOfDay)!
        
        let predicate = NSPredicate(format: "date >= %@ AND date <= %@", argumentArray: [startOfDay, endOfDay])
        
        _result = FetchRequest(entity: Task.entity(), sortDescriptors: [
            NSSortDescriptor(keyPath: \Task.date, ascending: false)
        ], predicate: predicate, animation: .easeInOut(duration: 0.25))
        
        self.content = content
        self._filterDate = filterDate
    }
    var body: some View {
        content(separateTasks().0, separateTasks().1)
            .onChange(of: filterDate) { newValue in
             /// Manual NSPredicate update
                /// Clearing Old Predicate
                result.nsPredicate = nil
                
                let calendar  = Calendar.current
                let startOfDay = calendar.startOfDay(for: newValue)
                let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: startOfDay)!
                
                let predicate = NSPredicate(format: "date >= %@ AND date <= %@", argumentArray: [startOfDay, endOfDay])
                
                /// Assigning New Predicate
                result.nsPredicate = predicate
                /// 알 수 있듯이, 또 다른 문제를 발견했습니다: 사용자가 텍스트 필드를 비우고 다른 날짜로 이동하면 빈 텍스트 필드가 여전히 남아 있습니다. 이 문제를 해결하기 위해 간단히 ondisappear 수정자를 사용하고 텍스트가 비어 있으면 작업을 제거하면 됩니다.
            }
    }
    
    func separateTasks() -> ([Task], [Task]) {
        let pendingTasks = result.filter { !$0.isCompleted }
        let completedTasks = result.filter { $0.isCompleted }
        
        return (pendingTasks , completedTasks)
    }
}

#Preview {
    ContentView()
}
