import 'package:flutter/material.dart';
import '../../../config/constant/app_colors.dart';

class PaymentMethodSelectionDialog extends StatefulWidget {
  final String title;
  final Map<String, String> options;
  final String? selectedKey;
  final Function(String key, String value) onSelected;

  const PaymentMethodSelectionDialog({
    super.key,
    required this.title,
    required this.options,
    this.selectedKey,
    required this.onSelected,
  });

  @override
  State<PaymentMethodSelectionDialog> createState() =>
      _PaymentMethodSelectionDialogState();
}

class _PaymentMethodSelectionDialogState
    extends State<PaymentMethodSelectionDialog> {
  final TextEditingController _searchController = TextEditingController();
  late Map<String, String> _filteredOptions;

  @override
  void initState() {
    super.initState();
    _filteredOptions = widget.options;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredOptions = widget.options;
      } else {
        _filteredOptions = Map.fromEntries(
          widget.options.entries.where(
            (e) => e.value.toLowerCase().contains(query),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final showSearch = widget.options.length > 5;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title row
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.lightGreyBorderColor,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.headingTextColor,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close,
                      color: AppColors.lightGreyColor,
                    ),
                  ),
                ],
              ),
            ),

            // Search field (only when options > 5)
            if (showSearch)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  style: const TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                    hintText: 'Search...',
                    hintStyle: TextStyle(
                      color: AppColors.lightGreyColor,
                      fontSize: 14,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColors.lightGreyColor,
                      size: 20,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.clear,
                              color: AppColors.lightGreyColor,
                              size: 18,
                            ),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    filled: true,
                    fillColor: AppColors.textFieldBGColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: AppColors.dropDownBorderColor,
                        width: 1,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: AppColors.dropDownBorderColor,
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: AppColors.primaryColor,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 12),

            // Options list
            Flexible(
              child: _filteredOptions.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      child: Text(
                        'No results found',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.lightGreyColor,
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: _filteredOptions.length,
                      itemBuilder: (context, index) {
                        final entry =
                            _filteredOptions.entries.elementAt(index);
                        final key = entry.key;
                        final value = entry.value;
                        final isSelected = key == widget.selectedKey;

                        return Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primaryColor.withValues(alpha: 0.1)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primaryColor
                                  : AppColors.lightGreyBorderColor,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: ListTile(
                            title: Text(
                              value,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: isSelected
                                    ? AppColors.primaryColor
                                    : AppColors.headingTextColor,
                              ),
                            ),
                            trailing: isSelected
                                ? const Icon(
                                    Icons.check_circle,
                                    color: AppColors.primaryColor,
                                  )
                                : null,
                            onTap: () {
                              widget.onSelected(key, value);
                              Navigator.of(context).pop();
                            },
                          ),
                        );
                      },
                    ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
