import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isDark = prefs.getBool('isDarkMode') ?? false;

  runApp(HealthSuiteApp(isDarkInit: isDark));
}

class HealthSuiteApp extends StatefulWidget {
  final bool isDarkInit;
  const HealthSuiteApp({super.key, required this.isDarkInit});

  @override
  State<HealthSuiteApp> createState() => _HealthSuiteAppState();
}

class _HealthSuiteAppState extends State<HealthSuiteApp> {
  late ThemeMode _themeMode;

  @override
  void initState() {
    super.initState();
    _themeMode = widget.isDarkInit ? ThemeMode.dark : ThemeMode.light;
  }

  void _toggleTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      if (_themeMode == ThemeMode.light) {
        _themeMode = ThemeMode.dark;
        prefs.setBool('isDarkMode', true);
      } else {
        _themeMode = ThemeMode.light;
        prefs.setBool('isDarkMode', false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pro Health Suite',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFF4F7F6),
        cardColor: Colors.white,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardColor: const Color(0xFF1E1E1E),
        useMaterial3: true,
      ),
      home: MainHomeScreen(
        onToggleTheme: _toggleTheme, 
        isDarkMode: _themeMode == ThemeMode.dark
      ),
    );
  }
}

class MainHomeScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final bool isDarkMode;

  const MainHomeScreen({
    super.key, 
    required this.onToggleTheme, 
    required this.isDarkMode
  });

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _currentProfile = "Renante Fullo";
  final List<String> _profiles = ["Renante Fullo", "Guest"];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pro Health Suite', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          DropdownButton<String>(
            value: _currentProfile,
            underline: const SizedBox(),
            items: _profiles.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _currentProfile = val);
            },
          ),
          IconButton(
            icon: Icon(widget.isDarkMode ? Icons.wb_sunny : Icons.nightlight_round),
            onPressed: widget.onToggleTheme,
            tooltip: 'Toggle Dark Mode',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.calculate_outlined), text: 'Calculators'),
            Tab(icon: Icon(Icons.timer_outlined), text: 'Fasting & Sleep'),
            Tab(icon: Icon(Icons.show_chart_outlined), text: 'Progress'),
            Tab(icon: Icon(Icons.access_time_outlined), text: 'Body Clock'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          CalculatorTab(profile: _currentProfile),
          FastingSleepTab(profile: _currentProfile),
          ProgressTab(profile: _currentProfile),
          const BodyClockTab(),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(10),
        color: Theme.of(context).cardColor,
        child: const Text(
          'Developed by Renante Fullo',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12),
        ),
      ),
    );
  }
}

// ==================== TAB 1: CALCULATORS ====================
class CalculatorTab extends StatefulWidget {
  final String profile;
  const CalculatorTab({super.key, required this.profile});

  @override
  State<CalculatorTab> createState() => _CalculatorTabState();
}

class _CalculatorTabState extends State<CalculatorTab> {
  final _weightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();

  final String _gender = 'male';
  final String _goal = 'maintain';
  String _resultText = '';

  @override
  void initState() {
    super.initState();
    _loadSavedInputs();
    
    // Auto-save habang nagta-type
    _weightCtrl.addListener(() => _saveInput('weight', _weightCtrl.text));
    _heightCtrl.addListener(() => _saveInput('height', _heightCtrl.text));
    _ageCtrl.addListener(() => _saveInput('age', _ageCtrl.text));
  }

