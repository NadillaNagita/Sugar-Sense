import 'package:flutter/material.dart';

class TermsConditionScreen extends StatelessWidget {
  const TermsConditionScreen({Key? key}) : super(key: key);

  static const _backgroundColor = Color.fromARGB(200, 33, 0, 83);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: Stack(
        children: [
          Container(color: Colors.black.withOpacity(0.0)),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header with icon
                      Column(
                        children: const [
                          Icon(Icons.article_outlined,
                              size: 48, color: Colors.lightBlueAccent),
                          SizedBox(height: 12),
                          Text(
                            'Terms & Conditions',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Please review the terms for using the Daily Sugar Intake Tracker App.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Terms card
                      Card(
                        color: Colors.white10,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              _TermItem(
                                  number: 1,
                                  text:
                                      'Data Usage: Access camera for barcode scanning.'),
                              _TermItem(
                                  number: 2,
                                  text:
                                      'Accuracy: Nutritional data sourced from USDA & Open Food Facts; actual values may vary.'),
                              _TermItem(
                                  number: 3,
                                  text:
                                      'User Responsibility: Verify nutritional info before making decisions.'),
                              _TermItem(
                                  number: 4,
                                  text:
                                      'Updates: Terms may change with data source or feature updates.'),
                              _TermItem(
                                  number: 5,
                                  text:
                                      'Liability: App provided “as is”; developers not liable for use outcomes.'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Back button without arrow icon
                      Center(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'Back to Profile',
                            style: TextStyle(
                              color: Colors.white70,
                              decoration: TextDecoration.underline,
                              fontSize: 14,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TermItem extends StatelessWidget {
  final int number;
  final String text;
  const _TermItem({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$number.',
            style: const TextStyle(
              color: Colors.lightBlueAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
