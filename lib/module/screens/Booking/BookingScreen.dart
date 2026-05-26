import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/constant/app_colors.dart';
import '../../../config/routes.dart';
import '../../utils/responsive.dart';
import '../../../data/models/project_model.dart' as local_model;
import '../../../data/models/response_model/project_response_model.dart';
import '../../../data/models/customer_model.dart';
import '../../../data/models/payment_model.dart';
import '../../../data/models/bank_details_model.dart';
import '../../../data/models/booking_summary_model.dart';
import '../../../data/models/hold_details_model.dart';
import '../../../data/providers/sample_data_provider.dart';
import '../../providers/projects_provider.dart';
import '../../providers/booking_navigation_provider.dart';
import '../../providers/hold_status_provider.dart';
import '../../providers/app_config_provider.dart';
import '../../widgets/booking/booking_form_section.dart';
import '../../widgets/booking/customer_selection_section.dart';
import '../../widgets/booking/hold_details_section.dart';
import '../../widgets/booking/payment_details_section.dart';
import '../../widgets/booking/bank_details_section.dart';
import '../../widgets/booking/upload_documents_section.dart' show UploadDocumentsSection, DocumentFileData;
import '../../widgets/booking/review_confirm_section.dart';

// Extension to convert API Project model to local Project model
extension ProjectConversion on Project {
  local_model.Project toLocalModel() {
    // Since the API model doesn't have plots, we'll create an empty list
    return local_model.Project(
      id: id.toString(),
      name: name,
      plots: [], // API doesn't provide plots directly, they might be fetched separately
      availablePlotCount: availablePlotCount ?? 0, // Pass the available plot count from API
      payName: payName,
    );
  }
}

class BookingProcessorScreen extends ConsumerStatefulWidget {
  const BookingProcessorScreen({super.key});

  @override
  ConsumerState<BookingProcessorScreen> createState() => _BookingProcessorScreenState();
}

