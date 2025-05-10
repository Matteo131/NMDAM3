//
//  FirestoreViewModel.swift
//  NMDA MARK 3
//
//  Created by Matteo Ricci on 14/04/2025.
//

import Foundation
import Firebase
import FirebaseFirestore
import FirebaseStorage
import UserNotifications
import FirebaseAuth

class FirestoreViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var chores: [Chore] = []
    @Published var groceryItems: [GroceryItem] = []
    @Published var household: Household?
    @Published var errorMessage: String?
    @Published var isLoading = false
    @Published var isProcessing = false
    @Published var events: [Event] = []
    @Published var notifications: [AppNotification] = []
    @Published var expenses: [Expense] = []
    @Published var pendingExpensesAmount: Double = 0
    @Published var upcomingEvents: Int = 0
    @Published var householdMembers: [HouseholdMember] = []
    @Published var recentActivity: [RoommateActivity] = []
    
    // MARK: - Private Properties
    
    private var db = Firestore.firestore()
    private var refreshTimer: Timer?
    private var activeListeners: [ListenerRegistration] = []
    
    // MARK: - Chore Methods
    
    
    func fetchChores(householdId: String) {
        isLoading = true
        print("Fetching chores for household: \(householdId)")
        
        db.collection("households").document(householdId).collection("chores")
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = "Error fetching chores: \(error.localizedDescription)"
                    print(self.errorMessage ?? "")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    self.errorMessage = "No chore documents found"
                    print("No chore documents found")
                    return
                }
                
                print("Found \(documents.count) chore documents")
                
                self.chores = documents.compactMap { document -> Chore? in
                    let data = document.data()
                    
                    guard let title = data["title"] as? String else {
                        print("Missing title for chore")
                        return nil
                    }
                    
                    let description = data["description"] as? String
                    
                    guard let assignedTo = data["assignedTo"] as? String else {
                        print("Missing assignedTo for chore")
                        return nil
                    }
                    
                    guard let dueDateTimestamp = data["dueDate"] as? Timestamp else {
                        print("Missing or invalid dueDate for chore")
                        return nil
                    }
                    
                    let dueDate = dueDateTimestamp.dateValue()
                    let isCompleted = data["isCompleted"] as? Bool ?? false
                    
                    return Chore(
                        id: document.documentID,
                        title: title,
                        description: description,
                        assignedTo: assignedTo,
                        dueDate: dueDate,
                        isCompleted: isCompleted
                    )
                }
                
                print("Successfully loaded \(self.chores.count) chores")
            }
    }
    
    func addChore(householdId: String, title: String, description: String?, assignedTo: String, dueDate: Date, completion: @escaping (Bool, String?) -> Void) {
        isProcessing = true
        
        let choreData: [String: Any] = [
            "title": title,
            "description": description ?? "",
            "assignedTo": assignedTo,
            "dueDate": Timestamp(date: dueDate),
            "isCompleted": false,
            "createdAt": Timestamp(date: Date())
        ]
        
        db.collection("households").document(householdId).collection("chores")
            .addDocument(data: choreData) { [weak self] error in
                guard let self = self else { return }
                
                if let error = error {
                    completion(false, error.localizedDescription)
                } else {
                    self.fetchChores(householdId: householdId)
                    
                    // Add notification scheduling
                    if let newChore = self.chores.last {
                        NotificationService.shared.scheduleChoreReminder(chore: newChore, householdId: householdId)
                    }
                    // Log activity
                    if let userName = Auth.auth().currentUser?.displayName {
                        self.logActivity(
                            householdId: householdId,
                            userName: userName,
                            actionVerb: "added",
                            itemName: title,
                            itemType: "chore"
                        )
                    }
                    
                    completion(true, nil)
                }
            }
    }
    
    func toggleChoreCompletion(householdId: String, choreId: String, isCompleted: Bool) {
        // Find the chore to get its title for activity logging
        db.collection("households").document(householdId)
            .collection("chores").document(choreId).getDocument { [weak self] snapshot, error in
                guard let self = self else { return }
                
                let data = snapshot?.data()
                let title = data?["title"] as? String ?? "a chore"
                
                // Update the chore completion status
                self.db.collection("households").document(householdId).collection("chores")
                    .document(choreId).updateData([
                        "isCompleted": isCompleted,
                        "completedAt": isCompleted ? Timestamp(date: Date()) : FieldValue.delete()
                    ]) { error in
                        if let error = error {
                            self.errorMessage = "Error updating chore: \(error.localizedDescription)"
                        } else {
                            self.fetchChores(householdId: householdId)
                            
                            // Log activity if completed
                            if isCompleted, let userName = Auth.auth().currentUser?.displayName {
                                self.logActivity(
                                    householdId: householdId,
                                    userName: userName,
                                    actionVerb: "completed",
                                    itemName: title,
                                    itemType: "chore"
                                )
                            }
                        }
                    }
            }
    }
    
    // MARK: - Grocery Methods
    
    func fetchGroceryItems(householdId: String) {
        isLoading = true
        print("Fetching grocery items for household: \(householdId)")
        
        db.collection("households").document(householdId).collection("groceryItems")
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = "Error fetching grocery items: \(error.localizedDescription)"
                    print(self.errorMessage ?? "")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    self.errorMessage = "No grocery documents found"
                    print("No grocery documents found")
                    return
                }
                
                print("Found \(documents.count) grocery documents")
                
                self.groceryItems = documents.compactMap { document -> GroceryItem? in
                    let data = document.data()
                    
                    guard let name = data["name"] as? String else {
                        print("Missing name for grocery item")
                        return nil
                    }
                    
                    guard let category = data["category"] as? String else {
                        print("Missing category for grocery item")
                        return nil
                    }
                    
                    guard let addedBy = data["addedBy"] as? String else {
                        print("Missing addedBy for grocery item")
                        return nil
                    }
                    
                    guard let addedAtTimestamp = data["addedAt"] as? Timestamp else {
                        print("Missing or invalid addedAt for grocery item")
                        return nil
                    }
                    
                    let addedAt = addedAtTimestamp.dateValue()
                    let isCompleted = data["isCompleted"] as? Bool ?? false
                    
                    return GroceryItem(
                        id: document.documentID,
                        name: name,
                        category: category,
                        addedBy: addedBy,
                        addedAt: addedAt,
                        isCompleted: isCompleted
                    )
                }
                
                print("Successfully loaded \(self.groceryItems.count) grocery items")
            }
    }
    
    func addGroceryItem(householdId: String, name: String, category: String, completion: @escaping (Bool, String?) -> Void) {
        isProcessing = true
        
        let currentUserName = Auth.auth().currentUser?.displayName ?? "You"
        
        let itemData: [String: Any] = [
            "name": name,
            "category": category,
            "addedBy": currentUserName,
            "addedAt": Timestamp(date: Date()),
            "isCompleted": false
        ]
        
        db.collection("households").document(householdId).collection("groceryItems")
            .addDocument(data: itemData) { [weak self] error in
                guard let self = self else { return }
                
                self.isProcessing = false
                
                if let error = error {
                    completion(false, error.localizedDescription)
                } else {
                    self.fetchGroceryItems(householdId: householdId)
                    
                    // Log activity
                    self.logActivity(
                        householdId: householdId,
                        userName: currentUserName,
                        actionVerb: "added",
                        itemName: name,
                        itemType: "grocery"
                    )
                    
                    completion(true, nil)
                }
            }
    }
    
    func toggleGroceryItemCompletion(householdId: String, itemId: String, isCompleted: Bool) {
        // Find the item to get its name for activity logging
        db.collection("households").document(householdId)
            .collection("groceryItems").document(itemId).getDocument { [weak self] snapshot, error in
                guard let self = self else { return }
                
                let data = snapshot?.data()
                let name = data?["name"] as? String ?? "a grocery item"
                
                // Update the item completion status
                self.db.collection("households").document(householdId).collection("groceryItems")
                    .document(itemId).updateData([
                        "isCompleted": isCompleted,
                        "completedAt": isCompleted ? Timestamp(date: Date()) : FieldValue.delete()
                    ]) { error in
                        if let error = error {
                            self.errorMessage = "Error updating grocery item: \(error.localizedDescription)"
                        } else {
                            self.fetchGroceryItems(householdId: householdId)
                            
                            // Log activity if purchased
                            if isCompleted, let userName = Auth.auth().currentUser?.displayName {
                                self.logActivity(
                                    householdId: householdId,
                                    userName: userName,
                                    actionVerb: "purchased",
                                    itemName: name,
                                    itemType: "grocery"
                                )
                            }
                        }
                    }
            }
    }
    
    // MARK: - Household Methods
    
    func fetchHousehold(householdId: String, completion: (() -> Void)? = nil) {
        isLoading = true
        print("Fetching household: \(householdId)")
        
        db.collection("households").document(householdId)
            .getDocument { [weak self] document, error in
                guard let self = self else { return }
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = "Error fetching household: \(error.localizedDescription)"
                    print(self.errorMessage ?? "")
                    completion?()
                    return
                }
                
                guard let document = document, document.exists else {
                    self.errorMessage = "Household not found"
                    print("Household document not found")
                    completion?()
                    return
                }
                
                let data = document.data() ?? [:]
                print("Household data: \(data)")
                
                guard let name = data["name"] as? String else {
                    self.errorMessage = "Missing name for household"
                    print("Missing name for household")
                    completion?()
                    return
                }
                
                guard let createdAtTimestamp = data["createdAt"] as? Timestamp else {
                    self.errorMessage = "Missing or invalid createdAt for household"
                    print("Missing or invalid createdAt for household")
                    completion?()
                    return
                }
                
                let createdAt = createdAtTimestamp.dateValue()
                
                self.household = Household(
                    id: document.documentID,
                    name: name,
                    createdAt: createdAt
                )
                
                print("Successfully loaded household: \(name)")
                completion?()
            }
    }
    
    // MARK: - Expense Methods
    
    func fetchExpenses(householdId: String) {
        isLoading = true
        print("Fetching expenses for household: \(householdId)")
        
        db.collection("households").document(householdId).collection("expenses")
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = "Error fetching expenses: \(error.localizedDescription)"
                    print(self.errorMessage ?? "")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    self.errorMessage = "No expense documents found"
                    print("No expense documents found")
                    return
                }
                
                print("Found \(documents.count) expense documents")
                
                self.expenses = documents.compactMap { document -> Expense? in
                    let data = document.data()
                    
                    guard let title = data["title"] as? String else {
                        print("Missing title for expense")
                        return nil
                    }
                    
                    guard let amount = data["amount"] as? Double else {
                        print("Missing amount for expense")
                        return nil
                    }
                    
                    guard let paidBy = data["paidBy"] as? String else {
                        print("Missing paidBy for expense")
                        return nil
                    }
                    
                    guard let paidAtTimestamp = data["paidAt"] as? Timestamp else {
                        print("Missing or invalid paidAt for expense")
                        return nil
                    }
                    
                    guard let categoryString = data["category"] as? String,
                          let category = ExpenseCategory(rawValue: categoryString) else {
                        print("Missing or invalid category for expense")
                        return nil
                    }
                    
                    guard let splitTypeString = data["splitType"] as? String,
                          let splitType = SplitType(rawValue: splitTypeString) else {
                        print("Missing or invalid splitType for expense")
                        return nil
                    }
                    
                    guard let splitAmong = data["splitAmong"] as? [String] else {
                        print("Missing splitAmong for expense")
                        return nil
                    }
                    
                    guard let settled = data["settled"] as? [String: Bool] else {
                        print("Missing settled status for expense")
                        return nil
                    }
                    
                    let paidAt = paidAtTimestamp.dateValue()
                    let notes = data["notes"] as? String
                    let receiptPath = data["receiptPath"] as? String
                    
                    return Expense(
                        id: document.documentID,
                        title: title,
                        amount: amount,
                        paidBy: paidBy,
                        paidAt: paidAt,
                        category: category,
                        splitType: splitType,
                        splitAmong: splitAmong,
                        settled: settled,
                        notes: notes,
                        receiptPath: receiptPath
                    )
                }
                
                print("Successfully loaded \(self.expenses.count) expenses")
            }
    }
    
    func addExpense(householdId: String, expense: Expense, completion: @escaping (Bool, String?) -> Void) {
        isProcessing = true
        
        // Convert expense to dictionary
        var expenseData: [String: Any] = [
            "title": expense.title,
            "amount": expense.amount,
            "paidBy": expense.paidBy,
            "paidAt": Timestamp(date: expense.paidAt),
            "category": expense.category.rawValue,
            "splitType": expense.splitType.rawValue,
            "splitAmong": expense.splitAmong,
            "settled": expense.settled,
            "createdAt": Timestamp(date: Date())
        ]
        
        if let notes = expense.notes {
            expenseData["notes"] = notes
        }
        
        if let receiptPath = expense.receiptPath {
            expenseData["receiptPath"] = receiptPath
        }
        
        db.collection("households").document(householdId).collection("expenses")
            .addDocument(data: expenseData) { [weak self] error in
                guard let self = self else { return }
                
                self.isProcessing = false
                
                if let error = error {
                    completion(false, error.localizedDescription)
                } else {
                    self.fetchExpenses(householdId: householdId)
                    
                    // Log activity
                    if let userName = Auth.auth().currentUser?.displayName {
                        self.logActivity(
                            householdId: householdId,
                            userName: userName,
                            actionVerb: "added",
                            itemName: expense.title,
                            itemType: "expense"
                        )
                    }
                    
                    completion(true, nil)
                }
            }
    }
    
    // MARK: - Event Methods
    
    func fetchEvents(householdId: String, completion: (() -> Void)? = nil) {
        isLoading = true
        print("Fetching events for household: \(householdId)")
        
        db.collection("households").document(householdId).collection("events")
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = "Error fetching events: \(error.localizedDescription)"
                    print(self.errorMessage ?? "")
                    completion?()
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    self.events = []
                    print("No event documents found")
                    completion?()
                    return
                }
                
                self.events = documents.compactMap { document -> Event? in
                    let data = document.data()
                    
                    guard let title = data["title"] as? String,
                          let startDateTimestamp = data["startDate"] as? Timestamp,
                          let endDateTimestamp = data["endDate"] as? Timestamp,
                          let isAllDay = data["isAllDay"] as? Bool,
                          let attendees = data["attendees"] as? [String],
                          let createdBy = data["createdBy"] as? String,
                          let colorString = data["color"] as? String,
                          let color = EventColor(rawValue: colorString) else {
                        return nil
                    }
                    
                    let description = data["description"] as? String
                    let location = data["location"] as? String
                    
                    var reminder: EventReminder? = nil
                    if let reminderString = data["reminder"] as? String {
                        reminder = EventReminder(rawValue: reminderString)
                    }
                    
                    var recurrence: EventRecurrence? = nil
                    if let recurrenceString = data["recurrence"] as? String {
                        recurrence = EventRecurrence(rawValue: recurrenceString)
                    }
                    
                    return Event(
                        id: document.documentID,
                        title: title,
                        description: description,
                        startDate: startDateTimestamp.dateValue(),
                        endDate: endDateTimestamp.dateValue(),
                        location: location,
                        isAllDay: isAllDay,
                        reminder: reminder,
                        attendees: attendees,
                        createdBy: createdBy,
                        color: color,
                        recurrence: recurrence
                    )
                }
                
                print("Successfully loaded \(self.events.count) events")
                completion?()
            }
    }
    
    func addEvent(householdId: String, event: Event, completion: @escaping (Bool, String?) -> Void) {
        isProcessing = true
        
        var eventData: [String: Any] = [
            "title": event.title,
            "startDate": Timestamp(date: event.startDate),
            "endDate": Timestamp(date: event.endDate),
            "isAllDay": event.isAllDay,
            "attendees": event.attendees,
            "createdBy": event.createdBy,
            "color": event.color.rawValue,
            "createdAt": Timestamp(date: Date())
        ]
        
        if let description = event.description {
            eventData["description"] = description
        }
        
        if let location = event.location {
            eventData["location"] = location
        }
        
        if let reminder = event.reminder {
            eventData["reminder"] = reminder.rawValue
        }
        
        if let recurrence = event.recurrence {
            eventData["recurrence"] = recurrence.rawValue
        }
        
        db.collection("households").document(householdId).collection("events")
            .addDocument(data: eventData) { [weak self] error in
                guard let self = self else { return }
                
                self.isProcessing = false
                
                if let error = error {
                    completion(false, error.localizedDescription)
                } else {
                    self.fetchEvents(householdId: householdId)
                    
                    // Log activity
                    if let userName = Auth.auth().currentUser?.displayName {
                        self.logActivity(
                            householdId: householdId,
                            userName: userName,
                            actionVerb: "scheduled",
                            itemName: event.title,
                            itemType: "event"
                        )
                    }
                    
                    completion(true, nil)
                }
            }
    }
    
    func updateEvent(householdId: String, event: Event, completion: @escaping (Bool, String?) -> Void) {
        guard let eventId = event.id else {
            completion(false, "Event ID is missing")
            return
        }
        
        isProcessing = true
        
        var eventData: [String: Any] = [
            "title": event.title,
            "startDate": Timestamp(date: event.startDate),
            "endDate": Timestamp(date: event.endDate),
            "isAllDay": event.isAllDay,
            "attendees": event.attendees,
            "createdBy": event.createdBy,
            "color": event.color.rawValue,
            "updatedAt": Timestamp(date: Date())
        ]
        
        if let description = event.description {
            eventData["description"] = description
        } else {
            eventData["description"] = FieldValue.delete()
        }
        
        if let location = event.location {
            eventData["location"] = location
        } else {
            eventData["location"] = FieldValue.delete()
        }
        
        if let reminder = event.reminder {
            eventData["reminder"] = reminder.rawValue
        } else {
            eventData["reminder"] = FieldValue.delete()
        }
        
        if let recurrence = event.recurrence {
            eventData["recurrence"] = recurrence.rawValue
        } else {
            eventData["recurrence"] = FieldValue.delete()
        }
        
        db.collection("households").document(householdId).collection("events")
            .document(eventId).updateData(eventData) { [weak self] error in
                guard let self = self else { return }
                
                self.isProcessing = false
                
                if let error = error {
                    completion(false, error.localizedDescription)
                } else {
                    self.fetchEvents(householdId: householdId)
                    
                    // Log activity
                    if let userName = Auth.auth().currentUser?.displayName {
                        self.logActivity(
                            householdId: householdId,
                            userName: userName,
                            actionVerb: "updated",
                            itemName: event.title,
                            itemType: "event"
                        )
                    }
                    
                    completion(true, nil)
                }
            }
    }
    
    func deleteEvent(householdId: String, eventId: String, completion: @escaping (Bool, String?) -> Void) {
        // First get the event name for activity logging
        db.collection("households").document(householdId).collection("events")
            .document(eventId).getDocument { [weak self] snapshot, error in
                guard let self = self else { return }
                
                let title = snapshot?.data()?["title"] as? String ?? "an event"
                
                // Now delete the event
                self.db.collection("households").document(householdId).collection("events")
                    .document(eventId).delete { error in
                        if let error = error {
                            completion(false, error.localizedDescription)
                        } else {
                            // Refresh events list
                            self.fetchEvents(householdId: householdId)
                            
                            // Log activity
                            if let userName = Auth.auth().currentUser?.displayName {
                                self.logActivity(
                                    householdId: householdId,
                                    userName: userName,
                                    actionVerb: "deleted",
                                    itemName: title,
                                    itemType: "event"
                                )
                            }
                            
                            completion(true, nil)
                        }
                    }
            }
    }
    
    // MARK: - Activity Methods
    
    func fetchRecentActivity(householdId: String) {
        isLoading = true
        
        db.collection("households").document(householdId)
            .collection("activity")
            .order(by: "timestamp", descending: true)
            .limit(to: 10)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = "Error fetching activity: \(error.localizedDescription)"
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    self.recentActivity = []
                    return
                }
                
                self.recentActivity = documents.compactMap { document -> RoommateActivity? in
                    let data = document.data()
                    
                    guard let userName = data["userName"] as? String,
                          let actionVerb = data["actionVerb"] as? String,
                          let itemName = data["itemName"] as? String,
                          let itemType = data["itemType"] as? String,
                          let timestampValue = data["timestamp"] as? Timestamp else {
                        return nil
                    }
                    
                    return RoommateActivity(
                        id: document.documentID,
                        userName: userName,
                        actionVerb: actionVerb,
                        itemName: itemName,
                        itemType: itemType,
                        timestamp: timestampValue.dateValue()
                    )
                }
            }
    }
    
    func logActivity(householdId: String, userName: String, actionVerb: String, itemName: String, itemType: String) {
        guard let currentUser = Auth.auth().currentUser else { return }
        
        let activityData: [String: Any] = [
            "userName": userName,
            "userId": currentUser.uid,
            "actionVerb": actionVerb,
            "itemName": itemName,
            "itemType": itemType,
            "timestamp": Timestamp(date: Date())
        ]
        
        db.collection("households").document(householdId)
            .collection("activity").addDocument(data: activityData) { error in
                if let error = error {
                    print("Error logging activity: \(error.localizedDescription)")
                }
            }
    }
    
    // MARK: - Notification Methods
    
    func fetchNotifications() {
        // Placeholder implementation
        self.notifications = []
    }
    
    func markNotificationAsRead(notificationId: String) {
        // Placeholder implementation
    }
    
    func markAllNotificationsAsRead() {
        // Placeholder implementation
    }
    
    // MARK: - Household Members Methods
    
    func fetchHouseholdMembers(householdId: String) {
        isLoading = true
        
        db.collection("households").document(householdId).collection("members")
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                self.isLoading = false
                
                if let error = error {
                    print("Error fetching household members: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    self.householdMembers = []
                    return
                }
                
                self.householdMembers = documents.compactMap { document -> HouseholdMember? in
                    let data = document.data()
                    
                    guard let displayName = data["displayName"] as? String,
                          let email = data["email"] as? String,
                          let roleString = data["role"] as? String,
                          let role = HouseholdRole(rawValue: roleString),
                          let joinedAtTimestamp = data["joinedAt"] as? Timestamp else {
                        return nil
                    }
                    
                    let joinedAt = joinedAtTimestamp.dateValue()
                    let profileImageURL = data["profileImageURL"] as? String
                    
                    return HouseholdMember(
                        id: document.documentID,
                        displayName: displayName,
                        email: email,
                        role: role,
                        joinedAt: joinedAt,
                        profileImageURL: profileImageURL
                    )
                }
            }
    }
    
    func fetchMemberNames(householdId: String, completion: @escaping ([String]) -> Void) {
        db.collection("households").document(householdId).collection("members")
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching members: \(error.localizedDescription)")
                    completion([])
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion([])
                    return
                }
                
                // Extract just the names
                let names = documents.compactMap { document -> String? in
                    return document.data()["displayName"] as? String
                }
                
                completion(names.isEmpty ? ["You"] : names)
            }
    }
    
    // MARK: - Listener Methods
    
    func setupHouseholdListeners(householdId: String) {
        // Remove any existing listeners first
        removeListeners()
        
        // Listen for chores
        let choresListener = db.collection("households").document(householdId).collection("chores")
            .addSnapshotListener { [weak self] (snapshot: QuerySnapshot?, error: Error?) in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error listening for chores: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                DispatchQueue.main.async {
                    self.chores = documents.compactMap { document -> Chore? in
                        let data = document.data()
                        
                        guard let title = data["title"] as? String else { return nil }
                        
                        let description = data["description"] as? String
                        
                        guard let assignedTo = data["assignedTo"] as? String else { return nil }
                        
                        guard let dueDateTimestamp = data["dueDate"] as? Timestamp else { return nil }
                        
                        let dueDate = dueDateTimestamp.dateValue()
                        let isCompleted = data["isCompleted"] as? Bool ?? false
                        
                        return Chore(
                            id: document.documentID,
                            title: title,
                            description: description,
                            assignedTo: assignedTo,
                            dueDate: dueDate,
                            isCompleted: isCompleted
                        )
                    }
                    
                    // Check for newly completed chores to send notifications
                    if let changes = snapshot?.documentChanges {
                        for change in changes where change.type == .modified {
                            let data = change.document.data()
                            if let isCompleted = data["isCompleted"] as? Bool,
                               let title = data["title"] as? String,
                               isCompleted,
                               let completedAt = data["completedAt"] as? Timestamp,
                               // Only notify about recently completed items (within last minute)
                               completedAt.dateValue() > Date().addingTimeInterval(-60) {
                                
                                self.sendNotification(
                                    title: "Chore Completed",
                                    body: "\(title) has been marked as complete"
                                )
                            }
                        }
                    }
                }
            }
        activeListeners.append(choresListener)
        
        // Listen for grocery items
        let groceryListener = db.collection("households").document(householdId).collection("groceryItems")
            .addSnapshotListener { [weak self] (snapshot: QuerySnapshot?, error: Error?) in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error listening for grocery items: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                DispatchQueue.main.async {
                    self.groceryItems = documents.compactMap { document -> GroceryItem? in
                        let data = document.data()
                        
                        guard let name = data["name"] as? String else { return nil }
                        guard let category = data["category"] as? String else { return nil }
                        guard let addedBy = data["addedBy"] as? String else { return nil }
                        guard let addedAtTimestamp = data["addedAt"] as? Timestamp else { return nil }
                        
                        let addedAt = addedAtTimestamp.dateValue()
                        let isCompleted = data["isCompleted"] as? Bool ?? false
                        
                        return GroceryItem(
                            id: document.documentID,
                            name: name,
                            category: category,
                            addedBy: addedBy,
                            addedAt: addedAt,
                            isCompleted: isCompleted
                        )
                    }
                    
                    // Check for newly added grocery items to send notifications
                    if let changes = snapshot?.documentChanges {
                        for change in changes where change.type == .added {
                            let data = change.document.data()
                            if let name = data["name"] as? String,
                               let addedBy = data["addedBy"] as? String,
                               let addedAt = data["addedAt"] as? Timestamp,
                               // Only notify about recently added items (within last minute)
                               addedAt.dateValue() > Date().addingTimeInterval(-60) {
                                
                                self.sendNotification(
                                    title: "New Grocery Item",
                                    body: "\(addedBy) added \(name) to the grocery list"
                                )
                            }
                        }
                    }
                }
            }
        activeListeners.append(groceryListener)
        
        // Listen for household members
        let membersListener = db.collection("households").document(householdId).collection("members")
            .addSnapshotListener { [weak self] (snapshot: QuerySnapshot?, error: Error?) in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error listening for members: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                DispatchQueue.main.async {
                    self.householdMembers = documents.compactMap { document -> HouseholdMember? in
                        let data = document.data()
                        
                        guard let displayName = data["displayName"] as? String,
                              let email = data["email"] as? String,
                              let roleString = data["role"] as? String,
                              let role = HouseholdRole(rawValue: roleString),
                              let joinedAtTimestamp = data["joinedAt"] as? Timestamp else {
                            return nil
                        }
                        
                        let joinedAt = joinedAtTimestamp.dateValue()
                        let profileImageURL = data["profileImageURL"] as? String
                        
                        return HouseholdMember(
                            id: document.documentID,
                            displayName: displayName,
                            email: email,
                            role: role,
                            joinedAt: joinedAt,
                            profileImageURL: profileImageURL
                        )
                    }
                }
            }
        activeListeners.append(membersListener)
        
        // Listen for activity
        let activityListener = db.collection("households").document(householdId).collection("activity")
            .order(by: "timestamp", descending: true)
            .limit(to: 10)
            .addSnapshotListener { [weak self] (snapshot: QuerySnapshot?, error: Error?) in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error listening for activity: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                DispatchQueue.main.async {
                    self.recentActivity = documents.compactMap { document -> RoommateActivity? in
                        let data = document.data()
                        
                        guard let userName = data["userName"] as? String,
                              let actionVerb = data["actionVerb"] as? String,
                              let itemName = data["itemName"] as? String,
                              let itemType = data["itemType"] as? String,
                              let timestampValue = data["timestamp"] as? Timestamp else {
                            return nil
                        }
                        
                        return RoommateActivity(
                            id: document.documentID,
                            userName: userName,
                            actionVerb: actionVerb,
                            itemName: itemName,
                            itemType: itemType,
                            timestamp: timestampValue.dateValue()
                        )
                    }
                }
            }
        activeListeners.append(activityListener)
    }
    
    func removeListeners() {
        for listener in activeListeners {
            listener.remove()
        }
        activeListeners.removeAll()
    }
    
    // MARK: - Timer and Refresh Methods
    
    func setupEfficientRefresh(householdId: String) {
        // Cancel any existing timer
        refreshTimer?.invalidate()
        
        // Fetch data immediately using existing fetch methods
        fetchChores(householdId: householdId)
        fetchGroceryItems(householdId: householdId)
        fetchHousehold(householdId: householdId)
        fetchEvents(householdId: householdId)
        fetchRecentActivity(householdId: householdId)
        fetchHouseholdMembers(householdId: householdId)
        
        // Set up a timer that refreshes data every 30 seconds
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.fetchChores(householdId: householdId)
            self.fetchGroceryItems(householdId: householdId)
            self.fetchHousehold(householdId: householdId)
            self.fetchEvents(householdId: householdId)
            self.fetchRecentActivity(householdId: householdId)
        }
    }
    
    func cleanup() {
        refreshTimer?.invalidate()
        refreshTimer = nil
        removeListeners()
    }
    
    // MARK: - Helper Methods
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    func sendNotification(title: String, body: String) {
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        // Create trigger (immediate delivery)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        // Create request
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )
        
        // Add to notification center
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            }
        }
    }
    // Add to FirestoreViewModel.swift
    func deleteChore(householdId: String, choreId: String, completion: @escaping (Bool, String?) -> Void) {
        isProcessing = true
        
        db.collection("households").document(householdId).collection("chores")
            .document(choreId).delete { [weak self] error in
                guard let self = self else { return }
                
                self.isProcessing = false
                
                if let error = error {
                    completion(false, error.localizedDescription)
                } else {
                    self.fetchChores(householdId: householdId)
                    
                    // Log activity
                    if let userName = Auth.auth().currentUser?.displayName {
                        self.logActivity(
                            householdId: householdId,
                            userName: userName,
                            actionVerb: "deleted",
                            itemName: "a chore",
                            itemType: "chore"
                        )
                    }
                    
                    completion(true, nil)
                }
            }
        func resetCompletedChores(householdId: String) {
            // Check if chores need to be reset
            let defaults = UserDefaults.standard
            let lastResetDateKey = "lastChoreResetDate-\(householdId)"
            
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            
            if let lastResetDate = defaults.object(forKey: lastResetDateKey) as? Date {
                let lastResetDay = calendar.startOfDay(for: lastResetDate)
                
                // Only reset if it's a new day
                if lastResetDay < today {
                    // Reset all completed chores
                    db.collection("households").document(householdId).collection("chores")
                        .whereField("isCompleted", isEqualTo: true)
                        .getDocuments { [weak self] snapshot, error in
                            guard let self = self, let documents = snapshot?.documents else { return }
                            
                            let batch = self.db.batch()
                            
                            for document in documents {
                                let choreRef = self.db.collection("households").document(householdId)
                                    .collection("chores").document(document.documentID)
                                
                                // Reset isCompleted and remove completedAt
                                batch.updateData([
                                    "isCompleted": false,
                                    "completedAt": FieldValue.delete()
                                ], forDocument: choreRef)
                            }
                            
                            // Commit the batch
                            batch.commit { error in
                                if error == nil {
                                    // Update the reset date
                                    defaults.set(today, forKey: lastResetDateKey)
                                    
                                    // Refresh the chores list
                                    self.fetchChores(householdId: householdId)
                                    
                                    // Log activity
                                    if let userName = Auth.auth().currentUser?.displayName {
                                        self.logActivity(
                                            householdId: householdId,
                                            userName: "System",
                                            actionVerb: "reset",
                                            itemName: "all completed chores",
                                            itemType: "chore"
                                        )
                                    }
                                }
                            }
                        }
                }
            } else {
                // First time checking, just set the date
                defaults.set(today, forKey: lastResetDateKey)
            }
            func processRecurringChores(householdId: String) {
                db.collection("households").document(householdId).collection("chores")
                    .whereField("isRecurring", isEqualTo: true)
                    .whereField("isCompleted", isEqualTo: true)
                    .getDocuments { [weak self] snapshot, error in
                        guard let self = self, let documents = snapshot?.documents else { return }
                        
                        for document in documents {
                            let data = document.data()
                            
                            if let recurrenceData = data["recurrence"] as? [String: Any],
                               let frequency = recurrenceData["frequency"] as? String,
                               let freqEnum = RecurrenceFrequency(rawValue: frequency) {
                                
                                // Create new chore based on recurrence
                                var newChoreData = data
                                newChoreData["isCompleted"] = false
                                newChoreData["completedAt"] = FieldValue.delete()
                                
                                // Calculate new due date
                                if let currentDueDate = (data["dueDate"] as? Timestamp)?.dateValue() {
                                    let recurrence = ChoreRecurrence(
                                        frequency: freqEnum,
                                        daysOfWeek: recurrenceData["daysOfWeek"] as? [Int],
                                        dayOfMonth: recurrenceData["dayOfMonth"] as? Int,
                                        nextDueDate: currentDueDate
                                    )
                                    
                                    let newDueDate = recurrence.calculateNextDueDate(from: currentDueDate)
                                    newChoreData["dueDate"] = Timestamp(date: newDueDate)
                                    
                                    // Add the new chore
                                    self.db.collection("households").document(householdId)
                                        .collection("chores").addDocument(data: newChoreData)
                                }
                            }
                        }
                    }
            }
        }
    }
}
