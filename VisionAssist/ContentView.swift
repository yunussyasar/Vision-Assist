import SwiftUI

struct ContentView: View {
    @StateObject private var cameraManager = CameraManager()
    @StateObject private var objectDetector = ObjectDetector()
    @StateObject private var voiceCommandManager = VoiceCommandManager()
    @ObservedObject private var settings = SettingsManager.shared
    @State private var showSettings = false
    
    var body: some View {
        ZStack {
            // MARK: - Camera Preview
            CameraPreview(session: cameraManager.session)
                .edgesIgnoringSafeArea(.all)
                .accessibilityLabel("Camera view")
                .accessibilityHint("Shows real-time camera feed for object detection")
                .onAppear {
                    cameraManager.onFrameCaptured = { buffer in
                        objectDetector.processFrame(buffer)
                    }
                }
                .onChange(of: voiceCommandManager.targetObject) { newTarget in
                    objectDetector.targetObject = newTarget
                    
                    // Announce target change for accessibility
                    if let target = newTarget {
                        UIAccessibility.post(notification: .announcement, argument: "Now searching for \(target)")
                    } else {
                        UIAccessibility.post(notification: .announcement, argument: "Search cleared")
                    }
                }
                .onChange(of: objectDetector.isTargetFound) { found in
                    if found, let target = objectDetector.targetObject {
                        UIAccessibility.post(notification: .announcement, argument: "Found \(target)")
                    }
                }
            
            VStack {
                // MARK: - Top Bar with Settings Button
                HStack {
                    Spacer()
                    Button(action: {
                        showSettings = true
                    }) {
                        Image(systemName: "gearshape.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .accessibilityLabel("Ayarlar")
                    .accessibilityHint("Uygulama ayarlarını açmak için çift dokunun")
                }
                .padding(.horizontal)
                .padding(.top, 50)
                // MARK: - Search Status Banner
                if let target = objectDetector.targetObject {
                    HStack {
                        Image(systemName: objectDetector.isTargetFound ? "checkmark.circle.fill" : "magnifyingglass")
                            .foregroundColor(objectDetector.isTargetFound ? .green : .white)
                        
                        Text(objectDetector.isTargetFound ? "Found: \(target)" : "Searching for: \(target)")
                            .font(.headline)
                        
                        Spacer()
                        
                        // Clear Search Button
                        Button(action: {
                            voiceCommandManager.clearSearch()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .accessibilityLabel("Clear search")
                        .accessibilityHint("Double tap to stop searching for \(target)")
                    }
                    .padding()
                    .background(objectDetector.isTargetFound ? Color.green.opacity(0.8) : Color.blue.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .padding(.top, 50)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(objectDetector.isTargetFound ? "Found \(target)" : "Searching for \(target)")
                }
                
                // MARK: - Voice Command Status
                if let error = voiceCommandManager.errorMessage {
                    Text(error)
                        .font(.caption)
                        .padding(8)
                        .background(Color.red.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .padding(.horizontal)
                        .accessibilityLabel("Error: \(error)")
                }
                
                if voiceCommandManager.isRecording && !voiceCommandManager.recognizedText.isEmpty {
                    Text("Heard: \"\(voiceCommandManager.recognizedText)\"")
                        .font(.caption)
                        .padding(8)
                        .background(Color.black.opacity(0.6))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .padding(.horizontal)
                        .accessibilityLabel("Recognized speech: \(voiceCommandManager.recognizedText)")
                }
                
                Spacer()
                
                // MARK: - Detected Objects Display
                if settings.showObjectCards {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(objectDetector.detectedObjects) { object in
                                DetectedObjectCard(object: object, isTarget: isTargetObject(object))
                            }
                        }
                        .padding(.horizontal)
                    }
                    .frame(height: 100)
                    .padding(.bottom, 20)
                }
                
                // MARK: - Voice Command Button
                VoiceCommandButton(voiceCommandManager: voiceCommandManager)
                    .padding(.bottom, 30)
            }
            
            // MARK: - Permission Warning
            if !cameraManager.permissionGranted {
                VStack(spacing: 16) {
                    Image(systemName: "camera.fill")
                        .font(.largeTitle)
                    Text("Camera Access Required")
                        .font(.headline)
                    Text("Please enable camera access in Settings to use VisionAssist")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                }
                .foregroundColor(.white)
                .padding()
                .background(Color.black.opacity(0.85))
                .cornerRadius(16)
                .padding()
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Camera access required. Please enable camera access in Settings to use VisionAssist.")
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .preferredColorScheme(settings.colorScheme)
    }
    
    /// Check if a detected object matches the current search target
    private func isTargetObject(_ object: DetectedObject) -> Bool {
        guard let target = objectDetector.targetObject else { return false }
        return object.label.lowercased().contains(target.lowercased())
    }
}

// MARK: - Detected Object Card

/// A modern card displaying a detected object with glassmorphism effect
struct DetectedObjectCard: View {
    let object: DetectedObject
    let isTarget: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            // Icon based on object type
            ZStack {
                Circle()
                    .fill(isTarget ? Color.green : Color.white.opacity(0.2))
                    .frame(width: 44, height: 44)
                
                Image(systemName: iconForObject(object.label))
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(isTarget ? .white : .white.opacity(0.9))
            }
            
            // Object Label
            Text(object.label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(1)
            
            // Confidence Badge
            HStack(spacing: 4) {
                Circle()
                    .fill(confidenceColor)
                    .frame(width: 6, height: 6)
                
                Text("\(Int(object.confidence * 100))%")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            ZStack {
                // Glassmorphism background
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                
                // Gradient overlay for target
                if isTarget {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [Color.green.opacity(0.4), Color.green.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                
                // Border
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isTarget ? Color.green : Color.white.opacity(0.2),
                        lineWidth: isTarget ? 2 : 1
                    )
            }
        )
        .shadow(color: isTarget ? Color.green.opacity(0.3) : Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
        .scaleEffect(isTarget ? 1.05 : 1.0)
        .animation(.spring(response: 0.3), value: isTarget)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(object.label), \(object.spatialPosition), \(Int(object.confidence * 100)) percent confidence\(isTarget ? ", target found" : "")")
    }
    
    /// Returns confidence color based on value
    private var confidenceColor: Color {
        if object.confidence >= 0.8 {
            return .green
        } else if object.confidence >= 0.5 {
            return .yellow
        } else {
            return .orange
        }
    }
    
    /// Returns an appropriate SF Symbol for the object type
    private func iconForObject(_ label: String) -> String {
        let lowercased = label.lowercased()
        
        // Map common objects to SF Symbols
        let iconMap: [String: String] = [
            "computer": "desktopcomputer",
            "laptop": "laptopcomputer",
            "phone": "iphone",
            "mobile": "iphone",
            "keyboard": "keyboard",
            "mouse": "computermouse",
            "monitor": "display",
            "screen": "display",
            "person": "person.fill",
            "people": "person.2.fill",
            "car": "car.fill",
            "vehicle": "car.fill",
            "dog": "dog.fill",
            "cat": "cat.fill",
            "bird": "bird.fill",
            "book": "book.fill",
            "bottle": "waterbottle.fill",
            "cup": "cup.and.saucer.fill",
            "chair": "chair.fill",
            "table": "table.furniture.fill",
            "tv": "tv.fill",
            "television": "tv.fill",
            "clock": "clock.fill",
            "lamp": "lamp.desk.fill",
            "bag": "bag.fill",
            "backpack": "backpack.fill",
            "glasses": "eyeglasses",
            "machine": "gearshape.fill",
            "electronics": "cpu.fill",
            "consumer": "cpu.fill"
        ]
        
        // Find matching icon
        for (key, icon) in iconMap {
            if lowercased.contains(key) {
                return icon
            }
        }
        
        // Default icon
        return "cube.fill"
    }
}

// MARK: - Voice Command Button

/// Button for activating voice commands with proper accessibility support
struct VoiceCommandButton: View {
    @ObservedObject var voiceCommandManager: VoiceCommandManager
    
    var body: some View {
        Button(action: toggleRecording) {
            VStack(spacing: 4) {
                Image(systemName: buttonIcon)
                    .font(.largeTitle)
                
                if voiceCommandManager.isRecording {
                    Text("Listening...")
                        .font(.caption)
                }
            }
            .padding()
            .background(buttonColor)
            .foregroundColor(.white)
            .clipShape(Circle())
            .shadow(radius: voiceCommandManager.isRecording ? 10 : 5)
            .scaleEffect(voiceCommandManager.isRecording ? 1.1 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: voiceCommandManager.isRecording)
        }
        .accessibilityLabel(voiceCommandManager.isRecording ? "Stop listening" : "Start voice command")
        .accessibilityHint(voiceCommandManager.isRecording ?
            "Double tap to stop voice recognition" :
            "Double tap to start voice recognition. Say find followed by an object name to search.")
        .accessibilityAddTraits(voiceCommandManager.isRecording ? .isSelected : [])
    }
    
    private func toggleRecording() {
        if voiceCommandManager.isRecording {
            voiceCommandManager.stopRecording()
        } else {
            voiceCommandManager.startRecording()
        }
    }
    
    private var buttonIcon: String {
        if voiceCommandManager.isRecording {
            return "mic.fill"
        } else if !voiceCommandManager.isAvailable {
            return "mic.slash"
        } else {
            return "mic"
        }
    }
    
    private var buttonColor: Color {
        if voiceCommandManager.isRecording {
            return .red
        } else if !voiceCommandManager.isAvailable {
            return .gray
        } else {
            return .blue
        }
    }
}

#Preview {
    ContentView()
}

