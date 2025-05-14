import SwiftUI

struct EnhancedMainTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var firestoreViewModel = FirestoreViewModel()
    let householdId: String
    
    var body: some View {
        TabView {
            NavigationView {
                DashboardView(viewModel: firestoreViewModel, householdId: householdId)
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            
            NavigationView {
                ChoresView(viewModel: firestoreViewModel, householdId: householdId)
            }
            .tabItem {
                Label("Chores", systemImage: "checklist")
            }
            
            NavigationView {
                EnhancedGroceryView(viewModel: firestoreViewModel, householdId: householdId)
            }
            .tabItem {
                Label("Grocery", systemImage: "cart.fill")
            }
            
            NavigationView {
                CalendarView(viewModel: firestoreViewModel, householdId: householdId)
            }
            .tabItem {
                Label("Calendar", systemImage: "calendar")
            }
            
            NavigationView {
                ExpensesView(viewModel: firestoreViewModel, householdId: householdId)
            }
            .tabItem {
                Label("Expenses", systemImage: "dollarsign.circle.fill")
            }
        }
        .accentColor(AppTheme.primaryColor)
        .onAppear {
            // Load initial data
            firestoreViewModel.fetchChores(householdId: householdId)
            firestoreViewModel.fetchGroceryItems(householdId: householdId)
            firestoreViewModel.fetchHousehold(householdId: householdId)
            firestoreViewModel.fetchEvents(householdId: householdId)
            firestoreViewModel.fetchExpenses(householdId: householdId)
            SmartNotificationManager.shared.scheduleSmartNotifications(for: householdId)
        }
    }
}