  @override
  void didUpdateWidget(covariant CalculatorTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profile != widget.profile) {
      _loadSavedInputs();
    }
  }

  void _loadSavedInputs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _weightCtrl.text = prefs.getString('input_weight_${widget.profile}') ?? '';
      _heightCtrl.text = prefs.getString('input_height_${widget.profile}') ?? '';
      _ageCtrl.text = prefs.getString('input_age_${widget.profile}') ?? '';
    });
  }

  void _saveInput(String key, String value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('input_${key}_${widget.profile}', value);
  }

  void _calculate() async {
    double w = double.tryParse(_weightCtrl.text) ?? 0;
    double h = double.tryParse(_heightCtrl.text) ?? 0;
    int age = int.tryParse(_ageCtrl.text) ?? 0;

    if (w <= 0 || h <= 0 || age <= 0) {
      setState(() => _resultText = 'Pakilagay ng tamang numero.');
      return;
    }

    double bmi = w / pow(h / 100, 2);
    String cat = bmi < 18.5 ? 'Underweight' : bmi < 24.9 ? 'Normal' : 'Overweight/Obese';

    double bmr = (_gender == 'male')
        ? (10 * w) + (6.25 * h) - (5 * age) + 5
        : (10 * w) + (6.25 * h) - (5 * age) - 161;

    double calories = bmr * 1.375;
    if (_goal == 'lose') calories -= 500;
    if (_goal == 'gain') calories += 500;

    setState(() {
      _resultText = 'BMI: ${bmi.toStringAsFixed(2)} ($cat)\n'
          'Daily Target: ${calories.round()} kcal\n'
          'Water Target: ${(w * 0.033).toStringAsFixed(1)} Liters';
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList('history_${widget.profile}') ?? [];
    history.add('${DateFormat('MMM d').format(DateTime.now())},${bmi.toStringAsFixed(1)},$w');
    if (history.length > 7) history.removeAt(0);
    await prefs.setStringList('history_${widget.profile}', history);
  }

  void _clearData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('history_${widget.profile}');
    await prefs.remove('input_weight_${widget.profile}');
    await prefs.remove('input_height_${widget.profile}');
    await prefs.remove('input_age_${widget.profile}');
    setState(() {
      _weightCtrl.clear();
      _heightCtrl.clear();
      _ageCtrl.clear();
      _resultText = '';
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Na-clear na ang lahat ng inputs at history!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Master Body Metrics", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextButton.icon(
              onPressed: _clearData,
              icon: const Icon(Icons.delete_forever, color: Colors.red, size: 18),
              label: const Text("Clear All", style: TextStyle(color: Colors.red)),
            )
          ],
        ),
        const SizedBox(height: 10),
        TextField(controller: _weightCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Weight (kg)')),
        TextField(controller: _heightCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Height (cm)')),
        TextField(controller: _ageCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Age (Edad)')),
        const SizedBox(height: 15),
        ElevatedButton(onPressed: _calculate, child: const Text('Calculate Metrics')),
        if (_resultText.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 15),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withOpacity(0.5))
            ),
            child: Text(_resultText, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          )
      ],
    );
  }
}

// ==================== TAB 2: FASTING & SLEEP ====================
class FastingSleepTab extends StatefulWidget {
  final String profile;
  const FastingSleepTab({super.key, required this.profile});

  @override
  State<FastingSleepTab> createState() => _FastingSleepTabState();
}

class _FastingSleepTabState extends State<FastingSleepTab> {
  Timer? _timer;
  Duration _remaining = Duration.zero;

  void _startFast(int hours) {
    _timer?.cancel();
    DateTime endTime = DateTime.now().add(Duration(hours: hours));
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      final diff = endTime.difference(DateTime.now());
      if (diff.isNegative) {
        t.cancel();
        setState(() => _remaining = Duration.zero);
      } else {
        setState(() => _remaining = diff);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text("Intermittent Fasting Live Tracker", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(onPressed: () => _startFast(16), child: const Text("Start 16:8")),
            ElevatedButton(onPressed: () => _startFast(18), child: const Text("Start 18:6")),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          _remaining == Duration.zero
              ? "No Active Fasting"
              : "Remaining: ${_remaining.inHours}:${_remaining.inMinutes.remainder(60).toString().padLeft(2, '0')}:${_remaining.inSeconds.remainder(60).toString().padLeft(2, '0')}",
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
        )
      ],
    );
  }
}

// ==================== TAB 3: PROGRESS ====================
class ProgressTab extends StatefulWidget {
  final String profile;
  const ProgressTab({super.key, required this.profile});

  @override
  State<ProgressTab> createState() => _ProgressTabState();
}