class _BookingProcessorScreenState extends ConsumerState<BookingProcessorScreen>
    with SingleTickerProviderStateMixin {

  late TabController _tabController;
  final List<Customer> customers = SampleDataProvider.getSampleCustomers();
  int _currentStep = 0; // 0: Project & Plot, 1: Customer, 2: Payment, 3: Bank Details, 4: Upload Documents, 5: Review & Confirm
  int _currentHoldStep = 0; // 0: Project & Plot, 1: Customer, 2: Hold Details, 3: Bank Details, 4: Upload Documents, 5: Review & Confirm
  final ScrollController _scrollController = ScrollController();
  
  // Booking data to pass to review section
  local_model.Project? _selectedProject;
  List<local_model.Plot> _selectedPlots = [];
  Customer? _selectedCustomer;
  HoldDetails? _holdDetails;
  PaymentDetails? _paymentDetails;
  BankDetails? _bankDetails;
  List<String> _documents = [];
  List<DocumentFileData> _documentFiles = []; // Store file data for web uploads

  /// Refreshes projects and app config (hold limits, max plots, etc.).
  void _refreshScreenData() {
    ref.read(projectsControllerProvider.notifier).loadProjects();
    ref.read(projectsControllerProvider.notifier).loadActiveProjects();
    ref.read(appConfigControllerProvider.notifier).loadAppConfig();
  }

  // Method to reset all form data
  void _resetFormData() {
    setState(() {
      _selectedProject = null;
      _selectedPlots = [];
      _selectedCustomer = null;
      _holdDetails = null;
      _paymentDetails = null;
      _bankDetails = null;
      _documents = [];
      _documentFiles = [];
      _currentStep = 0;
      _currentHoldStep = 0;
      _hasHandledNavigation = false;
    });
    _refreshScreenData();
  }

  /// Computes total amount = Σ(effectivePrice × saleableSize) for all selected plots.
  String _computePlotsTotalAmount(List<local_model.Plot> plots) {
    double total = 0;
    for (final plot in plots) {
      final effectivePrice = plot.plcApplied && plot.plcPercentage != null
          ? plot.price * (1 + plot.plcPercentage! / 100)
          : plot.price;
      final size = plot.saleableSize ?? 0;
      total += effectivePrice * size;
    }
    if (total == 0) return '';
    return total % 1 == 0
        ? total.toStringAsFixed(0)
        : total.toStringAsFixed(2);
  }

  bool _hasHandledNavigation = false;

  Future<void> _onTabTapped(int index) async {
    if (index != 1) return;
    try {
      final holdStatus = await ref.read(holdStatusProvider.future);
      if (!mounted) return;
      if (holdStatus.isHoldOn) {
        _tabController.animateTo(0);
        _showHoldBlockedDialog(
          holdStatus.data.holdStartDate,
          holdStatus.data.holdOffDate,
        );
      }
    } catch (_) {
      // Allow hold if the status check fails
    }
  }

  String _formatHoldDate(String isoDate) {
    if (isoDate.isEmpty) return '';
    try {
      final dt = DateTime.parse(isoDate);
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return isoDate;
    }
  }

  void _showHoldBlockedDialog(String startDate, String endDate) {
    final formattedStart = _formatHoldDate(startDate);
    final formattedEnd = _formatHoldDate(endDate);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.block, color: Colors.red, size: 28),
            SizedBox(width: 10),
            Text('Hold Unavailable'),
          ],
        ),
        content: Text(
          'Holding plots has been temporarily disabled by the admin'
          '${formattedStart.isNotEmpty
              ? (formattedStart == formattedEnd
                  ? ' on $formattedStart'
                  : ' from $formattedStart${formattedEnd.isNotEmpty ? ' to $formattedEnd' : ''}')
              : ''}.'
          '\n\nPlease try again after the hold period ends.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Always refresh projects when the screen is opened
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshScreenData());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Handle navigation data only once when widget is first built
    if (!_hasHandledNavigation) {
      final navState = ref.read(bookingNavigationProvider);
      if (navState.shouldNavigate && navState.selectedProject != null && navState.tabIndex != null) {
        _hasHandledNavigation = true;
        
        // Convert API Project to local Project model and set state
        _selectedProject = navState.selectedProject!.toLocalModel();
        
        // Switch to the appropriate tab
        _tabController.index = navState.tabIndex!;
        
        // Clear navigation state after handling
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(bookingNavigationProvider.notifier).clearNavigation();
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  // Helper method to reset scroll position
  void _resetScrollPosition() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    });
  }

  // Returns true for desktop web UI, false for mobile UI (mobile browser or native app)
  bool _isDesktopWeb(BuildContext context) {
    return !Responsive.isMobile(context) && kIsWeb;
  }

  @override
  Widget build(BuildContext context) {
    final isDesktopWeb = _isDesktopWeb(context);
    if (isDesktopWeb) {
      // Web-specific layout with centered content and max width
      return Scaffold(
        body: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1200),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 30.0),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.1),
                        spreadRadius: 1,
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Booking Processor",
                        style: TextStyle(
                          fontSize: 28,
                          color: AppColors.headingTextColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Process bookings or holds using static data",
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.lightGreyColor,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 32),
                      TabBar(
                        controller: _tabController,
                        indicatorColor: AppColors.primaryColor,
                        labelColor: AppColors.primaryColor,
                        unselectedLabelColor: AppColors.headingTextColor,
                        indicatorSize: TabBarIndicatorSize.tab,
                        indicatorWeight: 3.0,
                        labelStyle: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                        unselectedLabelStyle: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                        onTap: _onTabTapped,
                        tabs: const [
                          Tab(text: "Book Now"),
                          Tab(text: "Hold for 24 Hours"),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.1),
                          spreadRadius: 1,
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(32.0),
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
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Mobile layout (original)
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22.0),
        child: Column(
          children: [
          //  const SizedBox(height: 30),

            Container(
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey, width: 0.5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Text(
                  //   "Booking Processor",
                  //   style: TextStyle(fontSize: 18, color: AppColors.headingTextColor, fontWeight: FontWeight.w500),
                  // ),
                  // const SizedBox(height: 5),
                  // const Text(
                  //   "Process bookings or holds using static data",
                  //   style: TextStyle(fontSize: 15, color: AppColors.lightGreyColor, fontWeight: FontWeight.w500),
                  // ),

                  // const SizedBox(height: 40),

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
                    onTap: _onTabTapped,
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
    Widget buildStepContent() {
      if (_currentStep == 0) {
        // Project & Plot Selection Step
        return Consumer(
          builder: (context, ref, child) {
            final projectsState = ref.watch(projectsControllerProvider);
            
            if (projectsState.isLoading && projectsState.projects.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (projectsState.error != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Error loading projects: ${projectsState.error}'),
                    ElevatedButton(
                      onPressed: () => ref.read(projectsControllerProvider.notifier).loadProjects(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }
            
            // Convert API Project models to local Project models
            // Filter to show only "Active" status projects
            final localProjects = projectsState.projects
                .where((project) => project.status.toLowerCase() == 'active')
                .map((project) => project.toLocalModel())
                .toList();
            
            return BookingFormSection(
              key: Key('booking_step_$_currentStep'),
              title: actionType,
              projects: localProjects,
              nextButtonText: "Next",
              initialProject: _selectedProject,
              initialPlots: _selectedPlots.isEmpty ? null : _selectedPlots,
              onRefreshProjects: () =>
                  ref.read(projectsControllerProvider.notifier).loadProjects(),
              isRefreshingProjects: projectsState.isLoading,
              onNext: (selectedProject, selectedPlots) {
                setState(() {
                  _selectedProject = selectedProject;
                  _selectedPlots = selectedPlots;
                  _currentStep = 1; // Move to customer selection
                });
                _resetScrollPosition();
              },
            );
          },
        );
      } else if (_currentStep == 1) {
        // Customer Selection Step
        return CustomerSelectionSection(
          key: Key('booking_step_$_currentStep'),
          title: actionType,
          customers: customers,
          nextButtonText: "Next",
          initialCustomer: _selectedCustomer,
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
            _resetScrollPosition();
          },
        );
      } else if (_currentStep == 2) {
        // Payment Details Step
        final isMultiPlot = _selectedPlots.length > 1;
        final singlePlot = _selectedPlots.isNotEmpty ? _selectedPlots.first : null;
        final precomputedTotal = _selectedPlots.isNotEmpty
            ? local_model.Plot.formatCombinedTotalAmount(_selectedPlots)
            : null;
        return PaymentDetailsSection(
          key: Key('booking_step_$_currentStep'),
          title: actionType,
          paymentAmount: isMultiPlot
              ? _computePlotsTotalAmount(_selectedPlots)
              : (singlePlot?.price.toString() ?? ''),
          nextButtonText: "Next",
          initialPaymentDetails: _paymentDetails,
          saleableSize: isMultiPlot ? null : singlePlot?.saleableSize,
          plcApplied: isMultiPlot ? false : (singlePlot?.plcApplied ?? false),
          plcPercentage: isMultiPlot ? null : singlePlot?.plcPercentage,
          pricePerSqYd: isMultiPlot ? null : singlePlot?.price.toString(),
          precomputedTotalAmount: precomputedTotal,
          expectedPayName: _selectedProject?.payName,
          onPrevious: () {
            setState(() {
              _currentStep = 1; // Go back to customer selection
            });
          },
          onNext: (paymentDetails) {
            setState(() {
              _paymentDetails = paymentDetails;
              _currentStep = 5; // Move to review & confirm
            });
            _resetScrollPosition();
          },
        );
      } else if (_currentStep == 3) {
        // Bank Details Step
        return BankDetailsSection(
          key: Key('booking_step_$_currentStep'),
          title: actionType,
          nextButtonText: "Next",
          initialBankDetails: _bankDetails,
          onPrevious: () {
            setState(() {
              _currentStep = 2; // Go back to payment details
            });
          },
          onNext: (bankDetails) {
            setState(() {
              _bankDetails = bankDetails;
              _currentStep = 4; // Move to upload documents
            });
            _resetScrollPosition();
          },
        );
      } else if (_currentStep == 4) {
        // Upload Documents Step
        return UploadDocumentsSection(
          key: Key('booking_step_$_currentStep'),
          title: actionType,
          nextButtonText: "Next",
          initialDocuments: _documents.isEmpty ? null : _documents,
          onPrevious: () {
            setState(() {
              _currentStep = 3; // Go back to bank details
            });
          },
          onNext: (documents) {
            setState(() {
              _documents = documents;
              _currentStep = 5; // Move to review & confirm
            });
            _resetScrollPosition();
          },
          onNextWithData: kIsWeb ? (documentFiles) {
            setState(() {
              _documentFiles = documentFiles;
              _documents = documentFiles.map((f) => f.path).toList();
              _currentStep = 5; // Move to review & confirm
            });
            _resetScrollPosition();
          } : null,
        );
      } else if (_currentStep == 5) {
        // Review & Confirm Step
        return Consumer(
          builder: (context, ref, child) {
           // final userState = ref.watch(userControllerProvider);
           // final agentId = userState.user?.id ?? '1'; // Default to '1' if no user data
           // String agentId = await _secureStorage.read(key: SharedPreferenceStrings.id) ?? '';

            return ReviewConfirmSection(
              key: Key('booking_step_$_currentStep'),
              title: "Review & Confirm",
              nextButtonText: actionType,
              onPrevious: () {
                setState(() {
                  _currentStep = 2; // Go back to payment details
                });
              },
              onNext: () {
                // This will be handled by the ReviewConfirmSection itself
              },
              bookingSummary: BookingSummary(
                selectedProject: _selectedProject,
                selectedPlots: _selectedPlots.isEmpty ? null : _selectedPlots,
                selectedCustomer: _selectedCustomer,
                paymentDetails: _paymentDetails,
                bankDetails: _bankDetails,
                documents: _documents.isEmpty ? null : _documents,
              ),
              documentFiles: kIsWeb ? _documentFiles : null,
              isHoldFlow: false,
              onResetForm: _resetFormData,
              onSuccess: () {
                _refreshScreenData();
                setState(() {
                  _currentStep = 6;
                });
                _resetScrollPosition();
              },
            );
          },
        );
      } else {
        // Success Step
        return _buildSuccessStep(isHoldFlow: false);
      }
    }

    // Wrap content for desktop web with better styling
    final isDesktopWeb = _isDesktopWeb(context);
    if (isDesktopWeb) {
      return SingleChildScrollView(
        controller: _scrollController,
        key: PageStorageKey('booking_step_$_currentStep'),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: buildStepContent(),
          ),
        ),
      );
    }

    // For mobile, use a key to force recreation when step changes
    return buildStepContent();
  }


  Widget _buildHoldStep(String actionType) {
    Widget buildStepContent() {
      if (_currentHoldStep == 0) {
        // Project & Plot Selection Step
        return Consumer(
          builder: (context, ref, child) {
            final projectsState = ref.watch(projectsControllerProvider);
            
            if (projectsState.isLoading && projectsState.projects.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (projectsState.error != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Error loading projects: ${projectsState.error}'),
                    ElevatedButton(
                      onPressed: () => ref.read(projectsControllerProvider.notifier).loadProjects(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }
            
            // Convert API Project models to local Project models
            // Filter to show only "Active" status projects
            final localProjects = projectsState.projects
                .where((project) => project.status.toLowerCase() == 'active')
                .map((project) => project.toLocalModel())
                .toList();
            
            return BookingFormSection(
              key: Key('hold_step_$_currentHoldStep'),
              title: actionType,
              projects: localProjects,
              nextButtonText: "Next",
              isHoldFlow: true,
              initialProject: _selectedProject,
              initialPlots: _selectedPlots.isEmpty ? null : _selectedPlots,
              onRefreshProjects: () =>
                  ref.read(projectsControllerProvider.notifier).loadProjects(),
              isRefreshingProjects: projectsState.isLoading,
              onNext: (selectedProject, selectedPlots) {
                setState(() {
                  _selectedProject = selectedProject;
                  _selectedPlots = selectedPlots;
                  _currentHoldStep = 1; // Move to customer selection
                });
                _resetScrollPosition();
              },
            );
          },
        );
      } else if (_currentHoldStep == 1) {
        // Customer Selection Step
        return CustomerSelectionSection(
          key: Key('hold_step_$_currentHoldStep'),
          title: actionType,
          customers: customers,
          nextButtonText: "Next",
          initialCustomer: _selectedCustomer,
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
            _resetScrollPosition();
          },
        );
      } else if (_currentHoldStep == 2) {
        // Hold Details Step
        return HoldDetailsSection(
          key: Key('hold_step_$_currentHoldStep'),
          title: actionType,
          nextButtonText: "Next",
          initialHoldDetails: _holdDetails,
          onPrevious: () {
            setState(() {
              _currentHoldStep = 1; // Go back to customer selection
            });
          },
          onNext: (holdDetails) {
            setState(() {
              _holdDetails = holdDetails;
              // _currentHoldStep = 3; // Move to payment details
              _currentHoldStep = 5; // Move to review & confirm
            });
            _resetScrollPosition();
          },
        );
      }  else if (_currentHoldStep == 3) {
        // Bank Details Step
        return BankDetailsSection(
          key: Key('hold_step_$_currentHoldStep'),
          title: "Bank Details",
          nextButtonText: "Next",
          initialBankDetails: _bankDetails,
          onPrevious: () {
            setState(() {
              _currentHoldStep = 2; // Go back to hold details
            });
          },
          onNext: (bankDetails) {
            setState(() {
              _bankDetails = bankDetails;
              _currentHoldStep = 4; // Move to upload documents
            });
            _resetScrollPosition();
          },
        );
      } else if (_currentHoldStep == 4) {
        // Upload Documents Step
        return UploadDocumentsSection(
          key: Key('hold_step_$_currentHoldStep'),
          title: actionType,
          nextButtonText: "Next",
          initialDocuments: _documents.isEmpty ? null : _documents,
          onPrevious: () {
            setState(() {
              _currentHoldStep = 3; // Go back to bank details
            });
          },
          onNext: (documents) {
            setState(() {
              _documents = documents;
              _currentHoldStep = 5; // Move to review & confirm
            });
            _resetScrollPosition();
          },
          onNextWithData: kIsWeb ? (documentFiles) {
            setState(() {
              _documentFiles = documentFiles;
              _documents = documentFiles.map((f) => f.path).toList();
              _currentHoldStep = 5; // Move to review & confirm
            });
            _resetScrollPosition();
          } : null,
        );
      } else if (_currentHoldStep == 5) {
        // Review & Confirm Step
        return Consumer(
          builder: (context, ref, child) {
           // final userState = ref.watch(userControllerProvider);
           // final agentId = userState.user?.id ?? '1'; // Default to '1' if no user data
            
            return ReviewConfirmSection(
              key: Key('hold_step_$_currentHoldStep'),
              title: "Review & Confirm",
              nextButtonText: "Hold",
              onPrevious: () {
                setState(() {
                  _currentHoldStep = 2; // Go back to hold details
                });
              },
              onNext: () {
                // This will be handled by the ReviewConfirmSection itself
              },
              bookingSummary: BookingSummary(
                selectedProject: _selectedProject,
                selectedPlots: _selectedPlots.isEmpty ? null : _selectedPlots,
                selectedCustomer: _selectedCustomer,
                holdDetails: _holdDetails,
                bankDetails: _bankDetails,
                documents: _documents.isEmpty ? null : _documents,
              ),
              documentFiles: kIsWeb ? _documentFiles : null,
              isHoldFlow: true,
              onResetForm: _resetFormData,
              onSuccess: () {
                _refreshScreenData();
                setState(() {
                  _currentHoldStep = 6;
                });
                _resetScrollPosition();
              },
            );
          },
        );
      } else {
        // Success Step
        return _buildSuccessStep(isHoldFlow: true);
      }
    }

    // Wrap content for desktop web with better styling
    final isDesktopWeb = _isDesktopWeb(context);
    if (isDesktopWeb) {
      return SingleChildScrollView(
        controller: _scrollController,
        key: PageStorageKey('hold_step_$_currentHoldStep'),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: buildStepContent(),
          ),
        ),
      );
    }

    // For mobile, use a key to force recreation when step changes
    return buildStepContent();
  }

  Widget _buildSuccessStep({required bool isHoldFlow}) {
    final projectName = _selectedProject?.name ?? 'N/A';
    final plotName = _selectedPlots.isEmpty
        ? 'N/A'
        : _selectedPlots.length == 1
            ? _selectedPlots.first.plotNumber
            : _selectedPlots.map((p) => p.plotNumber).join(', ');
    final customerName = _selectedCustomer?.name ?? 'N/A';

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_rounded,
                color: Colors.green.shade600,
                size: 64,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isHoldFlow ? 'Plot Held Successfully!' : 'Booking Confirmed!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.headingTextColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              isHoldFlow
                  ? 'Your plot has been held for 24 hours. Complete the booking before the hold expires.'
                  : 'Your booking has been submitted successfully. Our team will get in touch with you shortly.',
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.lightGreyColor,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 420),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isHoldFlow ? 'Hold Summary' : 'Booking Summary',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.headingTextColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _summaryRow('Project', projectName),
                  const SizedBox(height: 10),
                  _summaryRow('Plot', plotName),
                  const SizedBox(height: 10),
                  _summaryRow('Customer', customerName),
                  if (!isHoldFlow && _paymentDetails != null) ...[
                    const SizedBox(height: 10),
                    _summaryRow('Payment Mode', _paymentDetails!.paymentMethod),
                  ],
                  if (isHoldFlow && _holdDetails != null) ...[
                    const SizedBox(height: 10),
                    _summaryRow('Hold Expires In', '24 Hours'),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 32),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                children: [
                  // SizedBox(
                  //   width: double.infinity,
                  //   child: ElevatedButton(
                  //     onPressed: () => context.go(Routes.dashboardScreen),
                  //     style: ElevatedButton.styleFrom(
                  //       backgroundColor: AppColors.primaryColor,
                  //       foregroundColor: Colors.white,
                  //       padding: const EdgeInsets.symmetric(vertical: 16),
                  //       shape: RoundedRectangleBorder(
                  //         borderRadius: BorderRadius.circular(10),
                  //       ),
                  //       elevation: 0,
                  //     ),
                  //     child: const Text(
                  //       'Go to Dashboard',
                  //       style: TextStyle(
                  //         fontSize: 16,
                  //         fontWeight: FontWeight.w600,
                  //       ),
                  //     ),
                  //   ),
                  // ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _resetFormData,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryColor,
                        side: BorderSide(color: AppColors.primaryColor),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        isHoldFlow ? 'Go Back' : 'Go Back',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.lightGreyColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.headingTextColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

}