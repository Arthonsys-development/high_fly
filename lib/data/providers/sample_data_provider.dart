import '../models/project_model.dart';
import '../models/customer_model.dart';

class SampleDataProvider {
  static List<Project> getSampleProjects() {
    return [
      Project(
        id: '1',
        name: 'Greenwood Estates',
        plots: [
          Plot(
            id: '1-1',
            plotNumber: 'Plot A-101',
            projectId: '1',
            area: 2400,
            price: 85000,
            dimensions: '40×60 ft',
            facing: 'North',
            remark: 'Pending further clarification',
          ),
          Plot(
            id: '1-2',
            plotNumber: 'Plot A-102',
            projectId: '1',
            area: 2200,
            price: 78000,
            dimensions: '40×55 ft',
            facing: 'South',
            remark: 'Available immediately',
          ),
          Plot(
            id: '1-3',
            plotNumber: 'Plot A-103',
            projectId: '1',
            area: 2600,
            price: 92000,
            dimensions: '40×65 ft',
            facing: 'East',
            remark: 'Corner plot',
          ),
        ],
      ),
      Project(
        id: '2',
        name: 'Sunset Gardens',
        plots: [
          Plot(
            id: '2-1',
            plotNumber: 'Plot B-201',
            projectId: '2',
            area: 2000,
            price: 75000,
            dimensions: '40×50 ft',
            facing: 'West',
            remark: 'Near park',
          ),
          Plot(
            id: '2-2',
            plotNumber: 'Plot B-202',
            projectId: '2',
            area: 2300,
            price: 82000,
            dimensions: '40×57.5 ft',
            facing: 'North',
            remark: 'Premium location',
          ),
        ],
      ),
      Project(
        id: '3',
        name: 'Mountain View Residency',
        plots: [
          Plot(
            id: '3-1',
            plotNumber: 'Plot C-301',
            projectId: '3',
            area: 2800,
            price: 95000,
            dimensions: '40×70 ft',
            facing: 'South',
            remark: 'Hill view',
          ),
          Plot(
            id: '3-2',
            plotNumber: 'Plot C-302',
            projectId: '3',
            area: 2500,
            price: 88000,
            dimensions: '40×62.5 ft',
            facing: 'East',
            remark: 'Garden facing',
          ),
        ],
      ),
    ];
  }

  static List<Customer> getSampleCustomers() {
    return [
      Customer(
        id: '1',
        name: 'Michael Rodriguez',
        email: 'michael.r@email.com',
        phone: '+1 (555) 123-4567',
        location: 'Downtown District',
        budgetRange: '\$75,000 - \$100,000',
        notes: 'Interested in premium plots',
      ),
      Customer(
        id: '2',
        name: 'Sarah Johnson',
        email: 'sarah.j@email.com',
        phone: '+1 (555) 234-5678',
        location: 'Uptown Area',
        budgetRange: '\$50,000 - \$75,000',
        notes: 'First-time buyer',
      ),
      Customer(
        id: '3',
        name: 'David Chen',
        email: 'david.c@email.com',
        phone: '+1 (555) 345-6789',
        location: 'Suburban District',
        budgetRange: '\$100,000 - \$150,000',
        notes: 'Looking for family home',
      ),
      Customer(
        id: '4',
        name: 'Emily Williams',
        email: 'emily.w@email.com',
        phone: '+1 (555) 456-7890',
        location: 'Riverside',
        budgetRange: '\$60,000 - \$90,000',
        notes: 'Prefers waterfront properties',
      ),
      Customer(
        id: '5',
        name: 'Robert Brown',
        email: 'robert.b@email.com',
        phone: '+1 (555) 567-8901',
        location: 'Business District',
        budgetRange: '\$80,000 - \$120,000',
        notes: 'Investment property',
      ),
    ];
  }
}
