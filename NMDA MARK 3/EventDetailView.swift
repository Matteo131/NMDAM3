//
//  EventDetailView.swift
//  NMDA MARK 3
//
//  Created by Matteo Ricci on 23/04/2025.
//


import SwiftUI
import Firebase

struct EventDetailView: View {
    let event: Event
    @ObservedObject var viewModel: FirestoreViewModel
    let householdId: String
    @State private var isShowingDeleteAlert = false
    @State private var isEditing = false
    @State private var isDeleting = false
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Event header
                VStack(spacing: 8) {
                    Text(event.title)
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    EventTimeRow(event: event)
                        .padding(.vertical, 4)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(event.color.color.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Event details
                VStack(alignment: .leading, spacing: 16) {
                    if let description = event.description, !description.isEmpty {
                        DetailSection(title: "Description", icon: "text.alignleft") {
                            Text(description)
                                .foregroundColor(.primary)
                        }
                    }
                    
                    if let location = event.location, !location.isEmpty {
                        DetailSection(title: "Location", icon: "mappin.and.ellipse") {
                            Text(location)
                                .foregroundColor(.primary)
                        }
                    }
                    
                    DetailSection(title: "Calendar", icon: "calendar") {
                        HStack {
                            Circle()
                                .fill(event.color.color)
                                .frame(width: 12, height: 12)
                            
                            Text(event.color.rawValue)
                                .foregroundColor(.primary)
                        }
                    }
                    
                    if event.recurrence != .none {
                        DetailSection(title: "Repeat", icon: "repeat") {
                            Text(event.recurrence?.rawValue ?? "Does not repeat")
                                .foregroundColor(.primary)
                        }
                    }
                    
                    if event.reminder != .none {
                        DetailSection(title: "Alert", icon: "bell") {
                            Text(event.reminder?.rawValue ?? "None")
                                .foregroundColor(.primary)
                        }
                    }
                    
                    DetailSection(title: "Attendees", icon: "person.2") {
                        ForEach(event.attendees, id: \.self) { attendee in
                            HStack {
                                Text(attendee)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Text("Going")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                .padding(.horizontal)
                
                // Buttons
                HStack(spacing: 16) {
                    Button(action: {
                        isEditing = true
                    }) {
                        Label("Edit", systemImage: "pencil")
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color(.systemBackground))
                            .foregroundColor(AppTheme.primaryColor)
                            .cornerRadius(10)
                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    }
                    
                    Button(action: {
                        isShowingDeleteAlert = true
                    }) {
                        Label("Delete", systemImage: "trash")
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color(.systemBackground))
                            .foregroundColor(.red)
                            .cornerRadius(10)
                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    }
                }
                .padding(.horizontal)
                .disabled(isDeleting)
            }
            .padding(.vertical)
        }
        .navigationTitle("Event Details")
        .alert(isPresented: $isShowingDeleteAlert) {
            Alert(
                title: Text("Delete Event"),
                message: Text("Are you sure you want to delete this event? This action cannot be undone."),
                primaryButton: .destructive(Text("Delete")) {
                    deleteEvent()
                },
                secondaryButton: .cancel()
            )
        }
        .sheet(isPresented: $isEditing) {
            EditEventView(
                viewModel: viewModel,
                householdId: householdId,
                event: event,
                onSave: {
                    self.isEditing = false
                    self.presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
    
    private func deleteEvent() {
        guard let eventId = event.id else { return }
        isDeleting = true
        
        viewModel.deleteEvent(householdId: householdId, eventId: eventId) { success, error in
            DispatchQueue.main.async {
                self.isDeleting = false
                
                if success {
                    self.presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
}

struct EventTimeRow: View {
    let event: Event
    
    var body: some View {
        HStack {
            Image(systemName: "clock")
                .foregroundColor(.secondary)
            
            if event.isAllDay {
                Text("All day · \(formatDate(event.startDate))")
                    .foregroundColor(.secondary)
            } else if Calendar.current.isDate(event.startDate, inSameDayAs: event.endDate) {
                Text("\(formatDate(event.startDate)) · \(formatTime(event.startDate)) - \(formatTime(event.endDate))")
                    .foregroundColor(.secondary)
            } else {
                Text("\(formatDate(event.startDate)) \(formatTime(event.startDate)) - \(formatDate(event.endDate)) \(formatTime(event.endDate))")
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct DetailSection<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    
    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.secondary)
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            
            content
                .padding(.leading, 28)
        }
    }
}
