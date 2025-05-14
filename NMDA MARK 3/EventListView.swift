//
//  EventListView.swift
//  NMDA MARK 3
//
//  Created by Matteo Ricci on 02/05/2025.
//

import SwiftUI

struct EventsListView: View {
    @ObservedObject var viewModel: FirestoreViewModel
    let householdId: String
    @State private var showingAddEvent = false
    @State private var selectedDate = Date()
    
    var body: some View {
        ZStack {
            if viewModel.isLoading {
                ProgressView("Loading events...")
            } else if viewModel.events.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 60))
                        .foregroundColor(AppTheme.primaryColor.opacity(0.5))
                    
                    Text("No Events")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Schedule events and activities\nwith your roommates.")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.gray)
                    
                    Button(action: {
                        showingAddEvent = true
                    }) {
                        Text("Add Your First Event")
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(AppTheme.primaryColor)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.top, 16)
                }
                .padding()
            } else {
                VStack {
                    // Date selector
                    DatePicker("Select Date", selection: $selectedDate, displayedComponents: [.date])
                        .datePickerStyle(GraphicalDatePickerStyle())
                        .padding()
                    
                    // Events for selected date
                    List {
                        ForEach(eventsForSelectedDate) { event in
                            EventRowView(event: event)
                        }
                    }
                }
            }
        }
        .navigationTitle("Events")
        .toolbar(content: {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingAddEvent = true
                }) {
                    Image(systemName: "plus")
                }
            }
        })
        .sheet(isPresented: $showingAddEvent) {
            AddEventView(viewModel: viewModel, householdId: householdId, initialDate: selectedDate)
        }
        .onAppear {
            viewModel.fetchEvents(householdId: householdId)
        }
    }
    
    var eventsForSelectedDate: [Event] {
        viewModel.events.filter { event in
            Calendar.current.isDate(event.startDate, inSameDayAs: selectedDate)
        }.sorted { $0.startDate < $1.startDate }
    }
}

// EventRow component for the list
struct EventRowView: View {
    let event: Event
    
    var body: some View {
        HStack(spacing: 12) {
            // Event color indicator
            Rectangle()
                .fill(event.color.color)
                .frame(width: 4)
                .cornerRadius(2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(AppTheme.bodyBoldFont)
                    .foregroundColor(AppTheme.textPrimary)
                    .lineLimit(2)
                
                if let description = event.description, !description.isEmpty {
                    Text(description)
                        .font(AppTheme.captionFont)
                        .foregroundColor(AppTheme.textSecondary)
                        .lineLimit(1)
                }
                
                HStack(spacing: 8) {
                    // Time
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 12))
                            .foregroundColor(AppTheme.textSecondary)
                        
                        Text(timeString)
                            .font(AppTheme.captionFont)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    
                    // Location if available
                    if let location = event.location, !location.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "location")
                                .font(.system(size: 12))
                                .foregroundColor(AppTheme.textSecondary)
                            
                            Text(location)
                                .font(AppTheme.captionFont)
                                .foregroundColor(AppTheme.textSecondary)
                                .lineLimit(1)
                        }
                    }
                    
                    Spacer()
                    
                    // All day indicator
                    if event.isAllDay {
                        Text("All Day")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(event.color.color)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(event.color.color.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
            }
            
            Spacer()
            
            // Attendee count
            if event.attendees.count > 1 {
                HStack(spacing: 2) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.textTertiary)
                    
                    Text("\(event.attendees.count)")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.textTertiary)
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    var timeString: String {
        if event.isAllDay {
            return "All Day"
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        
        let startTime = formatter.string(from: event.startDate)
        let endTime = formatter.string(from: event.endDate)
        
        return "\(startTime) - \(endTime)"
    }
}
