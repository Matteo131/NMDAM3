import SwiftUI
import Firebase

struct EnhancedGroceryView: View {
    @ObservedObject var viewModel: FirestoreViewModel
    let householdId: String
    @State private var showingAddItem = false
    @State private var showingCategoryView = false
    @State private var selectedCategory = ""
    @State private var searchText = ""
    @State private var showCompletedItems = false
    
    // Grocery categories with colors and icons
    let categories = [
        GroceryCategory(name: "Fruits & Vegetables", color: Color(hex: "4CD964"), icon: "leaf.fill"),
        GroceryCategory(name: "Dairy & Eggs", color: Color(hex: "54C7FC"), icon: "cup.and.saucer.fill"),
        GroceryCategory(name: "Meat & Seafood", color: Color(hex: "FF2D55"), icon: "fish.fill"),
        GroceryCategory(name: "Bakery", color: Color(hex: "FF9500"), icon: "birthday.cake.fill"),
        GroceryCategory(name: "Pantry", color: Color(hex: "FFCC00"), icon: "shippingbox.fill"),
        GroceryCategory(name: "Frozen", color: Color(hex: "5856D6"), icon: "snow"),
        GroceryCategory(name: "Snacks", color: Color(hex: "FF3B30"), icon: "popcorn.fill"),
        GroceryCategory(name: "Beverages", color: Color(hex: "007AFF"), icon: "drop.fill"),
        GroceryCategory(name: "Household", color: Color(hex: "8E8E93"), icon: "house.fill")
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.spacing) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(AppTheme.textTertiary)
                    
                    TextField("Search grocery items", text: $searchText)
                        .font(AppTheme.bodyFont)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(AppTheme.cornerRadius)
                .shadow(color: AppTheme.cardShadow, radius: 3, x: 0, y: 1)
                .padding(.horizontal)
                
