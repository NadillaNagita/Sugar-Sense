// support_center_screen.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportCenterScreen extends StatelessWidget {
  const SupportCenterScreen({Key? key}) : super(key: key);

  static const _backgroundColor = Color.fromARGB(200, 33, 0, 83);
  static const _email = 'pblif39@gmail.com';
  static const _phone = '+6281321724567';
  static const _faqItems = <_FaqItem>[
    _FaqItem(
      question: 'What is the Daily Sugar Intake Tracker App?',
      answer:
          'This mobile app monitors your daily sugar intake based on USDA standards and the Open Food Facts database.',
    ),
    _FaqItem(
      question: 'How do I scan a food barcode?',
      answer:
          'Tap the camera icon on the main screen and point it at the barcode to retrieve sugar information.',
    ),
    _FaqItem(
      question: 'How accurate is the sugar data shown?',
      answer:
          'The data is sourced from USDA and Open Food Facts, so its accuracy reflects those references.',
    ),
    _FaqItem(
      question: 'Can I set a daily sugar limit?',
      answer:
          'Yes, you can set a daily target in the App Settings according to health recommendations.',
    ),
    _FaqItem(
      question: 'How do I report an issue or suggestion?',
      answer:
          'Send an email to $_email or WhatsApp to $_phone with details of your issue or suggestion.',
    ),
  ];

  Future<void> _launchEmail() async {
    final uri = Uri(scheme: 'mailto', path: _email);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _launchPhone() async {
    final uri = Uri(scheme: 'tel', path: _phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

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
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      const Text(
                        'Support Center',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Need help or have questions about the Daily Sugar Intake Tracker App based on USDA standards and Open Food Facts?',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Contact Card
                      _InfoCard(
                        icon: Icons.contact_mail,
                        title: 'Contact Information',
                        children: [
                          _InfoRow(
                            icon: Icons.email_outlined,
                            label: 'Email',
                            value: _email,
                            onTap: _launchEmail,
                          ),
                          const SizedBox(height: 12),
                          _InfoRow(
                            icon: Icons.phone_outlined,
                            label: 'Phone',
                            value: _phone,
                            onTap: _launchPhone,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // FAQ Card with themed ExpansionPanelList
                      _InfoCard(
                        icon: Icons.help_outline,
                        title: 'Frequently Asked Questions',
                        children: [
                          Theme(
                            data: Theme.of(context).copyWith(
                              cardColor:
                                  Colors.white10, // match card background
                              dividerColor: Colors.white24,
                            ),
                            child: ExpansionPanelList.radio(
                              animationDuration:
                                  const Duration(milliseconds: 300),
                              expandedHeaderPadding: EdgeInsets.zero,
                              children: _faqItems.map((item) {
                                return ExpansionPanelRadio(
                                  value: item.question,
                                  headerBuilder: (ctx, isOpen) {
                                    return ListTile(
                                      title: Text(
                                        item.question,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      trailing: Icon(
                                        isOpen
                                            ? Icons.keyboard_arrow_up
                                            : Icons.keyboard_arrow_down,
                                        color: Colors.white70,
                                      ),
                                    );
                                  },
                                  body: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    child: Text(
                                      item.answer,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                        height: 1.5,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Back Button
                      Center(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'Back to Profile',
                            style: TextStyle(
                              color: Colors.white70,
                              decoration: TextDecoration.underline,
                            ),
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

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.lightBlueAccent, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.lightBlueAccent,
                fontSize: 14,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqItem {
  final String question;
  final String answer;
  const _FaqItem({required this.question, required this.answer});
}
