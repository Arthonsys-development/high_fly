import 'package:flutter/material.dart';
import '../../../data/models/customer_model.dart';
import '../../../config/constant/app_colors.dart';
import '../../global/widgets/custom_text_field.dart';
import 'header_icon_widget.dart';
import 'customer_details_card.dart';
import 'action_buttons.dart';
import 'customer_selection_dialog.dart';

class CustomerSelectionSection extends StatefulWidget {
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
  State<CustomerSelectionSection> createState() => _CustomerSelectionSectionState();
}

class _CustomerSelectionSectionState extends State<CustomerSelectionSection> {
  Customer? _selectedCustomer;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 20, bottom: 20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          
          // Header with icon
          const HeaderIconWidget(
            icon: Icons.people_outline,
            title: 'Select Customer',
            subtitle: 'Choose a customer from our static database',
          ),
          
          const SizedBox(height: 40),
          
          // Customer selection field
          GestureDetector(
            onTap: _showCustomerSelectionDialog,
            child: CustomTextField(
              titleText: 'Customer',
              hintText: _selectedCustomer?.displayText ?? 'Select Customer',
              isMandatory: true,
              borderRadius: 6,
              enabled: false,
              suffixIcon: const Icon(
                Icons.keyboard_arrow_down,
                color: AppColors.lightGreyColor,
                size: 20,
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Customer details card
          CustomerDetailsCard(
            selectedCustomer: _selectedCustomer,
          ),
          
          const SizedBox(height: 40),
          
          // Action buttons
          ActionButtons(
            onPrevious: widget.onPrevious,
            onNext: _canProceed() ? () => widget.onNext?.call(_selectedCustomer) : null,
            isPreviousEnabled: widget.onPrevious != null,
            isNextEnabled: _canProceed(),
            nextButtonText: widget.nextButtonText,
          ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  bool _canProceed() {
    return _selectedCustomer != null;
  }

  void _showCustomerSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => CustomerSelectionDialog(
        customers: widget.customers,
        selectedCustomerId: _selectedCustomer?.id,
        onCustomerSelected: (customer) {
          setState(() {
            _selectedCustomer = customer;
          });
        },
      ),
    );
  }
}
