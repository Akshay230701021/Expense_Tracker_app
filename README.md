# Expense Tracker Flutter App

A comprehensive personal finance management app built with Flutter that helps you track expenses, set budgets, and analyze spending patterns with beautiful visualizations.

## Features

### 📊 Expense Management
- Add, view, and delete expenses with ease
- Categorize expenses into 8 predefined categories
- Search and filter expenses by category and date range
- Persistent data storage using SharedPreferences

### 💰 Budget Tracking
- Set monthly budgets for each expense category
- Real-time budget usage tracking with progress indicators
- Visual alerts when budget limits are exceeded
- Budget vs actual spending comparison

### 📈 Analytics & Insights
- Interactive pie chart showing expense breakdown by category
- Top spending categories with percentage breakdown
- Monthly and daily spending averages
- Total transaction count tracking

### 🎨 Modern UI/UX
- Clean, intuitive Material Design interface
- Gradient backgrounds and smooth animations
- Tab-based navigation (Home, Analytics, Budget)
- Responsive design for different screen sizes
- Color-coded categories with custom icons

## Screenshots

*Add screenshots of your app here*

## Categories

The app supports the following expense categories:
- 🍽️ **Food** - Restaurants, groceries, dining
- 🚗 **Transportation** - Gas, public transport, ride-sharing
- 🛍️ **Shopping** - Clothes, electronics, general purchases
- 🎬 **Entertainment** - Movies, games, subscriptions
- 📄 **Bills** - Utilities, rent, insurance
- 🏥 **Healthcare** - Medical expenses, pharmacy
- 🎓 **Education** - Books, courses, tuition
- 📂 **Other** - Miscellaneous expenses

## Getting Started

### Prerequisites
- Flutter SDK (3.0 or higher)
- Dart SDK (2.17 or higher)
- Android Studio / VS Code
- An Android/iOS device or emulator

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/Akshay230701021/expense-tracker-flutter.git
   cd expense-tracker-flutter
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

### Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  shared_preferences: ^2.2.2
  
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^2.0.0
```

## Project Structure

```
lib/
├── main.dart                 # App entry point and main widget
├── models/
│   ├── expense.dart         # Expense data model
│   └── budget.dart          # Budget data model
├── screens/
│   ├── home_screen.dart     # Home tab with expense list
│   ├── analytics_screen.dart # Analytics and charts
│   └── budget_screen.dart   # Budget management
├── widgets/
│   ├── add_expense_modal.dart
│   ├── budget_modal.dart
│   └── pie_chart_painter.dart
└── utils/
    └── storage_helper.dart   # Data persistence utilities
```

## Key Components

### Expense Model
- Unique ID generation
- JSON serialization/deserialization
- Date and category tracking

### Budget System
- Monthly budget allocation
- Real-time usage calculation
- Over-budget alerts

### Custom Pie Chart
- Custom painter implementation
- Dynamic color assignment
- Responsive sizing

### Data Persistence
- SharedPreferences for local storage
- Automatic save/load functionality
- JSON-based data serialization

## Usage

### Adding an Expense
1. Tap the floating action button (+)
2. Enter expense title and amount
3. Select a category from the dropdown
4. Tap "Add Expense"

### Setting a Budget
1. Navigate to the Budget tab
2. Tap "Set Budget"
3. Choose a category and enter budget amount
4. Tap "Set Budget"

### Viewing Analytics
1. Navigate to the Analytics tab
2. View pie chart breakdown
3. Check top spending categories
4. Monitor daily averages

### Filtering Expenses
1. Use the search bar to find specific expenses
2. Filter by category using the dropdown
3. View results in real-time

## Customization

### Adding New Categories
1. Add the new category to the `_categories` list
2. Update `_getCategoryColor()` method
3. Update `_getCategoryIcon()` method

### Modifying Colors
Update the color scheme in the `_getCategoryColor()` method:
```dart
Color _getCategoryColor(String category) {
  switch (category) {
    case 'YourCategory':
      return Colors.yourColor;
    // ... other cases
  }
}
```

### Currency Support
The app currently uses Indian Rupees (₹). To change:
1. Replace '₹' symbols throughout the code
2. Update number formatting if needed

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Future Enhancements

- [ ] Export data to CSV/PDF
- [ ] Multiple currency support
- [ ] Cloud sync with Firebase
- [ ] Recurring expense tracking
- [ ] Income tracking
- [ ] Advanced chart types
- [ ] Dark mode support
- [ ] Expense categories customization
- [ ] Backup and restore functionality
- [ ] Weekly/yearly analytics

## Known Issues

- Data is stored locally only (no cloud sync)
- Limited to predefined categories
- No data export functionality

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Flutter team for the amazing framework
- Material Design for UI guidelines
- SharedPreferences package for local storage

## Support

If you encounter any issues or have questions:
1. Check the [Issues](https://github.com/yourusername/expense-tracker-flutter/issues) page
2. Create a new issue if your problem isn't already reported
3. Provide detailed information about your device and Flutter version

## Changelog

### Version 1.0.0
- Initial release
- Basic expense tracking
- Budget management
- Analytics dashboard
- Local data storage

---

**Made with ❤️ using Flutter**
