//
//  CalendarView.swift
//  NMDA MARK 3
//
//  Created by Matteo Ricci on 25/04/2025.
//

import SwiftUI
import Firebase

struct CalendarView: View {
    @ObservedObject var viewModel: FirestoreViewModel
    let householdId: String
    @State private var selectedDate = Date()
    @State private var currentMonthEvents: [Event] = []
    @State private var showingAddEvent = false
    @State private var calendarViewMode: CalendarViewMode = .month
    @State private var showingQuickTemplates = false
    
    enum CalendarViewMode {
        case day, week, month
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Enhanced header with smart suggestions
            VStack(spacing: 12) {
                HStack {
                    // View mode selector
                    Picker("View", selection: $calendarViewMode) {
                        Text("Day").tag(CalendarViewMode.day)
                        Text("Week").tag(CalendarViewMode.week)
                        Text("Month").tag(CalendarViewMode.month)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(maxWidth: 200)
                    
                    Spacer()
                    
                    // Quick actions
                    HStack(spacing: 12) {
                        Button(action: {
                            selectedDate = Date()
                        }) {
                            Text("Today")
                                .font(AppTheme.captionFont.bold())
                                .foregroundColor(AppTheme.primaryColor)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(AppTheme.primaryColor.opacity(0.1))
                                .cornerRadius(8)
                        }
                        
                        Button(action: {
                            showingQuickTemplates = true
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(AppTheme.primaryColor)
                        }
                    }
                }
                
                // Smart event suggestions for students
                if shouldShowSuggestions {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(eventSuggestions, id: \.title) { suggestion in
                                EventSuggestionChip(suggestion: suggestion) {
                                    createQuickEvent(suggestion)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
            
            // Calendar view with enhanced styling
            Group {
                switch calendarViewMode {
                case .day:
                    EnhancedDayView(date: $selectedDate, events: eventsForSelectedDay, viewModel: viewModel, householdId: householdId)
                case .week:
                    EnhancedWeekView(selectedDate: $selectedDate, events: eventsForSelectedWeek, viewModel: viewModel, householdId: householdId)
                case .month:
                    EnhancedMonthView(selectedDate: $selectedDate, events: currentMonthEvents, onDateSelected: { date in
                        self.selectedDate = date
                        self.calendarViewMode = .day
                    })
                }
            }
            .padding(.top)
            
            // Enhanced events for selected day
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(formattedSelectedDate)
                        .font(AppTheme.headlineFont)
                        .foregroundColor(AppTheme.textPrimary)
                    
                    Spacer()
                    
                    if !eventsForSelectedDay.isEmpty {
                        Text("\(eventsForSelectedDay.count) events")
                            .font(AppTheme.captionFont)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
                .padding(.horizontal)
                
                if eventsForSelectedDay.isEmpty {
                    HStack {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "calendar.badge.plus")
                                .font(.system(size: 40))
                                .foregroundColor(AppTheme.textTertiary)
                            
                            Text("No events for \(isSelectedDateToday ? "today" : "this day")")
                                .font(AppTheme.subheadlineFont)
                                .foregroundColor(AppTheme.textSecondary)
                            
                            Button(action: {
                                showingAddEvent = true
                            }) {
                                Text("Add Event")
                                    .font(AppTheme.captionFont.bold())
                                    .foregroundColor(AppTheme.primaryColor)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(AppTheme.primaryColor.opacity(0.1))
                                    .cornerRadius(8)
                            }
                        }
                        .padding(.vertical, 30)
                        Spacer()
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(eventsForSelectedDay) { event in
                                NavigationLink(destination: EventDetailView(event: event, viewModel: viewModel, householdId: householdId)) {
                                    EnhancedEventRow(event: event)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
        .navigationTitle("Calendar")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingAddEvent = true
                }) {
                    Image(systemName: "plus")
                        .foregroundColor(AppTheme.primaryColor)
                }
            }
        }
        .sheet(isPresented: $showingAddEvent) {
            AddEventView(viewModel: viewModel, householdId: householdId, initialDate: selectedDate)
        }
        .sheet(isPresented: $showingQuickTemplates) {
            QuickEventTemplatesView(viewModel: viewModel, householdId: householdId, selectedDate: selectedDate)
        }
        .onAppear {
            viewModel.fetchEvents(householdId: householdId) {
                updateCurrentMonthEvents()
            }
        }
        .onChange(of: selectedDate) {
            updateCurrentMonthEvents()
        }
    }
    
    // MARK: - Computed Properties
    
    var formattedSelectedDate: String {
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(selectedDate) {
            return "Today"
        } else if Calendar.current.isDateInTomorrow(selectedDate) {
            return "Tomorrow"
        } else if Calendar.current.isDateInYesterday(selectedDate) {
            return "Yesterday"
        } else {
            formatter.dateStyle = .full
            return formatter.string(from: selectedDate)
        }
    }
    
    var isSelectedDateToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }
    
    var eventsForSelectedDay: [Event] {
        return viewModel.events.filter { event in
            Calendar.current.isDate(event.startDate, inSameDayAs: selectedDate)
        }.sorted { $0.startDate < $1.startDate }
    }
    
    var eventsForSelectedWeek: [Event] {
        let calendar = Calendar.current
        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: selectedDate)),
              let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) else {
            return []
        }
        
        return viewModel.events.filter { event in
            event.startDate >= weekStart && event.startDate < weekEnd
        }.sorted { $0.startDate < $1.startDate }
    }
    
