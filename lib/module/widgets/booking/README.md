# Booking Components Architecture

This directory contains the booking form components following clean architecture principles with proper separation of concerns.

## Architecture Overview

### Data Layer
- **`project_model.dart`**: Contains `Project` and `Plot` data models with JSON serialization
- **`sample_data_provider.dart`**: Provides sample data for testing and development

### Presentation Layer
- **`booking_form_section.dart`**: Main widget that orchestrates the entire booking form
- **`header_icon_widget.dart`**: Reusable header component with icon, title, and subtitle
- **`custom_form_field.dart`**: Reusable form field component with validation and styling
- **`plot_details_card.dart`**: Displays selected plot information in a structured card
- **`action_buttons.dart`**: Reusable action buttons (Previous/Next) with proper state management
- **`project_selection_dialog.dart`**: Modal dialog for project selection
- **`plot_selection_dialog.dart`**: Modal dialog for plot selection

## Component Features

### BookingFormSection
- **State Management**: Uses StatefulWidget for local state management
- **Validation**: Ensures both project and plot are selected before enabling Next button
- **Responsive**: Adapts to different screen sizes with proper scrolling
- **Accessibility**: Proper semantic labels and keyboard navigation

### Custom Components
- **HeaderIconWidget**: Displays circular icon with title and subtitle
- **CustomFormField**: Form field with required field indicators and dropdown support
- **PlotDetailsCard**: Two-column layout for plot information display
- **ActionButtons**: Previous/Next buttons with proper enabled/disabled states
- **ProjectSelectionDialog**: Searchable modal dialog for project selection
- **PlotSelectionDialog**: Searchable modal dialog for plot selection

## Usage Example

```dart
BookingFormSection(
  title: "Book Now",
  projects: sampleProjects,
  nextButtonText: "Book Now",
  onNext: () {
    // Handle booking action
  },
)
```

## Design System Integration

All components use the app's design system:
- **Colors**: Consistent use of `AppColors` constants
- **Typography**: Proper font weights and sizes
- **Spacing**: Consistent padding and margins
- **Borders**: Rounded corners and consistent border styling
- **Shadows**: Subtle elevation where appropriate

## State Management

The components follow a hierarchical state management pattern:
1. **Local State**: Form field values and selection states
2. **Parent State**: Booking actions and navigation
3. **Data State**: Project and plot data from providers

## Testing Considerations

- Components are designed to be easily testable with mock data
- State changes are predictable and testable
- UI interactions are properly handled with callbacks
- Form validation is clearly defined and testable

## Search Functionality

Both selection dialogs now include comprehensive search capabilities:

### Project Search
- **Search Fields**: Project name
- **Real-time Filtering**: Results update as you type
- **Clear Button**: Easy way to reset search
- **No Results State**: User-friendly message when no matches found

### Plot Search
- **Search Fields**: Plot number, facing direction, and remarks
- **Multi-field Search**: Searches across multiple plot properties
- **Visual Feedback**: Clear indication of search state
- **Responsive Design**: Adapts to different screen sizes

### Search Features
- **Case-insensitive**: Search works regardless of text case
- **Partial Matching**: Finds results containing search terms
- **Real-time Updates**: No need to press enter or search button
- **Clear Functionality**: Easy reset with clear button
- **Empty State Handling**: Proper messaging when no results found

## Future Enhancements

- Add form validation with error messages
- Add loading states for async operations
- Implement form persistence across app restarts
- Add accessibility improvements for screen readers
- Add advanced filtering options (price range, area range)
- Implement search history and recent selections
