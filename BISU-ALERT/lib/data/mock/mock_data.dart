import '../model/alert_message.dart';
import '../model/campus_location.dart';
import '../model/emergency_contact.dart';

class MockData {
  static const List<CampusLocation> campusLocations = [
    // Buildings
    CampusLocation(
      id: 'admin',
      name: 'Main Administration Building',
      description: 'Central admin offices, registrar, and campus records section.',
      latitude: 9.718541,
      longitude: 124.109619,
      type: LocationType.building,
      contactNumber: '+63 38 000 1201',
    ),
    CampusLocation(
      id: 'caf',
      name: 'College of Agriculture & Forestry (CAF)',
      description: 'Classrooms, agro-forestry laboratories, and faculty offices.',
      latitude: 9.720121,
      longitude: 124.106403,
      type: LocationType.building,
      contactNumber: '+63 38 000 1202',
    ),
    CampusLocation(
      id: 'cct',
      name: 'Computer Studies & Technology Building (CCT)',
      description: 'IT and computer laboratories, server rooms, lecture halls.',
      latitude: 9.718041,
      longitude: 124.109602,
      type: LocationType.building,
      contactNumber: '+63 38 000 1203',
    ),
    CampusLocation(
      id: 'gym',
      name: 'Student Center & University Gymnasium',
      description: 'Large multi-purpose indoor court, assembly hall, and student hub.',
      latitude: 9.718936,
      longitude: 124.110054,
      type: LocationType.building,
      contactNumber: '+63 38 000 1204',
    ),

    // Emergency Hubs & Clinic
    CampusLocation(
      id: 'clinic',
      name: 'Campus Medical Clinic',
      description: 'Emergency first-aid, triage beds, and campus nurse post.',
      latitude: 9.717639,
      longitude: 124.109396,
      type: LocationType.clinic,
      contactNumber: '+63 38 000 9111',
    ),
    CampusLocation(
      id: 'gate',
      name: 'Main Gate Security Guardhouse',
      description: 'Primary security checkpoint, dispatch post, radio base.',
      latitude: 9.718314,
      longitude: 124.111249,
      type: LocationType.security,
      contactNumber: '+63 38 000 9112',
    ),
    CampusLocation(
      id: 'hub_central',
      name: 'Central Emergency Operations Hub',
      description: 'Disaster response coordination center & emergency supplies depot.',
      latitude: 9.718600,
      longitude: 124.108500,
      type: LocationType.emergencyHub,
      contactNumber: '+63 38 000 9115',
    ),

    // Evacuation Zones & Safe Areas
    CampusLocation(
      id: 'evac_a',
      name: 'Assembly Area A (Disaster Grounds)',
      description: 'Primary campus open-field assembly area for earthquake & fire evacuation.',
      latitude: 9.719900,
      longitude: 124.107900,
      type: LocationType.evacuationZone,
      contactNumber: '+63 38 000 9130',
    ),
    CampusLocation(
      id: 'evac_b',
      name: 'Assembly Area B (Grandstand Field)',
      description: 'Secondary open evacuation space away from power lines and structures.',
      latitude: 9.717200,
      longitude: 124.106800,
      type: LocationType.evacuationZone,
      contactNumber: '+63 38 000 9131',
    ),

    // Emergency Exits
    CampusLocation(
      id: 'exit_gate1',
      name: 'Emergency Exit - Main Gate 1',
      description: 'East vehicular and pedestrian emergency exit route.',
      latitude: 9.718396,
      longitude: 124.111473,
      type: LocationType.emergencyExit,
      contactNumber: '+63 38 000 9112',
    ),
    CampusLocation(
      id: 'exit_gate2',
      name: 'Emergency Exit - West Perimeter Gate',
      description: 'Alternative evacuation exit leading toward provincial highway.',
      latitude: 9.716583,
      longitude: 124.105591,
      type: LocationType.emergencyExit,
      contactNumber: '+63 38 000 9112',
    ),

    // Fire Equipment & Extinguishers
    CampusLocation(
      id: 'fire_hose_admin',
      name: 'Admin Fire Hose Cabinet & Hydrant',
      description: 'High-pressure fire hose station with 2.5-inch connection.',
      latitude: 9.718420,
      longitude: 124.109750,
      type: LocationType.fireEquipment,
      contactNumber: '+63 38 500 1601',
    ),
    CampusLocation(
      id: 'fire_ext_cct',
      name: 'CCT Multi-Purpose Fire Extinguisher',
      description: 'Class ABC dry chemical fire extinguisher - Ground Floor.',
      latitude: 9.718100,
      longitude: 124.109500,
      type: LocationType.fireExtinguisher,
      contactNumber: '+63 38 000 9112',
    ),
    CampusLocation(
      id: 'fire_ext_gym',
      name: 'Gymnasium Fire Extinguisher Station',
      description: 'CO2 electrical & Class A extinguisher located near east portal.',
      latitude: 9.718850,
      longitude: 124.110200,
      type: LocationType.fireExtinguisher,
      contactNumber: '+63 38 000 9112',
    ),
  ];

  static const List<EmergencyContact> emergencyContacts = [
    EmergencyContact(
      name: 'BISU Bilar Campus Security Office',
      role: 'Campus Security',
      phoneNumber: '+63 38 000 9112',
    ),
    EmergencyContact(
      name: 'BISU Bilar University Clinic',
      role: 'Campus Clinic',
      phoneNumber: '+63 38 000 9111',
    ),
    EmergencyContact(
      name: 'Bilar MDRRMO',
      role: 'Municipal Disaster Response',
      phoneNumber: '+63 38 500 1300',
    ),
    EmergencyContact(
      name: 'Bilar Municipal Police Station',
      role: 'Police',
      phoneNumber: '+63 38 500 1170',
    ),
    EmergencyContact(
      name: 'Bilar Fire Station (BFP)',
      role: 'Fire Response',
      phoneNumber: '+63 38 500 1601',
    ),
    EmergencyContact(
      name: 'Gov. Celestino Gallares Memorial Medical Center',
      role: 'Hospital',
      phoneNumber: '+63 38 411 4861',
    ),
  ];

  static final List<AlertMessage> activeAlerts = [
    AlertMessage(
      title: 'Active Emergency Alert',
      detail: 'Medical assistance requested at Student Center. Security team en route.',
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      isCritical: true,
    ),
    AlertMessage(
      title: 'Weather Advisory - Yellow Alert',
      detail: 'Moderate to heavy rainfall expected over Bilar and central Bohol. Avoid tree lines.',
      timestamp: DateTime.now().subtract(const Duration(minutes: 45)),
      isCritical: false,
    ),
    AlertMessage(
      title: 'Campus Safety Broadcast',
      detail: 'Quarterly earthquake evacuation drill scheduled for tomorrow at Assembly Area A.',
      timestamp: DateTime.now().subtract(const Duration(hours: 3)),
      isCritical: false,
    ),
  ];
}
