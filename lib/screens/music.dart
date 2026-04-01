const Spacer(), // This acts like a spring to push the footer to the bottom

Padding(
  padding: const EdgeInsets.only(bottom: 40.0),
  child: Column(
    children: [
      // That subtle line above the name in your HTML
      Container(
        width: 30, 
        // height: 1, 
        color: const Color(0xFF2d2d4a),
      ),
      const SizedBox(height: 12),
      const Text(
        'for KouZoya 🌹',
        style: TextStyle(
          fontSize: 12,
          fontStyle: FontStyle.italic,
          color: Color(0xFF4a4aaa),
        ),
      ),
    ],
  ),
),