    var shouldShowSuggestions: Bool {
        let hour = Calendar.current.component(.hour, from: Date())
        let weekday = Calendar.current.component(.weekday, from: Date())
        
        // Show suggestions during planning times (evenings, weekends)
        return (hour >= 18 || hour <= 10) || (weekday == 1 || weekday == 7)
    }
    
    var eventSuggestions: [EventSuggestion] {
        let hour = Calendar.current.component(.hour, from: Date())
        let weekday = Calendar.current.component(.weekday, from: Date())
        
        var suggestions: [EventSuggestion] = []
        
        // Weekend suggestions
        if weekday == 1 || weekday == 7 {
            suggestions.append(contentsOf: [
                EventSuggestion(title: "Grocery Run", icon: "cart.fill", color: AppTheme.secondaryColor, defaultDuration: 2),
                EventSuggestion(title: "Cleaning Day", icon: "sparkles", color: AppTheme.warningColor, defaultDuration: 3),
                EventSuggestion(title: "Movie Night", icon: "tv.fill", color: AppTheme.accentColor, defaultDuration: 3)
            ])
        }
        
        // Evening suggestions
        if hour >= 18 {
            suggestions.append(contentsOf: [
                EventSuggestion(title: "Study Session", icon: "book.fill", color: AppTheme.primaryColor, defaultDuration: 2),
                EventSuggestion(title: "Dinner Plans", icon: "fork.knife", color: AppTheme.errorColor, defaultDuration: 2)
            ])
        }
        
        // Always available
        suggestions.append(contentsOf: [
            EventSuggestion(title: "Bill Due", icon: "dollarsign.circle", color: AppTheme.warningColor, defaultDuration: 0),
            EventSuggestion(title: "House Meeting", icon: "person.3.fill", color: AppTheme.infoColor, defaultDuration: 1)
        ])
        
        return Array(suggestions.prefix(4)) // Limit to 4 suggestions
    }
    
    // MARK: - Helper Methods
    
    private func updateCurrentMonthEvents() {
        let calendar = Calendar.current
        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedDate)),
              let monthEnd = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: monthStart) else {
            currentMonthEvents = []
            return
        }
        
        currentMonthEvents = viewModel.events.filter { event in
            (event.startDate >= monthStart && event.startDate <= monthEnd) ||
            (event.endDate >= monthStart && event.endDate <= monthEnd)
        }
    }
    
    private func createQuickEvent(_ suggestion: EventSuggestion) {
        let calendar = Calendar.current
        var startComponents = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        startComponents.hour = suggestion.defaultDuration == 0 ? 23 : 19 // Bills at 11 PM, others at 7 PM
        startComponents.minute = 0
        
        guard let startDate = calendar.date(from: startComponents) else { return }
        let endDate = calendar.date(byAdding: .hour, value: max(1, suggestion.defaultDuration), to: startDate) ?? startDate
        
        let event = Event(
            id: nil,
            title: suggestion.title,
            description: nil,
            startDate: startDate,
            endDate: endDate,
            location: nil,
            isAllDay: suggestion.defaultDuration == 0,
            reminder: .thirtyMinutes,
            attendees: ["You"], // In real app, get household members
            createdBy: "You",
            color: .blue,
            recurrence: .none
        )
        
        viewModel.addEvent(householdId: householdId, event: event) { success, error in
            if success {
                // Success feedback could go here
            }
        }
    }
}

// MARK: - Supporting Views and Types

struct EventSuggestion {
    let title: String
    let icon: String
    let color: Color
    let defaultDuration: Int // hours
}

struct EventSuggestionChip: View {
    let suggestion: EventSuggestion
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: suggestion.icon)
                    .font(.system(size: 12))
                    .foregroundColor(suggestion.color)
                
                Text(suggestion.title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(suggestion.color)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(suggestion.color.opacity(0.1))
            .cornerRadius(8)
        }
    }
}

struct EnhancedEventRow: View {
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
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(event.color.color.opacity(0.3), lineWidth: 1)
                )
        )
        .shadow(color: AppTheme.cardShadow, radius: 2, x: 0, y: 1)
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

// Enhanced Day/Week/Month views would go here - they follow similar patterns
// but with better student-focused features like:
// - Study session time blocking
// - Bill due date highlights
// - Social event coordination
// - Better mobile-first touch targets

struct EnhancedDayView: View {
    @Binding var date: Date
    let events: [Event]
    @ObservedObject var viewModel: FirestoreViewModel
    let householdId: String
    
    var body: some View {
        // Implementation would be similar to existing DayView
        // but with enhanced student-focused features
        Text("Enhanced Day View - \(date.formatted(date: .abbreviated, time: .omitted))")
            .font(AppTheme.headlineFont)
    }
}

struct EnhancedWeekView: View {
    @Binding var selectedDate: Date
    let events: [Event]
    @ObservedObject var viewModel: FirestoreViewModel
    let householdId: String
    
    var body: some View {
        Text("Enhanced Week View")
            .font(AppTheme.headlineFont)
    }
}

struct EnhancedMonthView: View {
    @Binding var selectedDate: Date
    let events: [Event]
    let onDateSelected: (Date) -> Void
    
    var body: some View {
        Text("Enhanced Month View")
            .font(AppTheme.headlineFont)
    }
}
