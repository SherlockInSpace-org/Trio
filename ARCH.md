# Trio Architecture

This document outlines the architecture of the Trio closed-loop application.

## High-Level Overview

Trio is a closed-loop insulin delivery application for iOS. It is built upon the foundation of the Loop project and incorporates various other open-source components to provide a comprehensive solution for automated insulin delivery.

The project is structured as a monorepo containing the main application (`Trio`) and several supporting frameworks and modules. These can be broadly categorized as:

*   **Core Loop Functionality:** The `LoopKit` framework, which provides the fundamental building blocks for a closed-loop system.
*   **Device Communication:** A collection of frameworks for communicating with various CGM (Continuous Glucose Monitor) and insulin pump hardware.
*   **Data Model:** A Core Data-based model for storing application data.
*   **Algorithm:** The OpenAPS (oref0) algorithm, implemented in JavaScript.
*   **Main Application:** The `Trio` application itself, which integrates all the components into a user-facing app.

## Key Directories

### `Trio/`

This is the main application target. It contains the user interface, application logic, and integration of the various frameworks.

*   `Trio/Sources/`: This directory contains the Swift source code for the application.
    *   `Application/`: Contains the main app entry point and app delegate.
    *   `Modules/`: Contains the different UI screens of the application, following a Model-View-Provider (MVP) or similar pattern. Key modules include `Home`, `Settings`, `Onboarding`, and `Treatments`.
    *   `Services/`: Contains various services used by the application, such as `HealthKitManager`, `WatchManager`, and `NetworkService`.
    *   `APS/`: Contains the "Artificial Pancreas System" logic, which is the core of the automated insulin delivery system. This is where the `OpenAPS` JavaScript code is managed and executed.
*   `Trio.xcodeproj/`: The Xcode project file for the main application.
*   `Trio.xcworkspace/`: The Xcode workspace, which includes the main project and all the submodule dependencies.

### `LoopKit/`

`LoopKit` is a core component of Trio, providing the underlying architecture and functionality for a closed-loop system. It defines protocols and services for:

*   **Device Management:** CGM and Pump manager protocols.
*   **Data Storage:** Storing glucose, insulin, and carb data.
*   **Dosing Logic:** The core logic for calculating and recommending insulin doses.
*   **UI Components:** Reusable UI components for settings, charts, and device management.

### Device Communication Frameworks

Trio supports a wide range of diabetes devices through a set of dedicated frameworks. Each of these frameworks is a git submodule and is responsible for handling the specific communication protocols of a particular device.

*   **CGM Frameworks:**
    *   `CGMBLEKit/`: For Dexcom G4, G5, and G6 CGMs using Bluetooth Low Energy.
    *   `dexcom-share-client-swift/`: For fetching glucose data from the Dexcom Share service.
    *   `G7SensorKit/`: For Dexcom G7.
    *   `LibreTransmitter/`: For FreeStyle Libre sensors.
*   **Pump Frameworks:**
    *   `DanaKit/`: For Dana-i and Dana-RS insulin pumps.
    *   `MinimedKit/`: For Medtronic insulin pumps.
    *   `OmniBLE/`: For Omnipod DASH pods.
    *   `OmniKit/`: For Omnipod Eros pods.
    *   `RileyLinkKit/`: A framework for communicating with RileyLink-compatible devices, which bridge Bluetooth Low Energy to the radio frequencies used by some pumps.

### `Model/`

This directory contains the Core Data model for the application.

*   `TrioCoreDataPersistentContainer.xcdatamodeld`: The Core Data model definition file.
*   `CoreDataStack.swift`: A helper class for managing the Core Data stack.
*   `Classes+Properties/`: Contains the generated `NSManagedObject` subclasses for the Core Data entities.

### `trio-oref/`

This directory contains the JavaScript implementation of the OpenAPS "oref0" algorithm.

*   `lib/`: Contains the core oref0 JavaScript files, such as `determine-basal.js`, `iob.js`, and `meal.js`.
*   The `APS/OpenAPS/` directory in the main `Trio` project contains the Swift code responsible for running this JavaScript code and passing data to and from it.
