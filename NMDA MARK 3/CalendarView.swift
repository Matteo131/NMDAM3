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
    
    enum CalendarViewMode {
        case day, week, month
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Calendar header with view mode selector
            HStack {
                Picker("View", selection: $calendarViewMode) {
                    Text("Day").tag(CalendarViewMode.day)
                    Text("Week").tag(CalendarViewMode.week)
                    Text("Month").tag(CalendarViewMode.month)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.trailing)
                
                Spacer()
                
                Button(action: {
                    selectedDate = Date()
                }) {
                    Text("Today")
                        .fontWeight(.medium)
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
            
            // Calendar view
            Group {
                switch calendarViewMode {
                case .day:
                    DayView(date: $selectedDate, events: eventsForSelectedDay)
                case .week:
                    WeekView(selectedDate: $selectedDate, events: eventsForSelectedWeek)
                case .month:
                    MonthView(selectedDate: $selectedDate, events: currentMonthEvents, onDateSelected: { date in
                        self.selectedDate = date
                        self.calendarViewMode = .day
                    })
                }
            }
            .padding(.top)
            
            // Events for selected day
            VStack(alignment: .leading) {
                Text(formattedSelectedDate)
                    .font(.headline)
                    .padding(.horizontal)
                
                if eventsForSelectedDay.isEmpty {
                    HStack {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "calendar.badge.plus")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                            Text("No events for this day")
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 30)
                        Spacer()
                    }
                } else {
                    List {
                        ForEach(eventsForSelectedDay) { event in
                            NavigationLink(destination: EventDetailView(event: event, viewModel: viewModel, householdId: householdId)) {
                                EventRow(event: event)
                            }
                        }
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
                }
            }
        }
        .sheet(isPresented: $showingAddEvent) {
            AddEventView(viewModel: viewModel, householdId: householdId, initialDate: selectedDate)
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
    
    var formattedSelectedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: selectedDate)
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
}

// MARK: - Day View Components

struct DayView: View {
    @Binding var date: Date
    let events: [Event]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(0..<24, id: \.self) { hour in
                    HStack {
                        Text(formatHour(hour))
                            .font(.caption)
                            .frame(width: 50, alignment: .trailing)
                        
                        // Events at this hour
                        ZStack(alignment: .topLeading) {
                            Rectangle()
                                .fill(Color.gray.opacity(0.1))
                                .frame(height: 60)
                            
                            // Display events for this hour
                            ForEach(eventsForHour(hour), id: \.id) { event in
                                EventTimeBlock(event: event)
                            }
                        }
                    }
                    
                    Divider()
                }
            }
            .padding(.horizontal)
        }
    }
    
    private func formatHour(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        
        var components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        components.hour = hour
        
        if let date = Calendar.current.date(from: components) {
            return formatter.string(from: date)
        }
        
        return "\(hour)"
    }
    
    private func eventsForHour(_ hour: Int) -> [Event] {
        return events.filter { event in
            let eventHour = Calendar.current.component(.hour, from: event.startDate)
            return eventHour == hour
        }
    }
}

struct EventTimeBlock: View {
    let event: Event
    
    var body: some View {
        HStack {
            Rectangle()
                .fill(event.color.color)
                .frame(width: 4)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                if let location = event.location, !location.isEmpty {
                    Text(location)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 6)
        }
        .background(event.color.color.opacity(0.1))
        .cornerRadius(4)
    }
}

// MARK: - Week View Components

struct WeekView: View {
    @Binding var selectedDate: Date
    let events: [Event]
    
    var body: some View {
        VStack {
            // Week day headers
            HStack(spacing: 0) {
                ForEach(weekDays, id: \.self) { date in
                    VStack {
                        Text(formatWeekDay(date))
                            .font(.caption)
                        
                        Text(formatDay(date))
                            .font(.headline)
                            .padding(8)
                            .background(
                                Circle()
                                    .fill(isSelectedDate(date) ? AppTheme.primaryColor : Color.clear)
                            )
                            .foregroundColor(isSelectedDate(date) ? .white : .primary)
                    }
                    .frame(maxWidth: .infinity)
                    .onTapGesture {
                        selectedDate = date
                    }
                }
            }
            .padding(.horizontal)
            
            Divider()
            
            // Day view for selected date
            DayView(date: $selectedDate, events: eventsForDate(selectedDate))
        }
    }
    
    private var weekDays: [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: selectedDate)
        
        var weekdays = [Date]()
        // Find the start of the week (Sunday)
        let weekday = calendar.component(.weekday, from: today)
        let daysToSubtract = weekday - 1 // 1 is Sunday in most calendar systems
        
        if let startOfWeek = calendar.date(byAdding: .day, value: -daysToSubtract, to: today) {
            // Add each day of the week
            for i in 0..<7 {
                if let day = calendar.date(byAdding: .day, value: i, to: startOfWeek) {
                    weekdays.append(day)
                }
            }
        }
        
