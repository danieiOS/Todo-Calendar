//
//  Home.swift
//  TodoCalendar
//
//  Created by 송성욱 on 12/5/23.
//

import SwiftUI

struct Home: View {
    
    /// View Properties
    @Environment(\.self) private var environment
    @State private var filterDate: Date = .init()
    @State private var showPendingTasks: Bool = true
    @State private var showCompletedTasks: Bool = true

    var body: some View {
        List {
            DatePicker(selection: $filterDate, displayedComponents: [.date]) {
               
               
            }
            .labelsHidden()
            .datePickerStyle(.graphical)
            /// 한 번 더 언급하면 삭제에 대한 동일한 문제가 존재한다는 것을 알 수 있습니다. 날짜를 예측에서 변경하지 않으면 문제가 발생하지 않는 것을 알았습니다. 그러나 날짜를 변경하면 Core Data 검색 요청에 문제가 발생하는 것 같습니다. 이 문제를 해결하기 위해 Core Data 검색 요청의 NSPredicate를 수동으로 업데이트하려고 합니다.
            CustomFilteringDataView(filterDate: $filterDate) { pendingTasks, completedTasks in
                DisclosureGroup(isExpanded: $showPendingTasks) {
                    /// Custom Core Data Filter View, Which will Display Only Pending Tasks on this Day
                    if pendingTasks.isEmpty {
                        Text("No Task's Found")
                            .font(.caption)
                            .foregroundStyle(Color.gray)
                    } else {
                        ForEach(pendingTasks) {
                            TaskRow(task: $0, isPendingTask: true)
                        }
                    }
                   
                } label: {
                    Text("Pending Task`s \(pendingTasks.isEmpty ? "" : "(\(pendingTasks.count))")")
                        .font(.caption)
                        .foregroundStyle(Color.gray)
                }
                
                DisclosureGroup(isExpanded: $showCompletedTasks) {
                    /// Custom Core Data Filter View, Which will Display Only Completed Tasks on this Day
                    if completedTasks.isEmpty {
                        Text("No Task's Found")
                            .font(.caption)
                            .foregroundStyle(Color.gray)
                    } else {
                        ForEach(completedTasks) {
                            TaskRow(task: $0, isPendingTask: false)
                        }
                    }
                  
                } label: {
                    Text("Completed Task`s \(completedTasks.isEmpty ? "" : "(\(completedTasks.count))")")
                        .font(.caption)
                        .foregroundStyle(Color.gray)
                }
            }
           
            
          
        }
        .toolbar {
            ToolbarItem(placement: .bottomBar) {
                Button { 
                    /// 빈 작업을 생성하고 대기 중인 작업 섹션을 표시합니다. (사용자가 닫았을 경우 어떠한 방법으로든)
                    ///  Simply Opening Pending Task View
                    ///  Then Adding an Empty Task
                    do {
                        let task = Task(context: environment.managedObjectContext)
                        task.id = .init()
                        task.date = filterDate
                        task.title = ""
                        task.isCompleted = false
                        
                        try environment.managedObjectContext.save()
                        showPendingTasks = true
                    } catch {
                        print(error.localizedDescription)
                    }
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                        
                        Text("New Task")
                    }
                    .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

#Preview {
   ContentView()
}

struct TaskRow: View {
    /// 알 수 있듯이 상태 변경 중에 작업이 업데이트되지 않았습니다. 이 문제를 해결하기 위해, 간단히 Core Data Entity를 @ObservedObject로 변환하십시오.
    @ObservedObject var task: Task
    var isPendingTask: Bool
    @Environment(\.self) private var environment
    @FocusState private var showKeyboard: Bool
    var body: some View {
        HStack(spacing: 12) {
            /// 이 버튼 탭이 목록 셀 전체에서 작동할 것임을 증명하겠습니다. 버튼만이 아니라 전체 목록 셀에 대해 작동하게 하려면 버튼 스타일을 일반(plain)으로 변경하면 문제가 해결됩니다.
            Button {
                task.isCompleted.toggle()
            } label: {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title)
                    .foregroundStyle(Color.blue)
            }
            .buttonStyle(.plain)
            
            VStack(alignment: .leading,spacing: 4) {
                TextField("Task Title", text: .init(get: {
                    return task.title ?? ""
                }, set: { value in
                    task.title = value
                }))
                .focused($showKeyboard)
                .onSubmit {
                    removeEmptyTask()
                    
                    save()
                }
                .foregroundColor(isPendingTask ? .primary : .gray)
                .strikethrough(!isPendingTask, pattern: .dash, color: .primary)
                /// Custom Date Picker
                Text((task.date ?? .init()).formatted(date: .omitted, time: .shortened))
                    .font(.callout)
                    .foregroundStyle(Color.gray)
                    .overlay {
                        DatePicker(selection: .init(get: {
                            return task.date ?? .init()
                        }, set: { value in
                            task.date = value
                            /// Saving Date When ever it's Updated
                            save()
                        }), displayedComponents: [.hourAndMinute]) {
                            
                        }
                        .labelsHidden()
                        /// BlendMode를 활용하여 뷰를 숨기기
                        .blendMode(.destinationOver)
                    }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .onAppear {
            /// 텍스트 필드가 비어 있을 때 키보드가 나타날 것이며, 이는 작업을 만들 때마다 키보드가 자동으로 표시되고 작업 제목이 입력될 것을 의미합니다.
            if (task.title ?? "").isEmpty {
                showKeyboard = true
            }
        }
        .onDisappear {
            /// 보시다시피, 우리는 키보드를 닫지 않고 즉시 작업을 제거하기 때문에 키보드가 작업 제목에 바인딩되어 있습니다. 이 경고가 표시되었습니다. 이를 해결하기 위해 간단히 먼저 키보드를 닫고 약간의 지연 후에 작업을 제거하면 경고가 사라집니다.            removeEmptyTask()
            save()
        }
        /// 사용자가 앱을 나갈 때 내용을 확인하는 중
        .onChange(of: environment.scenePhase) { newValue in
           /*
            사용자가 앱을 닫거나 최소화할 때 작업 제목을 입력하지 않은 경우, 빈 작업이 여전히 남아있을 수 있습니다.
            이러한 경우에 애플리케이션이 활성 상태가 아닌 경우 빈 작업을 해제합니다.
           */
            if newValue != .active {
                showKeyboard = false
                DispatchQueue.main.async {
                    /// Checking if it's Empty
                    removeEmptyTask()
                    save()
                }
               
            }
        }
        /// 알 수 있듯이, 작업 행을 삭제한 후에 해당 행을 스와이프하면 디스클로저 그룹이 이상하게 작동했습니다. 이 문제를 해결하려면 스와이프 동작에 일정한 지연을 만들기만 하면 됩니다.
        /// Adding swipe to delete
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    environment.managedObjectContext.delete(task)
                    save()
                    /// 어떤 이유에서인지 Core Data 검색 요청이 이상하게 작동하고 있습니다. 이 문제는 우리가 예측에서 날짜를 변경하지 않으면 발생하지 않지만, 변경하면 Core Data 검색 요청에 문제가 발생하는 것 같습니다. 이 문제를 해결하기 위해 간단히 작업들에 대한 수동 필터링을 수행하면 됩니다.
                }
            } label: {
                Image(systemName: "trash.fill")
            }
        }
    }
    
    /// Context Saving Method
    func save() {
        do {
            try environment.managedObjectContext.save()
        } catch {
            print(error.localizedDescription)
        }
    }
    
    /// Removing Empty Task
    func removeEmptyTask() {
        if (task.title ?? "").isEmpty {
            // Removing Empty Task
            environment.managedObjectContext.delete(task)
        }
    }
}