                // Main grocery list
                VStack(alignment: .leading, spacing: AppTheme.spacing) {
                    HStack {
                        Text("Current List")
                            .font(AppTheme.headlineFont)
                            .foregroundColor(AppTheme.textPrimary)
                        
                        Spacer()
                        
                        Button(action: {
                            showingAddItem = true
                        }) {
                            Text("Add Item")
                                .font(AppTheme.captionFont)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(AppTheme.primaryColor)
                                .foregroundColor(.white)
                                .cornerRadius(AppTheme.cornerRadius)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Grocery items
                    if viewModel.groceryItems.isEmpty {
                        emptyStateView
                    } else {
                        groceryItemsList
                    }
                }
                
                // Category tiles (Spotify-style)
                VStack(alignment: .leading, spacing: AppTheme.spacing) {
                    Text("Quick Add by Category")
                        .font(AppTheme.headlineFont)
                        .foregroundColor(AppTheme.textPrimary)
                        .padding(.horizontal)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(categories) { category in
                            categoryTile(category)
                                .onTapGesture {
                                    selectedCategory = category.name
                                    showingCategoryView = true
                                }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .background(AppTheme.backgroundLight.ignoresSafeArea())
        .navigationTitle("Grocery")
        .navigationBarItems(trailing:
            Toggle(isOn: $showCompletedItems) {
                Text("Show Completed")
                    .font(AppTheme.captionFont)
            }
            .toggleStyle(SwitchToggleStyle(tint: AppTheme.primaryColor))
            .labelsHidden()
        )
        .onAppear {
            viewModel.fetchGroceryItems(householdId: householdId)
        }
        .sheet(isPresented: $showingAddItem) {
            AddGroceryItemView(viewModel: viewModel, householdId: householdId)
        }
        .sheet(isPresented: $showingCategoryView) {
            CategoryGroceryView(
                viewModel: viewModel,
                householdId: householdId,
                category: selectedCategory
            )
        }
    }
    
    // MARK: - Subviews
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "cart")
                .font(.system(size: 50))
                .foregroundColor(AppTheme.textTertiary)
            
            Text("Your grocery list is empty")
                .font(AppTheme.subheadlineFont)
                .foregroundColor(AppTheme.textSecondary)
            
            Text("Tap 'Add Item' or browse the categories below")
                .font(AppTheme.captionFont)
                .foregroundColor(AppTheme.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    private var groceryItemsList: some View {
        VStack(spacing: 8) {
            ForEach(filteredGroceryItems) { item in
                HStack(spacing: 16) {
                    Button(action: {
                        if let id = item.id {
                            viewModel.toggleGroceryItemCompletion(
                                householdId: householdId,
                                itemId: id,
                                isCompleted: !item.isCompleted
                            )
                        }
                    }) {
                        Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 24))
                            .foregroundColor(item.isCompleted ? AppTheme.successColor : AppTheme.textTertiary)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.name)
                            .font(AppTheme.bodyFont)
                            .strikethrough(item.isCompleted)
                            .foregroundColor(item.isCompleted ? AppTheme.textTertiary : AppTheme.textPrimary)
                        
                        Text(item.category)
                            .font(AppTheme.captionFont)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    
                    Spacer()
                    
                    Text(formatDate(item.addedAt))
                        .font(AppTheme.captionFont)
                        .foregroundColor(AppTheme.textTertiary)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(AppTheme.cornerRadius)
                .shadow(color: AppTheme.cardShadow, radius: 3, x: 0, y: 1)
            }
            .padding(.horizontal)
        }
    }
    
    private func categoryTile(_ category: GroceryCategory) -> some View {
        ZStack(alignment: .bottomLeading) {
            // Background with rounded corners
            Rectangle()
                .fill(category.color)
                .cornerRadius(AppTheme.cornerRadius)
                .frame(height: 120)
            
            // Category icon
            Image(systemName: category.icon)
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.3))
                .offset(x: 100, y: -15)  // Position in corner
            
            // Category name
            Text(category.name)
                .font(AppTheme.subheadlineFont.bold())
                .foregroundColor(.white)
                .padding()
        }
        .shadow(color: category.color.opacity(0.3), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Helper methods
    
    private var filteredGroceryItems: [GroceryItem] {
        var items = viewModel.groceryItems
        
        // Apply search filter
        if !searchText.isEmpty {
            items = items.filter { $0.name.lowercased().contains(searchText.lowercased()) ||
                $0.category.lowercased().contains(searchText.lowercased()) }
        }
        
        // Apply completed filter
        if !showCompletedItems {
            items = items.filter { !$0.isCompleted }
        }
        
        return items
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Supporting Types

struct GroceryCategory: Identifiable {
    let id = UUID()
    let name: String
    let color: Color
    let icon: String
}

struct CategoryGroceryView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: FirestoreViewModel
    let householdId: String
    let category: String
    
    @State private var newItemName = ""
    @State private var addedItems: [String: Bool] = [:]
    @State private var showingConfirmation = false
    @State private var lastAddedItem = ""
    
    // Common items by category
    let commonItems: [String: [String]] = [
        "Fruits & Vegetables": ["Apples", "Bananas", "Carrots", "Onions", "Potatoes", "Lettuce", "Tomatoes", "Broccoli"],
        "Dairy & Eggs": ["Milk", "Eggs", "Cheese", "Yogurt", "Butter", "Cream", "Sour Cream"],
        "Meat & Seafood": ["Chicken", "Ground Beef", "Steak", "Pork Chops", "Salmon", "Shrimp", "Tuna"],
        "Bakery": ["Bread", "Bagels", "Buns", "Cookies", "Cake", "Muffins", "Tortillas"],
        "Pantry": ["Rice", "Pasta", "Flour", "Sugar", "Oil", "Vinegar", "Canned Beans", "Canned Soup"],
        "Frozen": ["Ice Cream", "Frozen Pizza", "Frozen Vegetables", "Frozen Meals", "Frozen Fruit"],
        "Snacks": ["Chips", "Crackers", "Nuts", "Popcorn", "Granola Bars", "Cookies", "Candy"],
        "Beverages": ["Coffee", "Tea", "Juice", "Soda", "Water", "Wine", "Beer"],
        "Household": ["Paper Towels", "Toilet Paper", "Dish Soap", "Laundry Detergent", "Trash Bags"]
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: AppTheme.spacing) {
                // Quick add bar
                HStack {
                    TextField("Add custom item", text: $newItemName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button(action: {
                        addItem(newItemName)
                        newItemName = ""
                    }) {
                        Text("Add")
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(AppTheme.primaryColor)
                            .foregroundColor(.white)
                            .cornerRadius(AppTheme.cornerRadius)
                    }
                    .disabled(newItemName.isEmpty)
                }
                .padding(.horizontal)
                
                // Confirmation popup
                if showingConfirmation {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(AppTheme.successColor)
                        
                        Text("\(lastAddedItem) added to your list")
                            .font(AppTheme.bodyFont)
                            .foregroundColor(AppTheme.textPrimary)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(AppTheme.cornerRadius)
                    .shadow(color: AppTheme.cardShadow, radius: 3, x: 0, y: 1)
                    .padding(.horizontal)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .onAppear {
                        // Automatically dismiss the confirmation after 2 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation {
                                showingConfirmation = false
                            }
                        }
                    }
                }
                
                // Common items grid
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(itemsForCategory, id: \.self) { item in
                            Button(action: {
                                addItem(item)
                            }) {
                                ZStack(alignment: .topTrailing) {
                                    Text(item)
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(addedItems[item] == true ?
                                                    Color(hex: "F2FFF2") :
                                                    Color.white)
                                        .foregroundColor(AppTheme.textPrimary)
                                        .cornerRadius(AppTheme.cornerRadius)
                                        .shadow(color: AppTheme.cardShadow, radius: 3, x: 0, y: 1)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                                                .stroke(addedItems[item] == true ?
                                                        AppTheme.successColor.opacity(0.5) :
                                                        Color.clear,
                                                        lineWidth: 2)
                                        )
                                    
                                    // Show checkmark when item is added
                                    if addedItems[item] == true {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(AppTheme.successColor)
                                            .background(Color.white)
                                            .clipShape(Circle())
                                            .padding(8)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .animation(.easeInOut, value: addedItems)
                }
            }
            .padding(.top)
            .background(AppTheme.backgroundLight.ignoresSafeArea())
            .navigationTitle(category)
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
    }
    
    private var itemsForCategory: [String] {
        return commonItems[category] ?? []
    }
    
    private func addItem(_ name: String) {
        guard !name.isEmpty else { return }
        
        viewModel.addGroceryItem(
            householdId: householdId,
            name: name,
            category: category
        ) { success, _ in
            if success {
                // Mark item as added
                addedItems[name] = true
                lastAddedItem = name
                
                // Show confirmation
                withAnimation {
                    showingConfirmation = true
                }
                
                // Reset checkmark after 5 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    withAnimation {
                        addedItems[name] = nil
                    }
                }
            }
        }
    }
}
