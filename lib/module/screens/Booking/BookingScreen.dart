import 'package:flutter/material.dart';
import 'package:highfly/config/constant/const_assets.dart';

import '../../../config/constant/app_colors.dart';

class BookingProcessorScreen extends StatefulWidget {
  const BookingProcessorScreen({super.key});

  @override
  State<BookingProcessorScreen> createState() => _BookingProcessorScreenState();
}

class _BookingProcessorScreenState extends State<BookingProcessorScreen>
    with SingleTickerProviderStateMixin {

  late TabController _tabController;
  String selectedProject = '';

  final List<String> projects = [
    'Project Alpha',
    'Project Beta',
    'Project Gamma',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      /*appBar: PreferredSize(
        preferredSize: const Size.fromHeight(10),
        child: AppBar(
          title: const Text(
            'HighFly - Booking',
            style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black),
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
          // bottom: PreferredSize(
          //   preferredSize: const Size.fromHeight(90),
          //   child: Container(
          //     decoration: const BoxDecoration(
          //       border: Border(
          //         bottom: BorderSide(color: Colors.grey, width: 0.5),
          //       ),
          //     ),
          //     child: Column( crossAxisAlignment: CrossAxisAlignment.start,
          //       children: [
          //         const Text(
          //           "Booking Processor",
          //           style: TextStyle(fontSize: 18,  color: Colors.black54, fontWeight: FontWeight.w600),
          //         ),
          //         const SizedBox(height: 4),
          //         const Text(
          //           "Process bookings or holds using static data",
          //           style: TextStyle(color: Colors.black54),
          //         ),
          //
          //         const SizedBox(height: 40),
          //
          //         TabBar(
          //           controller: _tabController,
          //           indicatorColor: Colors.orange,
          //           labelColor: Colors.orange,
          //           unselectedLabelColor: Colors.black54,
          //           indicatorSize: TabBarIndicatorSize.tab,
          //           indicatorWeight: 2.5,
          //           labelStyle: const TextStyle(
          //             fontWeight: FontWeight.w600,
          //           ),
          //           tabs: const [
          //             Tab(text: "Book Now"),
          //             Tab(text: "Hold for 24 Hours"),
          //           ],
          //         ),
          //       ],
          //     ),
          //   ),
          // ),
        ),
      ),*/
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22.0),
        child: Column(
          children: [

            const SizedBox(height: 30),

            Container(
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey, width: 0.5),
                ),
              ),
              child: Column( crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Booking Processor",
                    style: TextStyle(fontSize: 18, color: AppColors.headingTextColor, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    "Process bookings or holds using static data",
                    style: TextStyle(fontSize: 16, color: AppColors.darkGreyColor, fontWeight: FontWeight.w500),
                  ),

                  const SizedBox(height: 40),

                  TabBar(
                    controller: _tabController,
                    indicatorColor: AppColors.primaryColor,
                    labelColor: AppColors.primaryColor,
                    unselectedLabelColor: AppColors.headingTextColor,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicatorWeight: 2.5,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 16
                    ),
                    tabs: const [
                      Tab(text: "Book Now"),
                      Tab(text: "Hold for 24 Hours"),
                    ],
                  ),
                ],
              ),
            ),


            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // ----------------------------
                  // 🟠 Book Now Tab
                  // ----------------------------
                  _BookingFormSection(
                    title: "Book Now", 
                    items: projects, 
                    selectedProject: selectedProject,
                    onProjectChanged: (value) {
                      setState(() {
                        selectedProject = value ?? '';
                      });
                    },
                  ),

                  // ----------------------------
                  // ⚪ Hold for 24 Hours Tab
                  // ----------------------------
                  _BookingFormSection(
                    title: "Hold for 24 Hours", 
                    items: projects, 
                    selectedProject: selectedProject,
                    onProjectChanged: (value) {
                      setState(() {
                        selectedProject = value ?? '';
                      });
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookingFormSection extends StatelessWidget {
  final String title;
  final List<String> items;
  final String selectedProject;
  final Function(String?) onProjectChanged;

  const _BookingFormSection({
    required this.title, 
    required this.items, 
    required this.selectedProject,
    required this.onProjectChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(0.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          const SizedBox(height: 40),

          // Icon and heading
          Center(
            child: Column(
              children: [
                SizedBox(
                    height: 70,
                    width: 70,
                    child: Image.asset(ImageAssets.selectProject)),
                SizedBox(height: 10),
                Text(
                  "Select Project & Plot",
                  style: TextStyle(
                      fontSize: 18, color: AppColors.textColor, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 7),
                Text(
                  "Choose a project, then select a plot",
                  style: TextStyle(fontSize: 16, color: AppColors.darkGreyColor, fontWeight: FontWeight.w400),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Dropdown
          Row(
            children: [
              const Text("Project",
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: AppColors.textColor)),
              const Text(" *",
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: AppColors.primaryColor)),
            ],
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: selectedProject.isEmpty ? null : selectedProject,
            items: items
                .map((p) => DropdownMenuItem(
              value: p,
              child: Text(p),
            ))
                .toList(),
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderSide: const BorderSide(color: AppColors.primaryColor),
                borderRadius: BorderRadius.circular(6),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            icon: Icon(Icons.keyboard_arrow_down_outlined, color: AppColors.lightGreyColor),
            onChanged: onProjectChanged,
            hint: const Text("Select a project", style: TextStyle(color: AppColors.lightGreyColor, fontSize: 15, fontWeight: FontWeight.w400)),
          ),

          const Spacer(),

          // Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {

                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey,
                    side: const BorderSide(color: Colors.grey),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text("Previous"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  // onPressed: selectedProject == null ? null : () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    disabledBackgroundColor: Colors.orange.withOpacity(0.5),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () { },
                  child: const Text("Next →"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}