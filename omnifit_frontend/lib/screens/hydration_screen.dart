import 'package:flutter/material.dart';

class HydrationScreen extends StatefulWidget {
  // The constructor 
  // [super.key] uniquely identifies this widget in the widget tree for efficient rendering 
  const HydrationScreen({super.key});

  // Creates the mutable state for this screen, which will hold the current water intake, daily goal, history of intake, and reminder status
  @override
  State<HydrationScreen> createState() => _HydrationScreenState();
}

class _HydrationScreenState extends State<HydrationScreen> {
  int currentIntake = 0;
  int dailyGoal = 2500;
  List<Map<String, String>> history = [];
  bool isReminderOn = false;

  void _updateWater(int amount) {
    setState(() {
      int previousIntake = currentIntake;
      currentIntake += amount;
      
      if (currentIntake < 0) currentIntake = 0;

      // Add to history only if the value changed
      if (currentIntake != previousIntake) {
        final now = TimeOfDay.now(); // The current time is captured to log when the water intake was updated
        final timeString = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
        
        String logAmount = amount > 0 ? '+$amount ml' : '$amount ml';
        
        // Insert at index 0 to keep the most recent logs at the top
        history.insert(0, {'amount': logAmount, 'time': timeString});
      }
    });
  }

  // Show popup to set the daily goal
  void _showSetGoalDialog() {
    final TextEditingController goalController = TextEditingController(text: dailyGoal.toString());
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Setează Scopul Zilnic'),
          content: TextField(
            controller: goalController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              suffixText: 'ml',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Anulează', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                final newGoal = int.tryParse(goalController.text);
                if (newGoal != null && newGoal > 0) {
                  setState(() {
                    dailyGoal = newGoal;
                  });
                }
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.lightBlue),
              child: const Text('Salvează'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Calculăm progresul (între 0.0 și 1.0)
    double progress = currentIntake / dailyGoal;
    if (progress > 1.0) progress = 1.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Log Hydration', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: _showSetGoalDialog,
            icon: const Icon(Icons.edit, size: 18, color: Colors.lightBlue),
            label: const Text('Setează Scop', style: TextStyle(color: Colors.lightBlue, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // --- BARA DE PROGRES (Circulară) ---
            Center(
              child: SizedBox(
                width: 200,
                height: 200,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 16,
                      backgroundColor: Colors.lightBlue.withOpacity(0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.lightBlue),
                    ),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.water_drop, color: Colors.lightBlue.shade300, size: 40),
                          const SizedBox(height: 8),
                          Text(
                            '$currentIntake',
                            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                          Text(
                            '/ $dailyGoal ml',
                            style: const TextStyle(fontSize: 16, color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),

            // --- BUTOANE RAPIDE (+ / -) ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildWaterButton('-250 ml', () => _updateWater(-250), Colors.redAccent.withOpacity(0.8)),
                _buildWaterButton('+250 ml', () => _updateWater(250), Colors.lightBlue),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildWaterButton('+500 ml', () => _updateWater(500), Colors.blue),
                _buildWaterButton('+1000 ml', () => _updateWater(1000), Colors.blue.shade700),
              ],
            ),
            
            const SizedBox(height: 40),
            const Divider(),

            // --- ISTORIC ---
            Align(
              alignment: Alignment.centerLeft,
              child: const Text('Istoric Azi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),
            if (history.isEmpty)
              const Text('Încă nu ai băut apă astăzi.', style: TextStyle(color: Colors.black54))
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: history.length,
                itemBuilder: (context, index) {
                  final item = history[index];
                  final isPositive = item['amount']!.startsWith('+');
                  return ListTile(
                    leading: Icon(
                      isPositive ? Icons.water_drop : Icons.remove_circle_outline,
                      color: isPositive ? Colors.lightBlue : Colors.redAccent,
                    ),
                    title: Text(item['amount']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                    trailing: Text(item['time']!, style: const TextStyle(color: Colors.black54)),
                    contentPadding: EdgeInsets.zero,
                  );
                },
              ),

            const SizedBox(height: 24),
            const Divider(),

            // --- MEMENTO (Reminder) ---
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Memento', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              subtitle: const Text('Amintește-mi să beau apă la fiecare oră.'),
              value: isReminderOn,
              activeColor: Colors.lightBlue,
              onChanged: (bool value) {
                setState(() {
                  isReminderOn = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  // Design pentru butoanele de adăugare apă
  Widget _buildWaterButton(String label, VoidCallback onTap, Color color) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
      ),
      child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
    );
  }
}