import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../../../config/constant/const_assets.dart';
import '../../../data/models/customer_model.dart';
import '../../../data/repository/customer_api_repository_provider.dart';
import '../../global/widgets/custom_text_field.dart';
import 'header_icon_widget.dart';
import 'customer_details_card.dart';
import 'action_buttons.dart';

class CustomerSelectionSection extends ConsumerStatefulWidget {
  final String title;
  final List<Customer> customers;
  final VoidCallback? onPrevious;
  final Function(Customer?)? onNext;
  final String? nextButtonText;
  final Customer? initialCustomer;

  const CustomerSelectionSection({
    super.key,
    required this.title,
    required this.customers,
    this.onPrevious,
    this.onNext,
    this.nextButtonText,
    this.initialCustomer,
  });

  @override
  ConsumerState<CustomerSelectionSection> createState() => _CustomerSelectionSectionState();
}

class _CustomerSelectionSectionState extends ConsumerState<CustomerSelectionSection> {
  Customer? _selectedCustomer;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize with provided customer if available
    if (widget.initialCustomer != null) {
      _selectedCustomer = widget.initialCustomer;
      _nameController.text = widget.initialCustomer!.name;
      _phoneController.text = widget.initialCustomer!.phone;
    }
    // Add listeners to trigger rebuild when text changes
    _nameController.addListener(_onTextChanged);
    _phoneController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _nameController.removeListener(_onTextChanged);
    _phoneController.removeListener(_onTextChanged);
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      // This will trigger a rebuild and update the button state
    });
  }

  @override
  Widget build(BuildContext context) {
    final spacing = kIsWeb ? 28.0 : 20.0;
    final largeSpacing = kIsWeb ? 48.0 : 40.0;
    
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        top: kIsWeb ? 24 : 20,
        bottom: kIsWeb ? 24 : 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            SizedBox(height: kIsWeb ? 24 : 20),
            
            // Header with icon
            HeaderIconWidget(
              icon: IconsAssets.personsIcon,
              title: 'Add Customer',
              subtitle: 'Enter customer details to create a new customer',
            ),
            
            SizedBox(height: largeSpacing),
            
            // Customer name field
            CustomTextField(
              titleText: 'Customer Name',
              controller: _nameController,
              hintText: 'Enter customer name',
              isMandatory: true,
              borderRadius: 6,
              maxLength: 30,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter customer name';
                }
                return null;
              },
            ),
            
            SizedBox(height: spacing),
            
            // Customer phone field
            CustomTextField(
              titleText: 'Phone Number',
              controller: _phoneController,
              hintText: 'Enter phone number',
              isMandatory: false,
              borderRadius: 6,
              maxLength: 10,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                // Field is optional, but if provided, validate length
                if (value != null && value.trim().isNotEmpty && value.trim().length < 10) {
                  return 'Please enter a valid phone number';
                }
                return null;
              },
            ),
            
            SizedBox(height: kIsWeb ? 36 : 32),
            
            // Customer details card (show created customer info)
            if (_selectedCustomer != null)
              CustomerDetailsCard(
                selectedCustomer: _selectedCustomer,
              ),
            
            SizedBox(height: largeSpacing),
            
            // Action buttons
            ActionButtons(
              onPrevious: widget.onPrevious,
              onNext: _canProceed() ? _handleCreateCustomer : null,
              isPreviousEnabled: widget.onPrevious != null,
              isNextEnabled: _canProceed(),
              nextButtonText: _isLoading ? 'Creating...' : widget.nextButtonText,
            ),
            
            SizedBox(height: kIsWeb ? 24 : 20),
          ],
        ),
      ),
    );
  }

  bool _canProceed() {
    // Customer Name is mandatory
    return _nameController.text.trim().isNotEmpty && !_isLoading;
  }

  Future<void> _handleCreateCustomer() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Customer Name is mandatory, so it should not be empty
      // Use default value for Phone Number if empty
      final customerName = _nameController.text.trim();
      final phoneNumber = _phoneController.text.trim().isEmpty 
          ? '0000000000' 
          : _phoneController.text.trim();
      
      final customerRepository = ref.read(customerApiRepositoryProvider);
      final result = await customerRepository.createCustomer(
        customerName,
        phoneNumber,
      );

      if (result['success'] == true && result['data'] != null) {
        final createdCustomer = result['data'] as Customer;
        
        setState(() {
          _selectedCustomer = createdCustomer;
        });

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Customer created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }

        // Call the onNext callback with the created customer
        widget.onNext?.call(createdCustomer);
      } else {
        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to create customer'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
