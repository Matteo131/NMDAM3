//
//  AddEventView.swift
//  NMDA MARK 3
//
//  Created by Matteo Ricci on 23/04/2025.
//

import SwiftUI
import Firebase
import FirebaseAuth

struct AddEventView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: FirestoreViewModel
    let householdId: String
    let initialDate: Date
    
    @State private var title = ""
    @State private var description = ""
    @State private var location = ""
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var isAllDay = false
    @State private var reminder: EventReminder = .thirtyMinutes
    @State private var color: EventColor = .blue
    @State private var recurrence: EventRecurrence = .none
    @State private var attendees: [String] = []
    @State private var isProcessing = false
    @State private var errorMessage: String?
    
    // Placeholder for household members
    // In a real app, fetch this from Firebase
    @State private var householdMembers: [String] = []
    
    init(viewModel: FirestoreViewModel, householdId: String, initialDate: Date) {
        self.viewModel = viewModel
        self.householdId = householdId
        self.initialDate = initialDate
        
        // Initialize dates to the initial date with appropriate time
        let calendar = Calendar.current
        var startComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: initialDate)
        startComponents.hour = 9
        startComponents.minute = 0
        
        var endComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: initialDate)
        endComponents.hour = 10
        endComponents.minute = 0
        
        _startDate = State(initialValue: calendar.date(from: startComponents) ?? initialDate)
        _endDate = State(initialValue: calendar.date(from: endComponents) ?? initialDate)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("EVENT DETAILS")) {
                    TextField("Title", text: $title)
                    
                    TextField("Description (optional)", text: $description)
                    
                    TextField("Location (optional)", text: $location)
                }
                
                Section(header: Text("DATE & TIME")) {
                    Toggle("All Day", isOn: $isAllDay)
                    
                    if isAllDay {
                        DatePicker("Start Date", selection: $startDate, displayedComponents: [.date])
                        
                        DatePicker("End Date", selection: $endDate, displayedComponents: [.date])
                    } else {
                        DatePicker("Start", selection: $startDate)
                        
                        DatePicker("End", selection: $endDate)
                    }
                }
                
                Section(header: Text("ATTENDEES")) {
                    ForEach(householdMembers, id: \.self) { member in
                        Toggle(member, isOn: Binding(
                            get: { attendees.contains(member) },
                            set: { isIncluded in
                                if isIncluded {
                                    attendees.append(member)
                                } else {
                                    attendees.removeAll { $0 == member }
                                }
                            }
                        ))
                    }
                }
                
                Section(header: Text("OPTIONS")) {
                    Picker("Reminder", selection: $reminder) {
                        ForEach(EventReminder.allCases, id: \.self) { reminder in
                            Text(reminder.rawValue).tag(reminder)
                        }
                    }
                    
                    Picker("Color", selection: $color) {
                        ForEach(EventColor.allCases, id: \.self) { color in
                            HStack {
                                Circle()
                                    .fill(color.color)
                                    .frame(width: 20, height: 20)
                                Text(color.rawValue)
                            }
                            .tag(color)
                        }
                    }
                    
                    Picker("Repeat", selection: $recurrence) {
                        ForEach(EventRecurrence.allCases, id: \.self) { recurrence in
                            Text(recurrence.rawValue).tag(recurrence)
                        }
                    }
                }
                
                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                
                Section {
                    Button(action: {
                        addEvent()
                    }) {
                        if isProcessing {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                        } else {
                            HStack {
                                Spacer()
                                Text("Add Event")
                                    .fontWeight(.semibold)
                                Spacer()
                            }
                        }
                    }
                    .disabled(isProcessing || !isFormValid)
                }
            }
            .navigationTitle("Add Event")
            .navigationBarItems(leading: Button("Cancel") {
                dismiss()
            })
        }
        .onAppear {
                    // Check if we have actual members
                    if householdMembers.isEmpty {
                        if let currentUser = Auth.auth().currentUser?.displayName {
                            householdMembers = [currentUser]
                        } else {
                            householdMembers = ["You"]
                        }
                    }
                }
            }
        
    
    private var isFormValid: Bool {
        return !title.isEmpty && startDate <= endDate && !attendees.isEmpty
    }
    
    private func addEvent() {
        isProcessing = true
        errorMessage = nil
        
        let event = Event(
            id: nil,
            title: title,
            description: description.isEmpty ? nil : description,
            startDate: startDate,
            endDate: endDate,
            location: location.isEmpty ? nil : location,
            isAllDay: isAllDay,
            reminder: reminder,
            attendees: attendees,
            createdBy: "You", // In a real app, use current user's ID
            color: color,
            recurrence: recurrence
        )
        
        viewModel.addEvent(householdId: householdId, event: event) { success, error in
            DispatchQueue.main.async {
                self.isProcessing = false
                
                if let error = error {
                    self.errorMessage = error
                } else if success {
                    // If reminder is set, schedule local notification
                    if let reminderInterval = self.reminder.timeInterval() {
                        self.scheduleNotification(for: event)
                    }
                    
                    self.dismiss()
                }
            }
        }
    }
    
    private func scheduleNotification(for event: Event) {
        guard let reminderInterval = reminder.timeInterval() else { return }
        
        let content = UNMutableNotificationContent()
        content.title = event.title
        content.body = event.description ?? "Your event is upcoming"
        content.sound = .default
        
        // Calculate notification time
        let notificationTime = event.startDate.addingTimeInterval(reminderInterval)
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: notificationTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        // Create request
        let identifier = "event-\(UUID().uuidString)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        // Schedule notification
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            }
        }
    }
}