class _ProgressTabState extends State<ProgressTab> {
  Future<List<FlSpot>> _getChartData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList('history_${widget.profile}') ?? [];
    List<FlSpot> spots = [];
    for (int i = 0; i < history.length; i++) {
      var parts = history[i].split(',');
      if (parts.length >= 3) {
        spots.add(FlSpot(i.toDouble(), double.tryParse(parts[2]) ?? 0));
      }
    }
    return spots;
  }

  void _clearHistory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('history_${widget.profile}');
    setState(() {});
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Na-delete na ang history data!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<FlSpot>>(
      future: _getChartData(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("Walang data na naitala. Mag-compute muna sa Calculators tab."));
        }
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Weight Progress Chart", style: TextStyle(fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: _clearHistory,
                    tooltip: "Clear Progress History",
                  )
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: LineChart(
                  LineChartData(
                    lineBarsData: [LineChartBarData(spots: snapshot.data!, isCurved: true, color: Colors.blue)],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ==================== TAB 4: CIRCADIAN BODY CLOCK ====================
class BodyClockTab extends StatelessWidget {
  const BodyClockTab({super.key});

  final List<Map<String, dynamic>> organs = const [
    {"start": 23, "end": 1, "time": "11:00 PM - 1:00 AM", "organ": "Gallbladder", "act": "Cellular Repair"},
    {"start": 1, "end": 3, "time": "1:00 AM - 3:00 AM", "organ": "Liver", "act": "Deep Blood Detox"},
    {"start": 3, "end": 5, "time": "3:00 AM - 5:00 AM", "organ": "Lungs", "act": "Oxygenation & Clearing"},
    {"start": 5, "end": 7, "time": "5:00 AM - 7:00 AM", "organ": "Large Intestine", "act": "Bowel Movement"},
    {"start": 7, "end": 9, "time": "7:00 AM - 9:00 AM", "organ": "Stomach", "act": "Peak Digestion (Almusal)"},
    {"start": 9, "end": 11, "time": "9:00 AM - 11:00 AM", "organ": "Spleen/Pancreas", "act": "Nutrient Absorption"},
    {"start": 11, "end": 13, "time": "11:00 AM - 1:00 PM", "organ": "Heart", "act": "Circulation (Tanghalian)"},
    {"start": 13, "end": 15, "time": "1:00 PM - 3:00 PM", "organ": "Small Intestine", "act": "Nutrient Assimilation"},
    {"start": 15, "end": 17, "time": "3:00 PM - 5:00 PM", "organ": "Bladder", "act": "Fluid Balance (Tubig)"},
    {"start": 17, "end": 19, "time": "5:00 PM - 7:00 PM", "organ": "Kidneys", "act": "Energy Storage (Hapunan)"},
    {"start": 19, "end": 21, "time": "7:00 PM - 9:00 PM", "organ": "Pericardium", "act": "Brain Relaxation"},
    {"start": 21, "end": 23, "time": "9:00 PM - 11:00 PM", "organ": "Endocrine System", "act": "Hormone Balance"},
  ];

  bool _isActive(int start, int end, int currentHour) {
    if (start > end) {
      return currentHour >= start || currentHour < end;
    }
    return currentHour >= start && currentHour < end;
  }

  @override
  Widget build(BuildContext context) {
    int currentHour = DateTime.now().hour;

    return ListView.builder(
      itemCount: organs.length,
      itemBuilder: (context, i) {
        final item = organs[i];
        bool active = _isActive(item['start'], item['end'], currentHour);

        return Card(
          color: active ? Colors.amber.withOpacity(0.25) : null,
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: ListTile(
            title: Text(
              "${item['organ']} ${active ? '🔥 ACTIVE NOW' : ''}",
              style: TextStyle(
                fontWeight: active ? FontWeight.bold : FontWeight.normal, 
                color: active ? Colors.orange : null
              )
            ),
            subtitle: Text("${item['time']}\nAction: ${item['act']}"),
            isThreeLine: true,
          ),
        );
      },
    );
  }
}
