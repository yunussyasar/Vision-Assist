//
//  ObjectDetector.swift
//  VisionAssist
//
//  Real-time object detection using Apple Vision Framework
//

import Foundation
import UIKit
import Vision
import CoreML
import AVFoundation
import Combine

// MARK: - DetectedObject Model

/// Represents a detected object with its properties
struct DetectedObject: Identifiable, Equatable {
    let id = UUID()
    let label: String
    let confidence: Float
    let boundingBox: CGRect
    let spatialPosition: String
    
    static func == (lhs: DetectedObject, rhs: DetectedObject) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - ObjectDetector

/// Handles real-time object detection using Vision Framework
class ObjectDetector: ObservableObject {
    
    // MARK: - Published Properties
    
    /// List of currently detected objects (smoothed)
    @Published var detectedObjects: [DetectedObject] = []
    
    /// The object being searched for (voice command target)
    @Published var targetObject: String? = nil {
        didSet {
            if targetObject != oldValue {
                // Reset state when target changes
                isTargetFound = false
                hasAnnouncedTargetFound = false
                audioManager.resetAnnouncements()
                
                // Announce new search target
                if let target = targetObject {
                    audioManager.setSearchTarget(target)
                }
            }
        }
    }
    
    /// Whether the target object has been found
    @Published var isTargetFound: Bool = false
    
    /// Confidence threshold for detections (0.0 - 1.0)
    @Published var confidenceThreshold: Float = 0.4
    
    // MARK: - Private Properties
    
    /// Maximum number of objects to track
    private let maxDetections = 5
    
    /// Frame processing queue
    private let processingQueue = DispatchQueue(label: "com.visionassist.objectdetection", qos: .userInitiated)
    
    /// Flag to prevent concurrent processing
    private var isProcessing = false
    
    /// Input image size for coordinate conversion
    private var inputSize: CGSize = .zero
    
    /// Haptic feedback manager (singleton)
    private let hapticManager = HapticFeedbackManager.shared
    
    /// Audio feedback manager
    private let audioManager = AudioFeedbackManager()
    
    /// Flag to track if we've announced finding the target
    private var hasAnnouncedTargetFound = false
    
    /// Detection history for smoothing
    private var detectionHistory: [[String: Int]] = []
    private let historySize = 5
    
    /// Last stable detections
    private var stableDetections: [String: DetectedObject] = [:]
    
    /// Frame skip counter (process every N frames)
    private var frameCounter = 0
    private let frameSkip = 3  // Process every 3rd frame
    
    // MARK: - Initialization
    
    init() {
        print("ObjectDetector initialized with Vision Framework")
    }
    
    // MARK: - Frame Processing
    
    /// Processes a camera frame for object detection
    /// - Parameter pixelBuffer: The camera frame pixel buffer
    func processFrame(_ pixelBuffer: CVPixelBuffer) {
        // Skip frames to reduce flickering
        frameCounter += 1
        guard frameCounter >= frameSkip else { return }
        frameCounter = 0
        
        guard !isProcessing else { return }
        
        isProcessing = true
        
        processingQueue.async { [weak self] in
            self?.detectObjects(in: pixelBuffer)
        }
    }
    
    /// Detects objects in the given pixel buffer
    private func detectObjects(in pixelBuffer: CVPixelBuffer) {
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        inputSize = CGSize(width: width, height: height)
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .right, options: [:])
        
        // Use classification request for general object detection
        let classificationRequest = VNClassifyImageRequest { [weak self] request, error in
            self?.handleClassificationResults(request: request, error: error)
        }
        
        do {
            try handler.perform([classificationRequest])
        } catch {
            print("Failed to perform detection: \(error.localizedDescription)")
        }
        
        isProcessing = false
    }
    
