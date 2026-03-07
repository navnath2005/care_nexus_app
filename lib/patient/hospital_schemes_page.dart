import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HospitalSchemesPage extends StatefulWidget {
  const HospitalSchemesPage({super.key});

  @override
  State<HospitalSchemesPage> createState() => _HospitalSchemesPageState();
}

class _HospitalSchemesPageState extends State<HospitalSchemesPage> {
  String selectedCategory = 'All';

  final Map<String, List<Map<String, String>>> schemesByCategory = {
    'National Health Protection': [
      {
        "title": "Ayushman Bharat – PM-JAY",
        "desc":
            "World's largest health insurance scheme covering poor families.",
        "icon": "🏥",
        "url": "https://pmjay.gov.in/",
      },
      {
        "title": "Mahatma Jyotiba Phule Jan Arogya Yojana",
        "desc": "Maharashtra's health insurance scheme for poor families.",
        "icon": "🏛️",
        "url": "https://mjpjay.maharashtra.gov.in/",
      },
      {
        "title": "Rashtriya Swasthya Bima Yojana",
        "desc": "Health insurance for unorganized sector workers.",
        "icon": "🛡️",
        "url": "https://www.rsby.gov.in/",
      },
    ],
    'Health Services for Employees': [
      {
        "title": "Central Government Health Scheme",
        "desc":
            "Health scheme for central government employees and pensioners.",
        "icon": "👨‍💼",
        "url": "https://cghs.gov.in/",
      },
      {
        "title": "Employees' State Insurance Scheme",
        "desc": "Social security and health insurance for workers.",
        "icon": "🏢",
        "url": "https://www.esic.gov.in/",
      },
    ],
    'Maternal and Child Health': [
      {
        "title": "Janani Suraksha Yojana",
        "desc": "Safe delivery and maternal health care scheme.",
        "icon": "👶",
        "url": "https://www.nhm.gov.in/nrhm-components/rmnch-a.html",
      },
      {
        "title": "Pradhan Mantri Matru Vandana Yojana",
        "desc":
            "Conditional cash transfer to pregnant women and lactating mothers.",
        "icon": "👩‍🤱",
        "url": "https://www.pmmvy.nic.in/",
      },
      {
        "title": "Janani Shishu Suraksha Karyakram",
        "desc": "Free delivery and care for mother and child.",
        "icon": "🤰",
        "url": "https://www.nhm.gov.in/",
      },
    ],
    'Insurance and Safety': [
      {
        "title": "Pradhan Mantri Suraksha Bima Yojana",
        "desc": "Accident insurance cover for all ages at minimum premium.",
        "icon": "🛡️",
        "url": "https://www.jansuraksha.gov.in/",
      },
      {
        "title": "Pradhan Mantri Jeevan Jyoti Bima Yojana",
        "desc": "Life insurance cover for natural and accidental deaths.",
        "icon": "✨",
        "url": "https://www.jansuraksha.gov.in/",
      },
    ],
    'Disease-Specific Programs': [
      {
        "title": "National AIDS Control Programme",
        "desc": "Prevention, treatment and care for HIV/AIDS patients.",
        "icon": "🔬",
        "url": "https://naco.gov.in/",
      },
      {
        "title": "National Tuberculosis Elimination Programme",
        "desc": "Free diagnosis and treatment for tuberculosis.",
        "icon": "🫁",
        "url": "https://tbcindia.gov.in/",
      },
      {
        "title":
            "National Programme for Prevention and Control of Cancer, Diabetes, Cardiovascular Diseases and Stroke",
        "desc": "Prevention and control of chronic diseases.",
        "icon": "❤️",
        "url": "https://nmhp.gov.in/",
      },
    ],
  };

  // Function to launch URLs
  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Could not launch $url')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  List<Map<String, String>> getFilteredSchemes() {
    if (selectedCategory == 'All') {
      final allSchemes = <Map<String, String>>[];
      schemesByCategory.forEach((key, value) {
        allSchemes.addAll(value);
      });
      return allSchemes;
    }
    return schemesByCategory[selectedCategory] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final categories = ['All', ...schemesByCategory.keys];
    final filteredSchemes = getFilteredSchemes();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Hospital Schemes"),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Category Filter
          Container(
            color: const Color(0xFF1E3A8A).withOpacity(0.1),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: categories.map((category) {
                  final isSelected = selectedCategory == category;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(category),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          selectedCategory = category;
                        });
                      },
                      backgroundColor: Colors.white,
                      selectedColor: const Color(0xFF1E3A8A),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Schemes List
          Expanded(
            child: filteredSchemes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No schemes found',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredSchemes.length,
                    itemBuilder: (context, index) {
                      final scheme = filteredSchemes[index];

                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                        margin: const EdgeInsets.only(bottom: 15),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFF1E3A8A),
                            child: Text(
                              scheme["icon"] ?? "🏥",
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                          title: Text(
                            scheme["title"] ?? "",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            scheme["desc"] ?? "",
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SchemeDetailsPage(
                                  title: scheme["title"] ?? "",
                                  description: scheme["desc"] ?? "",
                                  url: scheme["url"] ?? "",
                                  icon: scheme["icon"] ?? "🏥",
                                  onLaunchURL: _launchURL,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class SchemeDetailsPage extends StatelessWidget {
  final String title;
  final String description;
  final String url;
  final String icon;
  final Function(String) onLaunchURL;

  const SchemeDetailsPage({
    super.key,
    required this.title,
    required this.description,
    required this.url,
    required this.icon,
    required this.onLaunchURL,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon and Title
              Center(
                child: Column(
                  children: [
                    Text(icon, style: const TextStyle(fontSize: 48)),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // Description
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Text(
                  description,
                  style: const TextStyle(fontSize: 16, height: 1.5),
                ),
              ),

              const SizedBox(height: 25),

              // Eligibility
              const Text(
                "Eligibility:",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.only(left: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("• Valid Government ID"),
                    Text("• Income criteria (if applicable)"),
                    Text("• Registered hospital"),
                    Text("• Age eligibility (varies by scheme)"),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Benefits
              const Text(
                "Key Benefits:",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.only(left: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("• Free or subsidized medical services"),
                    Text("• Coverage at network hospitals"),
                    Text("• Cashless treatment facility"),
                    Text("• Easy claim process"),
                  ],
                ),
              ),

              const SizedBox(height: 35),

              // Buttons
              ElevatedButton.icon(
                onPressed: () {
                  onLaunchURL(url);
                },
                icon: const Icon(Icons.open_in_browser),
                label: const Text("Visit Official Website"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),

              const SizedBox(height: 15),

              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Application feature coming soon"),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.app_registration),
                label: const Text("Apply Now"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
