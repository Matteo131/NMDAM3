//
//  RecurringChoreView.swift
//  NMDA MARK 3
//
//  Created by Matteo Ricci on 10/05/2025.
//

import SwiftUI

struct RecurringChoreView: View {
    @Binding var isRecurring: Bool
    @Binding var recurrence: ChoreRecurrence?
    
    @State private var frequency: RecurrenceFrequency = .weekly
    @State private var selectedDaysOfWeek: Set<Int> = []
    @State private var selectedDayOfMonth: Int = 1
    
    let daysOfWeek = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Toggle("Recurring Chore", isOn: $isRecurring)
                .font(AppTheme.bodyFont)
            
            if isRecurring {
                // Frequency picker
                Picker("Frequency", selection: $frequency) {
                    ForEach(RecurrenceFrequency.allCases, id: \.self) { freq in
                        Text(freq.rawValue).tag(freq)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                
                // Additional options based on frequency
                if frequency == .weekly {
                    Text("Repeat on:")
                        .font(AppTheme.subheadlineFont)
                    
                    HStack {
                        ForEach(0..<7) { day in
                            Button(action: {
                                if selectedDaysOfWeek.contains(day) {
                                    selectedDaysOfWeek.remove(day)
                                } else {
                                    selectedDaysOfWeek.insert(day)
                                }
                            }) {
                                Text(daysOfWeek[day])
                                    .font(.caption)
                                    .frame(width: 40, height: 40)
                                    .background(selectedDaysOfWeek.contains(day) ?
                                               AppTheme.primaryColor : Color.gray.opacity(0.2))
                                    .foregroundColor(selectedDaysOfWeek.contains(day) ? .white : .black)
                                    .cornerRadius(8)
                            }
                        }
                    }
                } else if frequency == .monthly {
                    Stepper("Day of month: \(selectedDayOfMonth)", value: $selectedDayOfMonth, in: 1...31)
                        .font(AppTheme.bodyFont)
                }
            }
        }
        .onChange(of: isRecurring) { newValue in
            if newValue {
                recurrence = ChoreRecurrence(
                    frequency: frequency,
                    daysOfWeek: Array(selectedDaysOfWeek),
                    dayOfMonth: selectedDayOfMonth,
                    nextDueDate: Date()
                )
            } else {
                recurrence = nil
            }
        }
        .onChange(of: frequency) { newValue in
            updateRecurrence()
        }
        .onChange(of: selectedDaysOfWeek) { _ in
            updateRecurrence()
        }
        .onChange(of: selectedDayOfMonth) { _ in
            updateRecurrence()
        }
    }
    
    private func updateRecurrence() {
        if isRecurring {
            recurrence = ChoreRecurrence(
                frequency: frequency,
                daysOfWeek: frequency == .weekly ? Array(selectedDaysOfWeek) : nil,
                dayOfMonth: frequency == .monthly ? selectedDayOfMonth : nil,
                nextDueDate: Date()
            )
        }
    }
}