        return weekdays
    }
    
    private func formatWeekDay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
    
    private func formatDay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    private func isSelectedDate(_ date: Date) -> Bool {
        Calendar.current.isDate(date, inSameDayAs: selectedDate)
    }
    
    private func eventsForDate(_ date: Date) -> [Event] {
        return events.filter { event in
            Calendar.current.isDate(event.startDate, inSameDayAs: date)
        }
    }
}

// MARK: - Month View Components

struct MonthView: View {
    @Binding var selectedDate: Date
    let events: [Event]
    let onDateSelected: (Date) -> Void
    
    @State private var monthOffset = 0
    
    var body: some View {
        VStack(spacing: 20) {
            // Month header
            HStack {
                Button(action: {
                    monthOffset -= 1
                }) {
                    Image(systemName: "chevron.left")
                }
                
                Spacer()
                
                Text(monthYearString)
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    monthOffset += 1
                }) {
                    Image(systemName: "chevron.right")
                }
            }
            .padding(.horizontal)
            
            // Day of week headers
            HStack {
                ForEach(daysOfWeek, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Calendar grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
                ForEach(days, id: \.self) { date in
                    if date.isPlaceholder {
                        Text("")
                            .frame(height: 40)
                    } else {
                        CalendarDayCell(
                            date: date.date,
                            isSelected: Calendar.current.isDate(date.date, inSameDayAs: selectedDate),
                            events: eventsForDate(date.date),
                            onTap: onDateSelected
                        )
                    }
                }
            }
        }
    }
    
    var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentMonth)
    }
    
    var currentMonth: Date {
        let calendar = Calendar.current
        let today = Date()
        
        guard let month = calendar.date(byAdding: .month, value: monthOffset, to: today),
              let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: month)) else {
            return today
        }
        
        return startOfMonth
    }
    
    var daysOfWeek: [String] {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        
        let weekdays = formatter.shortWeekdaySymbols ?? []
        
        // Adjust for calendar's first day of week if needed
        // This assumes Sunday is the first day (index 0)
        return weekdays
    }
    
    var days: [CalendarDay] {
        let calendar = Calendar.current
        let today = currentMonth
        
        // Get the first day of the month
        guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: today)),
              // Get the last day of the month
              let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) else {
            return []
        }
        
        let numberOfDaysInMonth = calendar.component(.day, from: endOfMonth)
        
        // Get the weekday of the first day (0 is Sunday, 6 is Saturday)
        let firstWeekday = calendar.component(.weekday, from: startOfMonth)
        
        // Account for 1-based weekday index
        let offsetFirstDay = firstWeekday - 1
        
        var days = [CalendarDay]()
        
        // Add placeholders for the days before the 1st of the month
        for _ in 0..<offsetFirstDay {
            days.append(CalendarDay(date: Date(), isPlaceholder: true))
        }
        
        // Add all days of the month
        for day in 1...numberOfDaysInMonth {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                days.append(CalendarDay(date: date, isPlaceholder: false))
            }
        }
        
        return days
    }
    
    func eventsForDate(_ date: Date) -> [Event] {
        return events.filter { event in
            Calendar.current.isDate(event.startDate, inSameDayAs: date)
        }
    }
}

struct CalendarDay: Hashable {
    let id = UUID()
    let date: Date
    let isPlaceholder: Bool
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: CalendarDay, rhs: CalendarDay) -> Bool {
        return lhs.id == rhs.id
    }
}

struct CalendarDayCell: View {
    let date: Date
    let isSelected: Bool
    let events: [Event]
    let onTap: (Date) -> Void
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(day)")
                .font(.system(size: 16))
                .fontWeight(isToday ? .bold : .regular)
                .foregroundColor(
                    isSelected ? .white :
                        isToday ? AppTheme.primaryColor : .primary
                )
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(isSelected ? AppTheme.primaryColor : Color.clear)
                )
                .overlay(
                    Circle()
                        .stroke(isToday && !isSelected ? AppTheme.primaryColor : Color.clear, lineWidth: 1)
                )
            
            // Event indicators (show up to 3 events)
            if !events.isEmpty {
                HStack(spacing: 2) {
                    ForEach(events.prefix(3), id: \.id) { event in
                        Circle()
                            .fill(event.color.color)
                            .frame(width: 6, height: 6)
                    }
                }
                
                if events.count > 3 {
                    Text("+\(events.count - 3)")
                        .font(.system(size: 8))
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(height: 50)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap(date)
        }
    }
    
    var day: Int {
        Calendar.current.component(.day, from: date)
    }
    
    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
}

// MARK: - Event Row Component

struct EventRow: View {
    let event: Event
    
    var body: some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(event.color.color)
                .frame(width: 4)
                .cornerRadius(2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.headline)
                
                Text(timeString)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let location = event.location, !location.isEmpty {
                    Text(location)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if event.isAllDay {
                Text("All Day")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(4)
            }
        }
        .padding(.vertical, 4)
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
