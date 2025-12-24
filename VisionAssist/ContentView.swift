import SwiftUI

struct ContentView: View {
    @StateObject private var cameraManager = CameraManager()
    @StateObject private var objectDetector = ObjectDetector()
    @StateObject private var voiceCommandManager = VoiceCommandManager()
    
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
                
                // MARK: - Detected Objects List
                ForEach(objectDetector.detectedObjects) { object in
                    DetectedObjectRow(object: object, isTarget: isTargetObject(object))
                }
                .padding(.bottom, 20)
                
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
    }
    
    /// Check if a detected object matches the current search target
    private func isTargetObject(_ object: DetectedObject) -> Bool {
        guard let target = objectDetector.targetObject else { return false }
        return object.label.lowercased().contains(target.lowercased())
    }
}

// MARK: - Detected Object Row

/// A row displaying a detected object with its confidence level
struct DetectedObjectRow: View {
    let object: DetectedObject
    let isTarget: Bool
    
    var body: some View {
        HStack {
            if isTarget {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
            }
            
            Text(object.label)
                .bold()
            
            Spacer()
            
            Text(object.spatialPosition.capitalized)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.2))
                .cornerRadius(4)
            
            Text("\(Int(object.confidence * 100))%")
                .font(.caption)
        }
        .padding()
        .background(isTarget ? Color.green.opacity(0.7) : Color.black.opacity(0.5))
        .foregroundColor(.white)
        .cornerRadius(8)
        .padding(.horizontal)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(object.label), \(object.spatialPosition), \(Int(object.confidence * 100)) percent confidence\(isTarget ? ", target found" : "")")
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

