import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  static const _backgroundColor = Color.fromARGB(200, 33, 0, 83);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: Stack(
        children: [
          // Dark overlay layer
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
                      // Header
                      Column(
                        children: const [
                          Icon(Icons.privacy_tip_outlined,
                              size: 48, color: Colors.lightBlueAccent),
                          SizedBox(height: 12),
                          Text(
                            'Privacy Policy',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Your privacy is important. This policy explains how the Daily Sugar Intake Tracker App collects, uses, and protects your data.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Policy card
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
                              _PolicyItem(
                                title: 'Information Collected',
                                description:
                                    '• Personal details you provide (name, email)\n• App usage data and preferences',
                              ),
                              SizedBox(height: 16),
                              _PolicyItem(
                                title: 'Use of Information',
                                description:
                                    '• To improve app features and user experience\n• To send notifications and updates',
                              ),
                              SizedBox(height: 16),
                              _PolicyItem(
                                title: 'Data Security',
                                description:
                                    '• Industry-standard measures to protect data\n• No sharing with third parties without consent',
                              ),
                              SizedBox(height: 16),
                              _PolicyItem(
                                title: 'Your Rights',
                                description:
                                    '• Access, update, or delete your data anytime\n• Contact support for privacy concerns',
                              ),
                              SizedBox(height: 16),
                              _PolicyItem(
                                title: 'Policy Updates',
                                description:
                                    '• We may revise this policy as needed; changes will be posted here',
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Back button
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

class _PolicyItem extends StatelessWidget {
  final String title;
  final String description;
  const _PolicyItem({required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.lightBlueAccent,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
