# DHIS2 D2_Touch SDK - Complete Guide

## Project Overview

Your **DHIS2 Flutter Mobile App** is a starter implementation demonstrating how to integrate the **d2_touch SDK** (v1.1.9) with a Flutter application for mobile data collection and management.

### What is D2_Touch SDK?
- A Dart package providing **offline-first** access to DHIS2 (District Health Information Software System)
- Enables local database syncing, authentication, and data querying on mobile devices
- Used for health data collection in resource-constrained settings (healthcare, disease surveillance, immunization programs)
- Provides modular architecture for different data domains

---

## Current Application Flow

### 1. **Initialization Phase**
```dart
D2Touch d2Touch = await D2Touch.init();
```
- Sets up the local database
- Initializes all SDK modules
- Establishes connection paths to DHIS2

### 2. **Login Screen**
- **Credentials**: `admin` / `district`
- **Target Server**: `https://play.dhis2.org/2.36.10` (DHIS2 demo instance)
- **Process**: `D2Touch.logIn()` authenticates and downloads user info locally

### 3. **Data Screen**
- Displays user information
- Lists organization units (healthcare facilities)
- Reads from local database

---

## Core D2_Touch SDK Modules

### Available Modules in D2Touch Instance:

```
d2Touch.
  ├── userModule          // User & authentication data
  ├── orgUnitModule       // Organisation units (facilities, districts)
  ├── dataElementModule   // Health indicators/metrics
  ├── dataSetModule       // Data collection forms
  ├── dataValueModule     // Actual health data entries
  ├── eventModule         // Event-based data (case investigations)
  ├── trackedEntityModule // Individual tracking (patients, contacts)
  ├── programModule       // Programs (immunization, malaria, etc.)
  └── settingsModule      // App configuration & metadata
```

---

## 1. Authentication & Login

### Current Implementation
```dart
var status = await D2Touch.logIn(
  username: "admin",
  password: "district",
  url: "https://play.dhis2.org/2.36.10",
);

if (status == LoginResponseStatus.ONLINE_LOGIN_SUCCESS) {
  // Navigate to home screen
}
```

### Login Response Status Options
- `ONLINE_LOGIN_SUCCESS` - Successfully logged in
- `OFFLINE_LOGIN_SUCCESS` - Logged in with cached credentials
- `INVALID_CREDENTIALS` - Wrong username/password
- `SERVER_ERROR` - DHIS2 server unreachable
- `NETWORK_ERROR` - No internet connection

### Check Login Status
```dart
// Check if user is already logged in
bool isLoggedIn = await d2Touch.userModule.user.getOne() != null;
```

### Logout
```dart
await D2Touch.logOut();
```

---

## 2. Local Database Queries

### Query User Information
```dart
// Get current logged-in user
var user = await d2Touch.userModule.user.getOne();
print(user.displayName);    // "Administrator"
print(user.username);       // "admin"
print(user.email);          // "admin@dhis2.org"
```

### Query Organization Units
```dart
// Get all org units for current user
List orgUnits = await d2Touch.userModule.userOrganisationUnit.get();
for (var ou in orgUnits) {
  print("${ou.displayName} - ID: ${ou.id}");
}

// Get specific org unit
var facility = await d2Touch.orgUnitModule.organisationUnit.byId("rO2BK4zV8qZ");
print(facility.displayName);
```

### Filtering & Advanced Queries
```dart
// Get org units with filter
List filtered = await d2Touch.userModule.userOrganisationUnit
  .where((unit) => unit.level == 3)  // Facility level
  .get();

// Get org units with limited fields
List limited = await d2Touch.userModule.userOrganisationUnit
  .select(["id", "displayName", "level"])
  .get();
```

---

## 3. Data Rendering Patterns

### Pattern 1: Using FutureBuilder (Simple, Static Data)
```dart
FutureBuilder(
  future: d2Touch.userModule.user.getOne(),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const CircularProgressIndicator();
    }
    if (snapshot.hasError) {
      return Text("Error: ${snapshot.error}");
    }
    
    final user = snapshot.data;
    return Text("Welcome, ${user.displayName}");
  },
)
```

### Pattern 2: Using StreamBuilder (Real-time Updates)
```dart
StreamBuilder(
  stream: d2Touch.userModule.userOrganisationUnit.watch(),
  builder: (context, snapshot) {
    if (!snapshot.hasData) return const CircularProgressIndicator();
    
    final orgUnits = snapshot.data as List;
    return ListView.builder(
      itemCount: orgUnits.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(orgUnits[index].displayName),
          subtitle: Text("ID: ${orgUnits[index].id}"),
        );
      },
    );
  },
)
```

