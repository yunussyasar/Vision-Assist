# VisionAssist 👁️

An iOS accessibility application designed for visually impaired users that provides **real-time object detection** with **voice-guided spatial feedback**.

![Platform](https://img.shields.io/badge/Platform-iOS%2015.0+-blue)
![Swift](https://img.shields.io/badge/Swift-5.0-orange)
![License](https://img.shields.io/badge/License-MIT-green)

## 📱 Overview

VisionAssist helps visually impaired users navigate their environment by detecting objects through the camera and providing audio feedback about what's around them. Users can search for specific objects using voice commands, and the app announces the object's location and distance using natural speech.

### Demo

| Feature | Description |
|---------|-------------|
| 🎤 Voice Search | Say "Find my phone" or "Where is the computer" |
| 🔊 Audio Feedback | "Found Computer. It is on your left, nearby" |
| 📳 Haptic Feedback | Vibration when target object is detected |
| 👁️ Real-time Detection | Continuous object recognition from camera feed |

## ✨ Features

- **Real-time Object Detection** - Uses Apple Vision Framework for continuous object recognition
- **Voice Commands** - Hands-free object search using natural language
- **Spatial Audio Feedback** - Announces object position (left/right/center) and distance
- **Haptic Feedback** - Tactile notifications when objects are found
- **Accessible UI** - Full VoiceOver support with proper accessibility labels
- **Detection Smoothing** - Prevents UI flickering with intelligent frame processing

## 🛠️ Technologies

| Technology | Purpose |
|------------|---------|
| **Swift & SwiftUI** | UI and application logic |
| **Apple Vision Framework** | Object classification (VNClassifyImageRequest) |
| **AVFoundation** | Camera capture and audio session management |
| **Speech Framework** | Voice command recognition (SFSpeechRecognizer) |
| **AVSpeechSynthesizer** | Text-to-speech for audio feedback |
| **CoreML** | Machine learning model integration ready |

## 📋 Requirements

- iOS 15.0+
- Xcode 14.0+
- Physical iOS device (camera required)

## 🚀 Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yunussyasar/VisionAssist.git
   cd VisionAssist
   ```

2. **Open in Xcode**
   ```bash
   open VisionAssist.xcodeproj
   ```

3. **Configure signing**
   - Select the project in Xcode
   - Go to "Signing & Capabilities"
   - Select your development team

4. **Build and run**
   - Connect your iOS device
   - Select your device as the target
   - Press `Cmd + R` to build and run

## 📖 Usage

### Basic Usage

1. **Launch the app** - Grant camera and microphone permissions when prompted
2. **View detections** - Objects are automatically detected and shown on screen
3. **Search for objects** - Tap the microphone button and say:
   - "Find [object name]" (e.g., "Find my keys")
   - "Where is [object]" (e.g., "Where is the laptop")
   - "Look for [object]" (e.g., "Look for a chair")

### Voice Commands

| Command | Example |
|---------|---------|
| Find | "Find my phone" |
| Search | "Search for a bottle" |
| Look for | "Look for the remote" |
| Where is | "Where is my wallet" |
| Locate | "Locate the door" |
| Clear | "Clear" or "Cancel" to stop searching |

### Audio Feedback Examples

- **Object found:** *"Found Phone. It is on your left, nearby. 85 percent confident."*
- **Object lost:** *"Phone is no longer visible. Move your camera around to find it."*
- **Position updates:** *"Phone is now on your right"*

## 🏗️ Architecture

```
VisionAssist/
├── VisionAssistApp.swift      # App entry point
├── ContentView.swift          # Main UI with camera preview
├── ObjectDetector.swift       # Vision framework integration
├── CameraManager.swift        # AVFoundation camera handling
├── CameraPreview.swift        # SwiftUI camera view wrapper
├── VoiceCommandManager.swift  # Speech recognition
├── AudioFeedbackManager.swift # Text-to-speech feedback
├── HapticFeedbackManager.swift# Haptic notifications
└── Info.plist                 # App permissions
```

### Key Components

#### ObjectDetector
Handles real-time object detection using Apple's Vision framework. Features:
- Frame skipping for performance (processes every 3rd frame)
- Detection history smoothing (requires 60% consistency over 5 frames)
- Automatic target tracking with state management

#### VoiceCommandManager
Manages speech recognition for hands-free operation:
- Supports multiple trigger phrases
- Extracts object names from natural language
- Handles audio session switching between record and playback

#### AudioFeedbackManager
Provides voice feedback using AVSpeechSynthesizer:
- Detailed position announcements (left/right, top/bottom, distance)
- Debounced announcements to prevent repetition
- Forced speaker output routing

## 🔒 Privacy & Permissions

The app requires the following permissions (configured in Info.plist):

| Permission | Reason |
|------------|--------|
| Camera | Object detection from live camera feed |
| Microphone | Voice command recognition |
| Speech Recognition | Converting speech to text for commands |

## 🎯 Future Improvements

- [ ] Custom YOLO model integration for better object detection
- [ ] Offline mode with on-device ML models
- [ ] Object distance estimation using depth sensor
- [ ] Multi-language support (Turkish, German, etc.)
- [ ] Saved object presets for quick search
- [ ] AR overlay showing object locations

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👨‍💻 Author

**Yunus Emre**

- GitHub: [@yunussyasar](https://github.com/yunussyasar)

## 🙏 Acknowledgments

- Apple Vision Framework documentation
- SwiftUI accessibility guidelines
- iOS Human Interface Guidelines for accessibility

---

<p align="center">
  Made with ❤️ for accessibility
</p>
