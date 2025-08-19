import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;

void main() {
  runApp(const ExpenseTrackerApp());
}

class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Expense Tracker',
      debugShowCheckedModeBanner: false, // Remove debug banner
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const ExpenseHomePage(),
    );
  }
}

class Expense {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final String category;

  Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'date': date.millisecondsSinceEpoch,
      'category': category,
    };
  }

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'],
      title: json['title'],
      amount: json['amount'],
      date: DateTime.fromMillisecondsSinceEpoch(json['date']),
      category: json['category'],
    );
  }
}

class Budget {
  final String category;
  final double amount;
  final DateTime month;

  Budget({required this.category, required this.amount, required this.month});

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'amount': amount,
      'month': month.millisecondsSinceEpoch,
    };
  }

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      category: json['category'],
      amount: json['amount'],
      month: DateTime.fromMillisecondsSinceEpoch(json['month']),
    );
  }
}

class ExpenseHomePage extends StatefulWidget {
  const ExpenseHomePage({super.key});

  @override
  _ExpenseHomePageState createState() => _ExpenseHomePageState();
}

class _ExpenseHomePageState extends State<ExpenseHomePage>
    with TickerProviderStateMixin {
  final List<Expense> _expenses = [];
  final List<Budget> _budgets = [];
  final List<String> _categories = [
    'Food',
    'Transportation',
    'Shopping',
    'Entertainment',
    'Bills',
    'Healthcare',
    'Education', // Added Education category
    'Other',
  ];

  final int _selectedIndex = 0;
  late TabController _tabController;
  String _searchQuery = '';
  String _filterCategory = 'All';
  final DateTime _filterStartDate = DateTime.now().subtract(
    const Duration(days: 30),
  );
  final DateTime _filterEndDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Data persistence methods
  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();

    // Save expenses
    final expensesJson = _expenses.map((e) => e.toJson()).toList();
    await prefs.setString('expenses', jsonEncode(expensesJson));

    // Save budgets
    final budgetsJson = _budgets.map((b) => b.toJson()).toList();
    await prefs.setString('budgets', jsonEncode(budgetsJson));
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    // Load expenses
    final expensesString = prefs.getString('expenses');
    if (expensesString != null) {
      final expensesList = jsonDecode(expensesString) as List;
      setState(() {
        _expenses.clear();
        _expenses.addAll(expensesList.map((e) => Expense.fromJson(e)));
      });
    }

    // Load budgets
    final budgetsString = prefs.getString('budgets');
    if (budgetsString != null) {
      final budgetsList = jsonDecode(budgetsString) as List;
      setState(() {
        _budgets.clear();
        _budgets.addAll(budgetsList.map((b) => Budget.fromJson(b)));
      });
    }
  }

  void _addExpense(String title, double amount, String category) {
    final newExpense = Expense(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      amount: amount,
      date: DateTime.now(),
      category: category,
    );

    setState(() {
      _expenses.add(newExpense);
    });
    _saveData();
  }

  void _deleteExpense(String id) {
    setState(() {
      _expenses.removeWhere((expense) => expense.id == id);
    });
    _saveData();
  }

  void _addBudget(String category, double amount) {
    final currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
    final existingBudgetIndex = _budgets.indexWhere(
      (budget) =>
          budget.category == category &&
          budget.month.month == currentMonth.month &&
          budget.month.year == currentMonth.year,
    );

    setState(() {
      if (existingBudgetIndex >= 0) {
        _budgets[existingBudgetIndex] = Budget(
          category: category,
          amount: amount,
          month: currentMonth,
        );
      } else {
        _budgets.add(
          Budget(category: category, amount: amount, month: currentMonth),
        );
      }
    });
    _saveData();
  }

  // Analytics methods
  double get _totalExpenses {
    return _getFilteredExpenses().fold(
      0.0,
      (sum, expense) => sum + expense.amount,
    );
  }

  double get _monthlyTotal {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    return _expenses
        .where((expense) => expense.date.isAfter(monthStart))
        .fold(0.0, (sum, expense) => sum + expense.amount);
  }

  List<Expense> _getFilteredExpenses() {
    return _expenses.where((expense) {
      bool matchesSearch = expense.title.toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
      bool matchesCategory =
          _filterCategory == 'All' || expense.category == _filterCategory;
      bool matchesDate =
          expense.date.isAfter(
            _filterStartDate.subtract(const Duration(days: 1)),
          ) &&
          expense.date.isBefore(_filterEndDate.add(const Duration(days: 1)));
      return matchesSearch && matchesCategory && matchesDate;
    }).toList();
  }

  Map<String, double> _getCategoryTotals() {
    Map<String, double> categoryTotals = {};
    for (var expense in _getFilteredExpenses()) {
      categoryTotals[expense.category] =
          (categoryTotals[expense.category] ?? 0) + expense.amount;
    }
    return categoryTotals;
  }

  List<MapEntry<String, double>> _getTopCategories() {
    var categoryTotals = _getCategoryTotals();
    var sortedEntries = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sortedEntries.take(5).toList();
  }

  double _getCategoryBudgetUsage(String category) {
    final currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
    final budget = _budgets.firstWhere(
      (b) =>
          b.category == category &&
          b.month.month == currentMonth.month &&
          b.month.year == currentMonth.year,
      orElse: () => Budget(category: category, amount: 0, month: currentMonth),
    );

    final spent = _expenses
        .where((e) => e.category == category && e.date.isAfter(currentMonth))
        .fold(0.0, (sum, e) => sum + e.amount);

    return budget.amount > 0 ? spent / budget.amount : 0.0;
  }

  void _showAddExpenseModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) =>
          AddExpenseModal(onAddExpense: _addExpense, categories: _categories),
    );
  }

  void _showBudgetModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => BudgetModal(
        onAddBudget: _addBudget,
        categories: _categories,
        budgets: _budgets,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Tracker'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.home), text: 'Home'),
            Tab(icon: Icon(Icons.analytics), text: 'Analytics'),
            Tab(icon: Icon(Icons.account_balance_wallet), text: 'Budget'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildHomeTab(), _buildAnalyticsTab(), _buildBudgetTab()],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddExpenseModal,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildHomeTab() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue, Colors.blueAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Text(
                        'Total Expenses',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      Text(
                        '₹${_totalExpenses.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      const Text(
                        'This Month',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      Text(
                        '₹${_monthlyTotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search expenses...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _filterCategory,
                items: ['All', ..._categories].map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _filterCategory = value!;
                  });
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: _getFilteredExpenses().isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No expenses found',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _getFilteredExpenses().length,
                  itemBuilder: (ctx, index) {
                    final expense = _getFilteredExpenses()[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getCategoryColor(expense.category),
                          child: Icon(
                            _getCategoryIcon(expense.category),
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          expense.title,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${expense.category} • ${_formatDate(expense.date)}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '₹${expense.amount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteExpense(expense.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsTab() {
    final categoryTotals = _getCategoryTotals();
    final topCategories = _getTopCategories();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Expense Analytics',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          // Pie Chart
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Category Breakdown',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: CustomPaint(
                      size: Size.infinite,
                      painter: PieChartPainter(
                        categoryTotals,
                        _getCategoryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Top Categories
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Top Spending Categories',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ...topCategories.map((entry) {
                    final percentage = _totalExpenses > 0
                        ? (entry.value / _totalExpenses * 100)
                        : 0;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: _getCategoryColor(entry.key),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Text(entry.key)),
                          Text(
                            '₹${entry.value.toStringAsFixed(0)} (${percentage.toStringAsFixed(1)}%)',
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Stats Cards
          Row(
            children: [
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Text(
                          'Average Daily',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        Text(
                          '₹${(_monthlyTotal / DateTime.now().day).toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Text(
                          'Total Transactions',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        Text(
                          '${_getFilteredExpenses().length}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetTab() {
    final currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Monthly Budgets',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              ElevatedButton(
                onPressed: _showBudgetModal,
                child: const Text('Set Budget'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ..._categories.map((category) {
            final budget = _budgets.firstWhere(
              (b) =>
                  b.category == category &&
                  b.month.month == currentMonth.month &&
                  b.month.year == currentMonth.year,
              orElse: () =>
                  Budget(category: category, amount: 0, month: currentMonth),
            );

            final spent = _expenses
                .where(
                  (e) => e.category == category && e.date.isAfter(currentMonth),
                )
                .fold(0.0, (sum, e) => sum + e.amount);

            final percentage = budget.amount > 0 ? spent / budget.amount : 0.0;
            final isOverBudget = percentage > 1.0;

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _getCategoryIcon(category),
                              color: _getCategoryColor(category),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              category,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          budget.amount > 0
                              ? '₹${spent.toStringAsFixed(0)} / ₹${budget.amount.toStringAsFixed(0)}'
                              : 'No Budget Set',
                          style: TextStyle(
                            color: isOverBudget ? Colors.red : Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (budget.amount > 0) ...[
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: percentage.clamp(0.0, 1.0),
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isOverBudget
                              ? Colors.red
                              : _getCategoryColor(category),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isOverBudget
                            ? 'Over budget by ₹${(spent - budget.amount).toStringAsFixed(0)}'
                            : '₹${(budget.amount - spent).toStringAsFixed(0)} remaining',
                        style: TextStyle(
                          fontSize: 12,
                          color: isOverBudget ? Colors.red : Colors.green,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    List<String> months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month]} ${date.day}, ${date.year}';
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Food':
        return Colors.orange;
      case 'Transportation':
        return Colors.green;
      case 'Shopping':
        return Colors.purple;
      case 'Entertainment':
        return Colors.pink;
      case 'Bills':
        return Colors.red;
      case 'Healthcare':
        return Colors.teal;
      case 'Education': // Added Education color
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Food':
        return Icons.restaurant;
      case 'Transportation':
        return Icons.directions_car;
      case 'Shopping':
        return Icons.shopping_bag;
      case 'Entertainment':
        return Icons.movie;
      case 'Bills':
        return Icons.receipt;
      case 'Healthcare':
        return Icons.local_hospital;
      case 'Education': // Added Education icon
        return Icons.school;
      default:
        return Icons.category;
    }
  }
}

class PieChartPainter extends CustomPainter {
  final Map<String, double> data;
  final Color Function(String) getColor;

  PieChartPainter(this.data, this.getColor);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 20;
    final total = data.values.fold(0.0, (sum, value) => sum + value);

    double startAngle = -math.pi / 2;

    for (final entry in data.entries) {
      final sweepAngle = (entry.value / total) * 2 * math.pi;
      final paint = Paint()
        ..color = getColor(entry.key)
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class AddExpenseModal extends StatefulWidget {
  final Function(String, double, String) onAddExpense;
  final List<String> categories;

  const AddExpenseModal({
    super.key,
    required this.onAddExpense,
    required this.categories,
  });

  @override
  _AddExpenseModalState createState() => _AddExpenseModalState();
}

class _AddExpenseModalState extends State<AddExpenseModal> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  String _selectedCategory = 'Food';

  void _submitExpense() {
    final title = _titleController.text.trim();
    final amount = double.tryParse(_amountController.text);

    if (title.isEmpty || amount == null || amount <= 0) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Invalid Input'),
          content: const Text('Please enter a valid title and amount.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    widget.onAddExpense(title, amount, _selectedCategory);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Add New Expense',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Expense Title',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Amount',
              prefixText: '₹ ',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _selectedCategory,
            decoration: const InputDecoration(
              labelText: 'Category',
              border: OutlineInputBorder(),
            ),
            items: widget.categories.map((category) {
              return DropdownMenuItem(value: category, child: Text(category));
            }).toList(),
            onChanged: (value) => setState(() => _selectedCategory = value!),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: _submitExpense,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Add Expense'),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class BudgetModal extends StatefulWidget {
  final Function(String, double) onAddBudget;
  final List<String> categories;
  final List<Budget> budgets;

  const BudgetModal({
    super.key,
    required this.onAddBudget,
    required this.categories,
    required this.budgets,
  });

  @override
  _BudgetModalState createState() => _BudgetModalState();
}

class _BudgetModalState extends State<BudgetModal> {
  final _amountController = TextEditingController();
  String _selectedCategory = 'Food';

  @override
  void initState() {
    super.initState();
    _loadCurrentBudget();
  }

  void _loadCurrentBudget() {
    final currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
    final existingBudget = widget.budgets.firstWhere(
      (budget) =>
          budget.category == _selectedCategory &&
          budget.month.month == currentMonth.month &&
          budget.month.year == currentMonth.year,
      orElse: () =>
          Budget(category: _selectedCategory, amount: 0, month: currentMonth),
    );

    if (existingBudget.amount > 0) {
      _amountController.text = existingBudget.amount.toString();
    }
  }

  void _submitBudget() {
    final amount = double.tryParse(_amountController.text);

    if (amount == null || amount < 0) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Invalid Input'),
          content: const Text('Please enter a valid budget amount.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    widget.onAddBudget(_selectedCategory, amount);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Set Monthly Budget',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            initialValue: _selectedCategory,
            decoration: const InputDecoration(
              labelText: 'Category',
              border: OutlineInputBorder(),
            ),
            items: widget.categories.map((category) {
              return DropdownMenuItem(value: category, child: Text(category));
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedCategory = value!;
                _loadCurrentBudget();
              });
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Budget Amount',
              prefixText: '₹ ',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: _submitBudget,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Set Budget'),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
