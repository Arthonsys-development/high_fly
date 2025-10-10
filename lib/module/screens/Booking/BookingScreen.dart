import 'package:flutter/material.dart';

import '../../../config/constant/app_colors.dart';
import '../../../data/models/project_model.dart';
import '../../../data/models/customer_model.dart';
import '../../../data/models/payment_model.dart';
import '../../../data/models/bank_details_model.dart';
import '../../../data/models/booking_summary_model.dart';
import '../../../data/models/hold_details_model.dart';
import '../../../data/providers/sample_data_provider.dart';
import '../../widgets/booking/booking_form_section.dart';
import '../../widgets/booking/customer_selection_section.dart';
import '../../widgets/booking/hold_details_section.dart';
import '../../widgets/booking/payment_details_section.dart';
import '../../widgets/booking/bank_details_section.dart';
import '../../widgets/booking/review_confirm_section.dart';

class BookingProcessorScreen extends StatefulWidget {
  const BookingProcessorScreen({super.key});

  @override
  State<BookingProcessorScreen> createState() => _BookingProcessorScreenState();
}

class _BookingProcessorScreenState extends State<BookingProcessorScreen>
    with SingleTickerProviderStateMixin {

  late TabController _tabController;
  final List<Project> projects = SampleDataProvider.getSampleProjects();
  final List<Customer> customers = SampleDataProvider.getSampleCustomers();
  int _currentStep = 0; // 0: Project & Plot, 1: Customer, 2: Payment, 3: Bank Details, 4: Review & Confirm
  int _currentHoldStep = 0; // 0: Project & Plot, 1: Customer, 2: Hold Details, 4: Bank Details, 5: Review & Confirm
  String _selectedPlotPrice = '85000'; // Default price, will be updated from plot selection
  
  // Booking data to pass to review section
  Project? _selectedProject;
  Plot? _selectedPlot;
  Customer? _selectedCustomer;
  HoldDetails? _holdDetails;
  PaymentDetails? _paymentDetails;
  BankDetails? _bankDetails;

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

  void _handleBookingAction(String action) {
    // Show confirmation dialog or navigate to next screen
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(action),
        content: const Text('This action will be processed. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Handle the actual booking/hold logic here
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$action completed successfully!')),
              );
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Booking Processor",
                    style: TextStyle(fontSize: 18, color: AppColors.headingTextColor, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    "Process bookings or holds using static data",
                    style: TextStyle(fontSize: 15, color: AppColors.lightGreyColor, fontWeight: FontWeight.w500),
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
                  _buildCurrentStep("Book Now"),

                  // ----------------------------
                  // ⚪ Hold for 24 Hours Tab
                  // ----------------------------
                  _buildHoldStep("Hold for 24 Hours"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStep(String actionType) {
    if (_currentStep == 0) {
      // Project & Plot Selection Step
      return BookingFormSection(
        title: actionType,
        projects: projects,
        nextButtonText: "Next",
        onNext: (selectedProject, selectedPlot) {
          setState(() {
            _selectedProject = selectedProject;
            _selectedPlot = selectedPlot;
            _selectedPlotPrice = selectedPlot?.price.toString() ?? '85000';
            _currentStep = 1; // Move to customer selection
          });
        },
      );
    } else if (_currentStep == 1) {
      // Customer Selection Step
      return CustomerSelectionSection(
        title: actionType,
        customers: customers,
        nextButtonText: "Next",
        onPrevious: () {
          setState(() {
            _currentStep = 0; // Go back to project & plot selection
          });
        },
        onNext: (selectedCustomer) {
          setState(() {
            _selectedCustomer = selectedCustomer;
            _currentStep = 2; // Move to payment details
          });
        },
      );
    } else if (_currentStep == 2) {
      // Payment Details Step
      return PaymentDetailsSection(
        title: actionType,
        paymentAmount: _selectedPlotPrice,
        nextButtonText: "Next",
        onPrevious: () {
          setState(() {
            _currentStep = 1; // Go back to customer selection
          });
        },
        onNext: (paymentDetails) {
          setState(() {
            _paymentDetails = paymentDetails;
            _currentStep = 3; // Move to bank details
          });
        },
      );
    } else if (_currentStep == 3) {
      // Bank Details Step
      return BankDetailsSection(
        title: actionType,
        nextButtonText: "Next",
        onPrevious: () {
          setState(() {
            _currentStep = 2; // Go back to payment details
          });
        },
        onNext: (bankDetails) {
          setState(() {
            _bankDetails = bankDetails;
            _currentStep = 4; // Move to review & confirm
          });
        },
      );
    } else {
      // Review & Confirm Step
      return ReviewConfirmSection(
        title: "Review & Confirm",
        nextButtonText: actionType,
        onPrevious: () {
          setState(() {
            _currentStep = 3; // Go back to bank details
          });
        },
        onNext: () {
          _handleBookingAction(actionType);
        },
        bookingSummary: BookingSummary(
          selectedProject: _selectedProject,
          selectedPlot: _selectedPlot,
          selectedCustomer: _selectedCustomer,
          paymentDetails: _paymentDetails,
          bankDetails: _bankDetails,
        ),
      );
    }
  }


  Widget _buildHoldStep(String actionType) {
    if (_currentHoldStep == 0) {
      // Project & Plot Selection Step
      return BookingFormSection(
        title: actionType,
        projects: projects,
        nextButtonText: "Next",
        onNext: (selectedProject, selectedPlot) {
          setState(() {
            _selectedProject = selectedProject;
            _selectedPlot = selectedPlot;
            _selectedPlotPrice = selectedPlot?.price.toString() ?? '85000';
            _currentHoldStep = 1; // Move to customer selection
          });
        },
      );
    } else if (_currentHoldStep == 1) {
      // Customer Selection Step
      return CustomerSelectionSection(
        title: actionType,
        customers: customers,
        nextButtonText: "Next",
        onPrevious: () {
          setState(() {
            _currentHoldStep = 0; // Go back to project & plot selection
          });
        },
        onNext: (selectedCustomer) {
          setState(() {
            _selectedCustomer = selectedCustomer;
            _currentHoldStep = 2; // Move to hold details
          });
        },
      );
    } else if (_currentHoldStep == 2) {
      // Hold Details Step
      return HoldDetailsSection(
        title: actionType,
        nextButtonText: "Next",
        onPrevious: () {
          setState(() {
            _currentHoldStep = 1; // Go back to customer selection
          });
        },
        onNext: (holdDetails) {
          setState(() {
            _holdDetails = holdDetails;
            _currentHoldStep = 3; // Move to payment details
          });
        },
      );
    }  else if (_currentHoldStep == 3) {
      // Bank Details Step
      return BankDetailsSection(
        title: "Bank Details",
        nextButtonText: "Next",
        onPrevious: () {
          setState(() {
            _currentHoldStep = 2; // Go back to payment details
          });
        },
        onNext: (bankDetails) {
          setState(() {
            _bankDetails = bankDetails;
            _currentHoldStep = 4; // Move to review & confirm
          });
        },
      );
    } else {
      // Review & Confirm Step
      return ReviewConfirmSection(
        title: "Review & Confirm",
        nextButtonText: actionType,
        onPrevious: () {
          setState(() {
            _currentHoldStep = 3; // Go back to bank details
          });
        },
        onNext: () {
          _handleBookingAction(actionType);
        },
        bookingSummary: BookingSummary(
          selectedProject: _selectedProject,
          selectedPlot: _selectedPlot,
          selectedCustomer: _selectedCustomer,
          holdDetails: _holdDetails,
         // paymentDetails: _paymentDetails,
          bankDetails: _bankDetails,
        ),
      );
    }
  }

}
