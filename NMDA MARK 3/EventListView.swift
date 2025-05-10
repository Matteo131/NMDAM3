//
//  EventListView.swift
//  NMDA MARK 3
//
//  Created by Matteo Ricci on 02/05/2025.
//
// Create EventsListView.swift
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
                            EventRow(event: event)
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
