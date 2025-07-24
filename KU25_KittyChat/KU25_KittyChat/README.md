# KittyChat

A modern iOS chat application with AI safety protection mechanisms, focused on creating a safe and friendly chat environment.

## 📱 Application Overview

KittyChat is an iOS chat application built with SwiftUI, integrating an advanced AI Guardian safety system that can detect and handle inappropriate speech in real-time, providing users with a secure chat experience.

### 🌟 Core Features

- **AI Guardian Safety System** - Real-time detection of misogynistic speech and inappropriate content
- **Intelligent Matching System** - User pairing based on interest similarity
- **Bidirectional Interaction Management** - Complete sender and receiver response mechanisms
- **Real-time Chat Features** - Stable chat services based on Sendbird
- **User Profile Analysis** - Detailed personality analysis and safety status monitoring

## 🏗 Architecture Design

### Tech Stack
- **UI Framework**: SwiftUI + UIKit (Hybrid Architecture)
- **Architecture Pattern**: MVVM
- **Chat SDK**: Sendbird UIKit & Chat SDK
- **Programming Language**: Swift 5.0+
- **iOS Version**: iOS 14.0+

### Project Structure

```
KU25_KittyChat/
├── Core/                           # Core functionality modules
│   ├── DetectionEngine/           # AI detection engine
│   │   ├── DetectionEngine.swift  # Main detection logic
│   │   └── BiDirectionalInteractionManager.swift # Bidirectional interaction management
│   ├── MessageMonitor/            # Message monitoring system
│   │   └── GlobalMessageMonitor.swift # Global message monitoring
│   ├── MessageRouter/             # Message routing system
│   │   └── AIMessageRouter.swift  # AI message router
│   ├── LocalData/                 # Local data management
│   │   └── StrikeManager.swift    # Strike record management
│   ├── Sendbird/                  # Sendbird integration
│   │   └── SendbirdAPI.swift      # Sendbird API wrapper
│   └── UI/                        # Shared UI components
│       ├── Color+Hex.swift        # Color extensions
│       ├── FlowLayout.swift       # Flow layout
│       └── StatCard.swift         # Statistics card component
├── Features/                       # Feature modules
│   ├── Chat/                      # Chat functionality
│   │   └── KittyChatChannelViewController.swift
│   ├── Matching/                  # Matching functionality
│   │   ├── MatchingView.swift     # Main matching interface
│   │   ├── MatchingReadyView.swift # Pairing preparation page
│   │   └── MatchingCongratsView.swift # Successful pairing page
│   ├── Onboarding/                # Onboarding flow
│   │   ├── OnboardingView.swift   # Welcome page
│   │   └── ProfileAnalysisView.swift # Profile analysis page
│   └── Profile/                   # User profile
│       ├── ProfileView.swift      # Personal profile page
│       └── ProfileComponents.swift # Profile components
├── Data/                          # Data models
│   └── UserProfile.swift         # User profile model
├── Resources/                     # Resource files
│   ├── Assets.xcassets/          # Image assets
│   └── MockData/                 # Test data
│       ├── DetectionRules.json   # Detection rules
│       └── Users/               # Test user data
└── KU25_KittyChatApp.swift      # Application entry point
```

## 🔧 Core Systems

### 1. AI Guardian Safety System

#### Detection Engine (DetectionEngine)
- **Functionality**: Real-time detection of misogynistic speech, stereotypes, and demeaning language
- **Supported Languages**: English, Japanese

#### Bidirectional Interaction Management (BiDirectionalInteractionManager)
- **Sender Options**:
  - Retract Message
  - Edit Message
  - Just Joking
- **Receiver Options**:
  - Acceptable
  - Uncomfortable but continue
  - Exit now

### 2. Intelligent Matching System

#### Interest Matching Algorithm
```swift
// Pairing based on common interest count
let commonInterests = myInterests.intersection(partnerInterests).count
```

#### Matching Process
1. Retrieve all online users
2. Analyze interest similarity
3. Select best matching partner
4. Create dedicated chat room

## 🚀 Installation & Setup

### Environment Requirements
- Xcode 14.0+
- iOS 14.0+
- Swift 5.0+

### Installation Steps

1. **Clone Project**
```bash
git clone <repository-url>
cd KU25_KittyChat
```

2. **Open Xcode Project**
```bash
open KU25_KittyChat.xcodeproj
```

3. **Add Sendbird Package**
   
   In Xcode:
   - Select **File → Add Package Dependencies...**
   - Enter Sendbird UIKit URL: `https://github.com/sendbird/sendbird-uikit-ios`
   - Choose version (recommend using latest stable version)
   - Add the following Target Dependencies:
     - `SendbirdUIKit`
     - `SendbirdChatSDK`


4. **Configure Sendbird**
   
   **⚠️ Important: Please contact YUJU for the following required information:**
   - **Sendbird Application ID**
   - **Sendbird API Token**
   
   After obtaining the information, update the following two files:
   
   **📄 KU25_KittyChatApp.swift**
   ```swift
   // Line 19, replace "YOURID" with actual Application ID
   SendbirdUI.initialize(
       applicationId: "YOUR_ACTUAL_APP_ID", // Replace here
       startHandler: { ... }
   )
   ```
   
   **📄 Core/Sendbird/SendbirdAPI.swift**
   ```swift
   struct SendbirdAPI {
       static let appId = "YOUR_ACTUAL_APP_ID"     // Replace here
       static let apiToken = "YOUR_ACTUAL_TOKEN"   // Replace here
       // ...
   }
   ```
   
   > 💡 **Reminder**: Please ensure not to commit real IDs and TOKENs to public code repositories

### Dependencies

#### Main Dependencies
- **SendbirdUIKit** (3.0.0+): Complete chat interface components
- **SendbirdChatSDK** (4.0.0+): Chat core functionality and API

#### Package Repository
- **GitHub**: https://github.com/sendbird/sendbird-uikit-ios
- **Documentation**: https://sendbird.com/docs/uikit/v3/ios/getting-started/about-uikit

#### Minimum System Requirements
- iOS 11.0+
- Xcode 14.0+
- Swift 5.0+

## 📚 Usage Guide

### User Registration Flow
1. Enter User ID and Threads account
2. System analyzes user profile and interests
3. Display personality analysis results
4. Set display name and complete registration

### Chat Features
1. **Safe Matching**: Click "Safe Match" to start pairing
2. **Real-time Chat**: Enter chat room after successful pairing
3. **AI Monitoring**: All messages automatically undergo AI Guardian detection
4. **Interaction Response**: Inappropriate content triggers bidirectional response mechanism

### Personal Profile Management
- View personal interest tags
- Monitor safety status and strike records
- Display personality analysis results

## 🧪 Test Data

The application includes rich test data:

### Test Users
- `user1` - user5: Test users with different personalities and interests
- Default safety status and strike records
- Complete personality analysis data

### Detection Rules
- 37 predefined detection rules
- Covers stereotypes, demeaning language, offensive content
- Supports English and Japanese detection keywords





