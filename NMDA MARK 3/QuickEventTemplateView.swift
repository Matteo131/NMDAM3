//
//  QuickEventTemplateView.swift
//  NMDA MARK 3
//
//  Created by Matteo Ricci on 19/06/2025.
//

//
//  QuickEventTemplatesView.swift
//  NMDA MARK 3
//

import SwiftUI

struct QuickEventTemplatesView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: FirestoreViewModel
    let householdId: String
    let selectedDate: Date
    
    private let templates = [
        EventTemplate(
            title: "Study Session",
            icon: "book.fill",
            color: AppTheme.primaryColor,
            defaultDuration: 2,
            category: "Academic"
        ),
        EventTemplate(
            title: "Grocery Run",
            icon: "cart.fill",
            color: AppTheme.secondaryColor,
            defaultDuration: 1,
            category: "Household"
        ),
        EventTemplate(
            title: "Movie Night",
            icon: "tv.fill",
            color: AppTheme.accentColor,
            defaultDuration: 3,
            category: "Social"
        ),
        EventTemplate(
            title: "Cleaning Day",
            icon: "sparkles",
            color: AppTheme.warningColor,
            defaultDuration: 2,
            category: "Household"
        ),
        EventTemplate(
            title: "Bill Due",
            icon: "dollarsign.circle",
            color: AppTheme.errorColor,
            defaultDuration: 0,
            category: "Finance"
        ),
        EventTemplate(
            title: "House Meeting",
            icon: "person.3.fill",
            color: AppTheme.infoColor,
            defaultDuration: 1,
            category: "Household"
        )
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: AppTheme.spacing) {
                Text("Quick Event Templates")
                    .font(AppTheme.headlineFont)
                    .foregroundColor(AppTheme.textPrimary)
                    .padding(.top)
                
                Text("Choose from common household events")
                    .font(AppTheme.captionFont)
                    .foregroundColor(AppTheme.textSecondary)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(templates) { template in
                        templateCard(template)
                    }
                }
                .padding()
                
                Spacer()
            }
            .background(AppTheme.backgroundLight.ignoresSafeArea())
            .navigationTitle("Templates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func templateCard(_ template: EventTemplate) -> some View {
        Button(action: {
            createEvent(from: template)
        }) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(template.color.opacity(0.15))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: template.icon)
                        .font(.system(size: 24))
                        .foregroundColor(template.color)
                }
                
                Text(template.title)
                    .font(AppTheme.subheadlineFont)
                    .foregroundColor(AppTheme.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text(template.category)
                    .font(AppTheme.captionFont)
                    .foregroundColor(AppTheme.textSecondary)
            }
            .frame(height: 120)
            .frame(maxWidth: .infinity)
            .background(Color.white)
            .cornerRadius(AppTheme.cornerRadius)
            .shadow(color: AppTheme.cardShadow, radius: 3, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func createEvent(from template: EventTemplate) {
        let calendar = Calendar.current
        var startComponents = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        
        // Set appropriate time based on template
        if template.defaultDuration == 0 { // All day events
            startComponents.hour = 0
            startComponents.minute = 0
        } else {
            startComponents.hour = 19 // Default to 7 PM
            startComponents.minute = 0
        }
        
        guard let startDate = calendar.date(from: startComponents) else { return }
        let endDate = calendar.date(byAdding: .hour, value: max(1, template.defaultDuration), to: startDate) ?? startDate
        
        let event = Event(
            id: nil,
            title: template.title,
            description: nil,
            startDate: startDate,
            endDate: endDate,
            location: nil,
            isAllDay: template.defaultDuration == 0,
            reminder: .thirtyMinutes,
            attendees: ["You"], // In real app, get household members
            createdBy: "You",
            color: .blue,
            recurrence: .none
        )
        
        viewModel.addEvent(householdId: householdId, event: event) { success, error in
            DispatchQueue.main.async {
                if success {
                    self.dismiss()
                }
            }
        }
    }
}

struct EventTemplate: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let color: Color
    let defaultDuration: Int // hours, 0 for all-day
    let category: String
}
