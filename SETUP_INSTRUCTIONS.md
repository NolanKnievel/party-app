# Party Game App - Xcode Setup Instructions

## Overview

I've created all the necessary files for the Party Game App, including the default question decks and data seeding functionality. However, these files need to be properly integrated into an Xcode project.

## Files Created

- `PartyGameApp/PartyGameAppApp.swift` - Main app file with data seeding logic
- `PartyGameApp/ContentView.swift` - Basic UI to display decks
- `PartyGameApp/DataModel.xcdatamodeld/DataModel.xcdatamodel/contents` - Core Data model
- `PartyGameApp/Info.plist` - App configuration
- `PartyGameAppTests/DefaultContentTests.swift` - Tests for default content

## Setup Steps

### 1. Create New Xcode Project

1. Open Xcode
2. Choose "Create a new Xcode project"
3. Select "iOS" → "App"
4. Fill in project details:
   - Product Name: `PartyGameApp`
   - Interface: `SwiftUI`
   - Language: `Swift`
   - Use Core Data: ✅ (checked)
   - Include Tests: ✅ (checked)
5. Save the project in the `party-app` directory (replace the existing folder)

### 2. Replace Generated Files

After creating the project, replace these generated files with the ones I created:

- Replace `PartyGameAppApp.swift` with the one I created
- Replace `ContentView.swift` with the one I created
- Replace the Core Data model with the one I created
- Add `DefaultContentTests.swift` to the test target

### 3. Verify Project Structure

Your project should have:

```
PartyGameApp/
├── PartyGameAppApp.swift (main app with data seeding)
├── ContentView.swift (basic UI)
├── DataModel.xcdatamodeld/ (Core Data model)
├── Assets.xcassets/
└── Info.plist

PartyGameAppTests/
├── PartyGameAppTests.swift (generated)
└── DefaultContentTests.swift (my tests)
```

### 4. Build and Test

1. Build the project (⌘+B)
2. Run the tests (⌘+U) to verify default content creation
3. Run the app (⌘+R) to see the default decks

## What's Implemented

✅ **Task 3: Create default question decks and data seeding**

- ✅ Default Truth or Dare deck with 20 questions (mix of truths and dares)
- ✅ Default Would You Rather deck with 20 questions
- ✅ Data seeding service integrated into app launch
- ✅ Tests to verify default content is properly loaded
- ✅ Covers requirements 3.1 and 3.2

## Features

- **Default Decks**: Two pre-populated decks with engaging questions
- **Data Seeding**: Automatic creation of default content on first launch
- **Core Data Integration**: Proper persistence with CloudKit support
- **Comprehensive Tests**: Verify content creation and data integrity
- **No Duplicates**: Logic prevents creating duplicate default decks

## Next Steps

After setting up the Xcode project, you can:

1. Run the app to see the default decks
2. Run tests to verify everything works
3. Continue with the next task in the implementation plan

## Questions Content Summary

- **Truth or Dare**: 20 questions ranging from light-hearted to challenging
- **Would You Rather**: 20 thought-provoking choice questions
- **Difficulty Levels**: Easy, Medium, Hard appropriately distributed
- **Categories**: Properly categorized for game mechanics