### Pattern 3: State Management (Complex UIs)
```dart
class DataScreen extends StatefulWidget {
  @override
  State<DataScreen> createState() => _DataScreenState();
}

class _DataScreenState extends State<DataScreen> {
  late Future<List> orgUnitsFuture;
  
  @override
  void initState() {
    super.initState();
    orgUnitsFuture = d2Touch.userModule.userOrganisationUnit.get();
  }
  
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: orgUnitsFuture,
      builder: (context, snapshot) {
        // Render UI here
      },
    );
  }
}
```

---

## 4. Working with Health Data

### Query Data Elements (Metrics/Indicators)
```dart
// Get all data elements
List dataElements = await d2Touch.dataElementModule.dataElement.get();

// Get with filter
List filtered = await d2Touch.dataElementModule.dataElement
  .where((de) => de.categoryCombo == "default")
  .select(["id", "displayName", "valueType"])
  .get();
```

### Query Data Sets (Forms)
```dart
// Get data entry forms
List dataSets = await d2Touch.dataSetModule.dataSet.get();

// Get data set details
var dataSet = await d2Touch.dataSetModule.dataSet.byId("lyLU2wO0ZXp");
print(dataSet.displayName);  // "RCH - ANC"
print(dataSet.expiryDays);   // Days before data entry expires
```

### Save Data Values (Offline-First)
```dart
// Create a new data value entry
var dataValue = {
  "dataElement": "f7n9E6iotQQ",  // Measles cases
  "value": "42",
  "organisationUnit": "ImspTQPwCqd",  // Health facility
  "period": "202405",  // May 2024
};

// Submit to local database (queued for sync)
await d2Touch.dataValueModule.dataValue.save(dataValue);

// Sync with server when online
await d2Touch.dataValueModule.dataValue.sync();
```

---

## 5. Events & Tracked Entities (Case Tracking)

### Query Events (Disease Cases)
```dart
// Get all events (disease investigations)
List events = await d2Touch.eventModule.event.get();

// Get events for a specific program
List programEvents = await d2Touch.eventModule.event
  .where((e) => e.program == "eBAyeGv0XqG")  // Malaria program
  .get();
```

### Query Tracked Entities (Patients/Contacts)
```dart
// Get tracked entities (e.g., patients)
List patients = await d2Touch.trackedEntityModule.trackedEntity.get();

// Get with relationships
var patient = await d2Touch.trackedEntityModule.trackedEntity.byId("NAv0tJ0HuTY");
print(patient.displayName);  // Patient name
print(patient.trackedEntityType);  // Patient type ID
```

### Save Events
```dart
var newEvent = {
  "eventDate": DateTime.now().toIso8601String(),
  "program": "eBAyeGv0XqG",
  "programStage": "stage_id",
  "organisationUnit": "ImspTQPwCqd",
  "trackedEntity": "patient_id",
  "dataValues": [
    {"dataElement": "de_id_1", "value": "Positive"},
    {"dataElement": "de_id_2", "value": "2024-05-10"},
  ]
};

await d2Touch.eventModule.event.save(newEvent);
await d2Touch.eventModule.event.sync();  // Sync when online
```

---

## 6. Offline Sync & Conflict Resolution

### Check Sync Status
```dart
// Check if data is synced
var status = await d2Touch.dataValueModule.dataValue.syncStatus();

// Get unsync records
List unsyncedValues = await d2Touch.dataValueModule.dataValue
  .where((dv) => dv.syncStatus == "NOT_SYNCED")
  .get();
```

### Manual Sync
```dart
// Sync all data
await d2Touch.dataValueModule.dataValue.sync();
await d2Touch.eventModule.event.sync();
await d2Touch.trackedEntityModule.trackedEntity.sync();

// Sync with progress callback
await d2Touch.dataValueModule.dataValue.sync(
  onProgress: (downloaded, total) {
    print("Synced: $downloaded / $total");
  }
);
```

### Handle Conflicts
```dart
// Get conflicting records
List conflicts = await d2Touch.dataValueModule.dataValue
  .where((dv) => dv.syncStatus == "ERROR")
  .get();

// Retry sync with force update
for (var record in conflicts) {
  await d2Touch.dataValueModule.dataValue
    .byId(record.id)
    .sync(forceUpdate: true);
}
```

---

## 7. Settings & Metadata

