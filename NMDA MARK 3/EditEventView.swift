//
//  EditEventView.swift
//  NMDA MARK 3
//
//  Created by Matteo Ricci on 23/04/2025.
//
import SwiftUI
import Firebase

struct EditEventView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: FirestoreViewModel
    let householdId: String
    let event: Event
    let onSave: () -> Void
    
    @State private var title: String
    @State private var description: String
    @State private var location: String
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var isAllDay: Bool
    @State private var reminder: EventReminder
    @State private var color: EventColor
    @State private var recurrence: EventRecurrence
    @State private var attendees: [String]
    @State private var isProcessing = false
    @State private var errorMessage: String?
    
    // Placeholder for household members
    // In a real app, fetch this from Firebase
    let householdMembers = ["You", "Roommate 1", "Roommate 2"]
    
    init(viewModel: FirestoreViewModel, householdId: String, event: Event, onSave: @escaping () -> Void) {
        self.viewModel = viewModel
        self.householdId = householdId
        self.event = event
        self.onSave = onSave
        
        _title = State(initialValue: event.title)
        _description = State(initialValue: event.description ?? "")
        _location = State(initialValue: event.location ?? "")
        _startDate = State(initialValue: event.startDate)
        _endDate = State(initialValue: event.endDate)
        _isAllDay = State(initialValue: event.isAllDay)
        _reminder = State(initialValue: event.reminder ?? .none)
        _color = State(initialValue: event.color)
        _recurrence = State(initialValue: event.recurrence ?? .none)
        _attendees = State(initialValue: event.attendees)
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
                        updateEvent()
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
                                Text("Save Changes")
                                    .fontWeight(.semibold)
                                Spacer()
                            }
                        }
                    }
                    .disabled(isProcessing || !isFormValid)
                }
            }
            .navigationTitle("Edit Event")
            .navigationBarItems(leading: Button("Cancel") {
                dismiss()
            })
        }
    }
    
    private var isFormValid: Bool {
        return !title.isEmpty && startDate <= endDate && !attendees.isEmpty
    }
    
    private func updateEvent() {
        guard let eventId = event.id else { return }
        
        isProcessing = true
        errorMessage = nil
        
        let updatedEvent = Event(
            id: eventId,
            title: title,
            description: description.isEmpty ? nil : description,
            startDate: startDate,
            endDate: endDate,
            location: location.isEmpty ? nil : location,
            isAllDay: isAllDay,
            reminder: reminder,
            attendees: attendees,
            createdBy: event.createdBy,
            color: color,
            recurrence: recurrence
        )
        
        viewModel.updateEvent(householdId: householdId, event: updatedEvent) { success, error in
            DispatchQueue.main.async {
                self.isProcessing = false
                
                if let error = error {
                    self.errorMessage = error
                } else if success {
                    // If reminder is set, schedule local notification
                    if let reminderInterval = self.reminder.timeInterval() {
                        self.updateNotification(for: updatedEvent)
                    }
                    
                    self.onSave()
                    self.dismiss()
                }
            }
        }
    }
    
    private func updateNotification(for event: Event) {
        guard let eventId = event.id, let reminderInterval = reminder.timeInterval() else { return }
        
        // Remove existing notification
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["event-\(eventId)"])
        
        // Create new notification
        let content = UNMutableNotificationContent()
        content.title = event.title
        content.body = event.description ?? "Your event is upcoming"
        content.sound = .default
        
        // Calculate notification time
        let notificationTime = event.startDate.addingTimeInterval(reminderInterval)
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: notificationTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        // Create request
        let request = UNNotificationRequest(identifier: "event-\(eventId)", content: content, trigger: trigger)
        
        // Schedule notification
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            }
        }
    }
}

