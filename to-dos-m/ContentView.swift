import SwiftUI


struct Activity: Identifiable, Hashable{
    let id = UUID()
    var name: String
    var isDone: Bool = false
    var group: ActivityGroup
    var importance: ActivityImportance
    var dueDate: Date?
    var notes: String?
    
    
    enum ActivityImportance: String, CaseIterable{
        case minor = "Minor"
        case normal = "Normal"
        case urgent = "Urgent"
        
        var shade: Color{
            switch self{
            case .minor: return .cyan.opacity(0.7)
            case .normal: return .yellow.opacity(0.7)
            case .urgent: return .pink.opacity(0.7)
            }
        }
        
        
        var symbol: String{
            switch self{
            case .minor: return "circle.fill"
            case .normal: return "triangle.fill"
            case .urgent: return "exclamationmark.triangle.fill"
            }
        }
        
        
        
        
    }
    
    
}



// Mark: - Activity Group Model

struct ActivityGroup: Identifiable, Hashable{
    let id = UUID()
    var title: String
    var hue: Color
    var icon: String
    
    static let presets: [ActivityGroup] = [
        ActivityGroup(title:"Daily", hue: .indigo, icon: "sun.max"),
        ActivityGroup(title: "Career", hue: .teal, icon: "brifcase"),
        ActivityGroup(title: "Fitness", hue: .mint, icon: "figure.walk")
    ]
}


// Mark: Activity Manager (observableObject)

class ActivityManager: ObservableObject{
    @Published var activities: [Activity] = []
    @Published var groups: [ActivityGroup] = ActivityGroup.presets
    @Published var sortBy: SortOption = .name
    
    
    enum SortOption: String, CaseIterable{
        case name = "Name"
        case importance = "Importance"
        case dueDate = "Due Date"
    }
    
    
    init(){
        activities = [
            Activity(name: "Master SwiftUI", group: groups[1], importance: .urgent, dueDate: Date().addingTimeInterval(86400)),
            Activity(name: "Morning Yoga", group: groups[2], importance: .minor),
            Activity(name: "Get Supplies", group: groups[0], importance: .normal, notes: "Buy pens and notebooks")
        ]
    }
    
    func insertActivity(_ activity: Activity){
        withAnimation(.spring()){
            activities.append(activity)
        }
    }
    
    
    func eraseActivity(activity: Activity){
        withAnimation(.easeOut){
            activities.removeAll(){
                $0.id == activity.id
            }
        }

    }
    
    var sortedActivities: [Activity]{
        switch sortBy{
        case .name: return activities.sorted{
            $0.name<$1.name
        }
        case .importance: return activities.sorted{
            $0.importance.rawValue>$1.importance.rawValue
        }
        case .dueDate: return activities.sorted{
            ($0.dueDate ?? .distantFuture)<($1.dueDate ?? .distantFuture)
        }
        }
    }
    
    
}



// Mark: new activity panel

struct NewActivityPanel: View{
    @Environment(\.dismiss) var dismiss
    @ObservedObject var manager: ActivityManager
    @State private var name: String = ""
    @State private var selectedGroup: ActivityGroup = ActivityGroup.presets.first!
    @State private var selectedImportance: Activity.ActivityImportance = .normal
    @State private var dueDate: Date = Date()
    @State private var notes: String = ""
    @State private var includeDueDate: Bool = false
    
    var body: some View{
        
        NavigationStack{
            
            Form{
                Section(header: Text("Activity Details")){
                    TextField("Activity Name", text: $name)
                    
                    Picker("Group", selection: $selectedGroup){
                        ForEach(manager.groups, id: \.id){
                            group in Text(group.title).tag(group)
                        }
                    }
                    
                    Picker("Importance", selection: $selectedImportance){
                        ForEach(Activity.ActivityImportance.allCases, id: \.self){
                            importance in Text(importance.rawValue).tag(importance)
                        }
                    }
                    
                    Toggle("Set Due Date", isOn: $includeDueDate)
                    if includeDueDate{
                        DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
                    }
                    TextField("Notes", text: $notes)
                    
                }
            }
            
            .navigationTitle("New Activity")
            .toolbar{
                ToolbarItem(placement: .navigationBarLeading){
                    Button("Cancel"){
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing){
                    Button("Add"){
                        let newActivity = Activity(
                            name: name,
                            group: selectedGroup,
                            importance: selectedImportance,
                            dueDate: includeDueDate ? dueDate : nil,
                            notes: notes.isEmpty ? nil : notes
                        )
                        manager.insertActivity(newActivity)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
            
            
            
            
        }
        
    }
}








// MARK: - Main View (Activity Hub)


struct ContentView: View {
    @StateObject private var manager = ActivityManager()
    @State private var showNewActivity = false
    
    var body: some View {
        NavigationStack{
            VStack{
                Picker("Sort By", selection: $manager.sortBy){
                    ForEach(ActivityManager.SortOption.allCases, id:\.self){
                        option in Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding()
                
                List{
                    ForEach(manager.sortedActivities){
                        activity in HStack{
                            Image(systemName: activity.importance.symbol)
                                .foregroundColor(activity.importance.shade)
                            VStack(alignment: .leading){
                                Text(activity.name)
                                    .font(.headline)
                                
                                if let dueDate = activity.dueDate{
                                    Text("Due: \(dueDate.formatted(date: .abbreviated, time: .shortened))")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                            Spacer()
                            Image(systemName: activity.group.icon)
                                .foregroundColor(activity.group.hue)
                        }
                    }
                    .onDelete{
                        IndexSet in IndexSet.map{
                            manager.activities[$0]
                        }.forEach(manager.eraseActivity)
                    }
                    
                }
                .listStyle(InsetGroupedListStyle())
                Button(action: {showNewActivity = true}){
                    Label("New Activity", systemImage: "plus")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }
                .padding()
            }
            .navigationTitle("Activity Hub")
            
            .toolbar{
                ToolbarItem(placement: .navigationBarTrailing){
                    Button(action: { showNewActivity = true }){
                        Image(systemName: "plus.circle.fill")
                            .font(.title)
                    }
                }
            }
            .sheet(isPresented: $showNewActivity){
                NewActivityPanel(manager: manager)
            }
            
            
            
            

            }
        }
    }



// MARK: - Preview

#Preview {
    ContentView()
}