### App Configuration
```dart
// Get app settings
var settings = await d2Touch.settingsModule.settings.getOne();

// Check DHIS2 version
print(settings.dhis2Version);  // "2.36.10"

// Get system info
print(settings.serverUrl);
print(settings.username);
print(settings.appVersion);
```

### Metadata Downloads
```dart
// Trigger metadata sync (programs, forms, etc.)
await d2Touch.settingsModule.metadata.sync();

// Check last sync time
var lastSync = await d2Touch.settingsModule.metadata.lastSyncTime();
print("Last synced: $lastSync");
```

---

## Complete Example: Data Entry Form

```dart
import 'package:flutter/material.dart';
import 'package:d2_touch/d2_touch.dart';

class DataEntryScreen extends StatefulWidget {
  final D2Touch d2Touch;
  const DataEntryScreen({required this.d2Touch});

  @override
  State<DataEntryScreen> createState() => _DataEntryScreenState();
}

class _DataEntryScreenState extends State<DataEntryScreen> {
  late D2Touch d2Touch;
  final Map<String, TextEditingController> controllers = {};
  String? selectedOrgUnit;
  String? selectedDataSet;

  @override
  void initState() {
    super.initState();
    d2Touch = widget.d2Touch;
  }

  Future<void> _submitData() async {
    // Prepare data values
    List<Map> dataValues = controllers.entries
        .map((entry) => {
              "dataElement": entry.key,
              "value": entry.value.text,
              "organisationUnit": selectedOrgUnit,
              "period": _getCurrentPeriod(),
            })
        .toList();

    // Save to local database
    for (var dv in dataValues) {
      await d2Touch.dataValueModule.dataValue.save(dv);
    }

    // Attempt sync if online
    await d2Touch.dataValueModule.dataValue.sync();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Data saved successfully")),
    );
  }

  String _getCurrentPeriod() {
    final now = DateTime.now();
    return "${now.year}${now.month.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Health Data Entry")),
      body: FutureBuilder(
        future: Future.wait([
          d2Touch.userModule.userOrganisationUnit.get(),
          d2Touch.dataSetModule.dataSet.get(),
        ]),
        builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final orgUnits = snapshot.data![0] as List;
          final dataSets = snapshot.data![1] as List;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Organization Unit Selector
              DropdownButton(
                hint: const Text("Select Health Facility"),
                value: selectedOrgUnit,
                items: orgUnits
                    .map((ou) => DropdownMenuItem(
                          value: ou.id,
                          child: Text(ou.displayName),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() => selectedOrgUnit = value);
                },
              ),
              const SizedBox(height: 20),

              // Data Set Selector
              DropdownButton(
                hint: const Text("Select Data Form"),
                value: selectedDataSet,
                items: dataSets
                    .map((ds) => DropdownMenuItem(
                          value: ds.id,
                          child: Text(ds.displayName),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() => selectedDataSet = value);
                },
              ),
              const SizedBox(height: 20),

              // Data Entry Fields (Example)
              TextField(
                controller: controllers["f7n9E6iotQQ"] ??= TextEditingController(),
                decoration: const InputDecoration(
                  labelText: "Measles Cases",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: _submitData,
                child: const Text("Submit Data"),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    for (var controller in controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}
```

---

## API Reference Quick Links

| Operation | Method | Example |
|-----------|--------|---------|
| Get all records | `.get()` | `d2Touch.userModule.user.get()` |
| Get one record | `.getOne()` | `d2Touch.userModule.user.getOne()` |
| Get by ID | `.byId(id)` | `d2Touch.orgUnitModule.organisationUnit.byId("rO2BK")` |
| Filter | `.where(condition)` | `.where((u) => u.level == 3)` |
| Select fields | `.select(["id", "name"])` | Select specific columns |
| Save | `.save(data)` | `d2Touch.dataValueModule.dataValue.save(obj)` |
| Sync | `.sync()` | `d2Touch.dataValueModule.dataValue.sync()` |
| Watch changes | `.watch()` | Use with StreamBuilder |

---

## Best Practices

✅ **DO:**
- Always check internet connectivity before sync
- Use `FutureBuilder` or `StreamBuilder` for UI data binding
- Save data locally immediately (queue for later sync)
- Handle errors gracefully
- Clear sensitive data on logout

❌ **DON'T:**
- Block UI thread with long-running queries
- Sync inside heavy loops
- Store passwords in plaintext
- Make assumptions about data availability

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Login fails | Verify credentials & server URL |
| Data not syncing | Check internet connection & sync status |
| Slow queries | Use `.select()` to limit fields |
| Memory issues | Paginate large datasets with `.limit()` & `.offset()` |

