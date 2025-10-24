import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  const CustomerSelectionSection({
    super.key,
    required this.title,
    required this.customers,
    this.onPrevious,
    this.onNext,
    this.nextButtonText,
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
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 20, bottom: 20),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            const SizedBox(height: 20),
            
            // Header with icon
            HeaderIconWidget(
              icon: IconsAssets.personsIcon,
              title: 'Add Customer',
              subtitle: 'Enter customer details to create a new customer',
            ),
            
            const SizedBox(height: 40),
            
            // Customer name field
            CustomTextField(
              titleText: 'Customer Name',
              controller: _nameController,
              hintText: 'Enter customer name',
              isMandatory: true,
              borderRadius: 6,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter customer name';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 20),
            
            // Customer phone field
            CustomTextField(
              titleText: 'Phone Number',
              controller: _phoneController,
              hintText: 'Enter phone number',
              isMandatory: true,
              borderRadius: 6,
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter phone number';
                }
                if (value.trim().length < 10) {
                  return 'Please enter a valid phone number';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 32),
            
            // Customer details card (show created customer info)
            if (_selectedCustomer != null)
              CustomerDetailsCard(
                selectedCustomer: _selectedCustomer,
              ),
            
            const SizedBox(height: 40),
            
            // Action buttons
            ActionButtons(
              onPrevious: widget.onPrevious,
              onNext: _canProceed() ? _handleCreateCustomer : null,
              isPreviousEnabled: widget.onPrevious != null,
              isNextEnabled: _canProceed(),
              nextButtonText: _isLoading ? 'Creating...' : widget.nextButtonText,
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  bool _canProceed() {
    return _nameController.text.trim().isNotEmpty && 
           _phoneController.text.trim().isNotEmpty &&
           !_isLoading;
  }

  Future<void> _handleCreateCustomer() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final customerRepository = ref.read(customerApiRepositoryProvider);
      final result = await customerRepository.createCustomer(
        _nameController.text.trim(),
        _phoneController.text.trim(),
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