    /// Handles classification results with smoothing
    private func handleClassificationResults(request: VNRequest, error: Error?) {
        guard error == nil else { return }
        
        guard let results = request.results as? [VNClassificationObservation] else {
            return
        }
        
        // Get top classifications that meet threshold
        let topResults = results.prefix(10).filter { $0.confidence >= confidenceThreshold }
        
        // Build current frame detections
        var currentFrameLabels: [String: Int] = [:]
        for classification in topResults {
            let label = classification.identifier.capitalized
                .replacingOccurrences(of: "_", with: " ")
            currentFrameLabels[label] = 1
        }
        
        // Add to history
        detectionHistory.append(currentFrameLabels)
        if detectionHistory.count > historySize {
            detectionHistory.removeFirst()
        }
        
        // Calculate stable detections (appear in majority of recent frames)
        var labelCounts: [String: Int] = [:]
        for frame in detectionHistory {
            for label in frame.keys {
                labelCounts[label, default: 0] += 1
            }
        }
        
        // Only keep detections that appear in at least 60% of recent frames
        let threshold = Int(Double(historySize) * 0.6)
        var stableLabels: Set<String> = []
        for (label, count) in labelCounts where count >= threshold {
            stableLabels.insert(label)
        }
        
        // Build smoothed detection list
        var smoothedDetections: [DetectedObject] = []
        
        for classification in topResults {
            let label = classification.identifier.capitalized
                .replacingOccurrences(of: "_", with: " ")
            
            guard stableLabels.contains(label) else { continue }
            
            let position = calculateSpatialPosition(label: label)
            
            let detectedObject = DetectedObject(
                label: label,
                confidence: classification.confidence,
                boundingBox: CGRect(x: 0.3, y: 0.3, width: 0.4, height: 0.4),
                spatialPosition: position
            )
            
            stableDetections[label] = detectedObject
            smoothedDetections.append(detectedObject)
            
            if smoothedDetections.count >= maxDetections {
                break
            }
        }
        
        updateDetections(smoothedDetections)
    }
    
    /// Updates detected objects on main thread
    private func updateDetections(_ newDetections: [DetectedObject]) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Only update if there's a meaningful change
            let oldLabels = Set(self.detectedObjects.map { $0.label })
            let newLabels = Set(newDetections.map { $0.label })
            
            if oldLabels != newLabels {
                self.detectedObjects = newDetections
            }
            
            // Check if target object is found
            self.checkForTargetObject()
        }
    }
    
    /// Checks if the target object has been found and provides feedback
    private func checkForTargetObject() {
        guard let target = targetObject else {
            isTargetFound = false
            return
        }
        
        // Find matching object
        let matchingObject = detectedObjects.first { object in
            object.label.lowercased().contains(target.lowercased()) ||
            target.lowercased().contains(object.label.lowercased())
        }
        
        let found = matchingObject != nil
        let wasFound = isTargetFound
        
        // Update state
        isTargetFound = found
        
        // Handle state transitions
        if found && !wasFound {
            // Just found the target!
            print("🎯 TARGET FOUND: \(target)")
            
            if let object = matchingObject {
                // Announce with position - this is first find!
                audioManager.announceTargetFound(object: object, isFirstFind: true)
                hapticManager.triggerSuccessFeedback()
            }
        } else if !found && wasFound {
            // Lost the target
            print("❌ TARGET LOST: \(target)")
            audioManager.announceTargetLost(objectLabel: target)
        }
    }
    
    // MARK: - Spatial Position Calculation
    
    /// Calculates spatial position for classification (center-based estimation)
    private func calculateSpatialPosition(label: String) -> String {
        // For classification, we don't have exact bounding boxes
        // Return "center" as default position
        return "center"
    }
    
    /// Calculates spatial position description from bounding box
    private func calculateSpatialPosition(boundingBox: CGRect) -> String {
        let centerX = boundingBox.midX
        let centerY = boundingBox.midY
        
        var horizontal: String
        var vertical: String
        
        if centerX < 0.33 {
            horizontal = "left"
        } else if centerX > 0.67 {
            horizontal = "right"
        } else {
            horizontal = "center"
        }
        
        if centerY < 0.33 {
            vertical = "bottom"
        } else if centerY > 0.67 {
            vertical = "top"
        } else {
            vertical = "middle"
        }
        
        if horizontal == "center" && vertical == "middle" {
            return "center"
        } else if horizontal == "center" {
            return vertical
        } else if vertical == "middle" {
            return horizontal
        } else {
            return "\(vertical) \(horizontal)"
        }
    }
    
    // MARK: - Configuration
    
    /// Sets the confidence threshold for detections
    func setConfidenceThreshold(_ threshold: Float) {
        confidenceThreshold = max(0.0, min(1.0, threshold))
    }
    
    /// Clears the current target object
    func clearTarget() {
        targetObject = nil
        isTargetFound = false
        hasAnnouncedTargetFound = false
    }
}
