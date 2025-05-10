import SwiftUI
import EventKit

struct CalendarEventView: View {
    @ObservedObject var viewModel: FirestoreViewModel
    let householdId: String
    @State private var selectedDate = Date()
    @State private var showingAddEvent = false
    @State private var showEventAddedAlert = false
    @State private var lastAddedEvent: String = ""
    
    var body: some View {
        VStack {
            // Calendar date picker
            DatePicker(
                "Select Date",
                selection: $selectedDate,
                displayedComponents: [.date]
            )
            .datePickerStyle(GraphicalDatePickerStyle())
            .padding()
            
            // Events list
            if viewModel.events.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    
                    Text("No events found")
                        .font(.headline)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(eventsForSelectedDate) { event in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(event.title)
                                .font(.headline)
                            
                            if let description = event.description, !description.isEmpty {
                                Text(description)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack {
                                Image(systemName: "clock")
                                    .foregroundColor(.secondary)
                                
                                if event.isAllDay {
                                    Text("All day")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                } else {
                                    Text("\(formatTime(event.startDate)) - \(formatTime(event.endDate))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Button(action: {
                                    addToSystemCalendar(event)
                                }) {
                                    Image(systemName: "calendar.badge.plus")
                                        .foregroundColor(AppTheme.primaryColor)
                                }
                            }
                        }
                        .padding(.vertical, 8)
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
            viewModel.fetchEvents(householdId: householdId)
        }
        .alert(isPresented: $showEventAddedAlert) {
            Alert(
                title: Text("Event Added"),
                message: Text("\"\(lastAddedEvent)\" has been added to your device calendar"),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    var eventsForSelectedDate: [Event] {
        return viewModel.events.filter { event in
            Calendar.current.isDate(event.startDate, inSameDayAs: selectedDate)
        }.sorted { $0.startDate < $1.startDate }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func addToSystemCalendar(_ event: Event) {
        let eventStore = EKEventStore()
        
        eventStore.requestAccess(to: .event) { granted, error in
            if granted && error == nil {
                let ekEvent = EKEvent(eventStore: eventStore)
                ekEvent.title = event.title
                ekEvent.startDate = event.startDate
                ekEvent.endDate = event.endDate
                ekEvent.notes = event.description
                ekEvent.isAllDay = event.isAllDay
                
                ekEvent.calendar = eventStore.defaultCalendarForNewEvents
                
                do {
                    try eventStore.save(ekEvent, span: .thisEvent)
                    DispatchQueue.main.async {
                        lastAddedEvent = event.title
                        showEventAddedAlert = true
                    }
                } catch {
                    print("Error saving event to calendar: \(error.localizedDescription)")
                }
            } else {
                print("Calendar access denied")
            }
        }
    }
}
