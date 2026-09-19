import 'package:flutter/material.dart';
import 'camera_screen.dart';

class CategoryScreen extends StatelessWidget {
  const CategoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Repair Category'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'What do you want to repair?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 30),

            _categoryButton(
              context,
              'Electrical',
              Icons.electrical_services,
            ),

            _categoryButton(
              context,
              'Plumbing',
              Icons.water_drop,
            ),

            _categoryButton(
              context,
              'Furniture',
              Icons.chair,
            ),

            _categoryButton(
              context,
              'Appliance',
              Icons.home_repair_service,
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoryButton(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CameraScreen(),
            ),
          );
        },
        icon: Icon(icon),
        label: Text(title),
      ),
    );
  }
}
