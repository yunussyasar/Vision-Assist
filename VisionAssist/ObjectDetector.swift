//
//  ObjectDetector.swift
//  VisionAssist
//
//  Real-time object detection using Apple Vision Framework & Custom YOLO Model
//  Optimized for thermal efficiency on iPhone 12 Pro
//

import Foundation
import UIKit
import Vision
import CoreML
import AVFoundation
import Combine

// MARK: - DetectedObject Model

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

class ObjectDetector: ObservableObject {
    
    // MARK: - Published Properties
    @Published var detectedObjects: [DetectedObject] = []
    @Published var isTargetFound: Bool = false
    
    /// Confidence threshold from settings
    private var confidenceThreshold: Float {
        Float(SettingsManager.shared.confidenceThreshold)
    }
    
    @Published var targetObject: String? = nil {
        didSet {
            if targetObject != oldValue {
                isTargetFound = false
                hasAnnouncedTargetFound = false
                audioManager.resetAnnouncements()
                if let target = targetObject {
                    audioManager.setSearchTarget(target)
                }
            }
        }
    }
    
    // MARK: - Private Properties
    private let maxDetections = 5
    private let processingQueue = DispatchQueue(label: "com.visionassist.objectdetection", qos: .userInitiated)
    private var isProcessing = false
    private var inputSize: CGSize = .zero
    private let hapticManager = HapticFeedbackManager.shared
    private let audioManager = AudioFeedbackManager()
    private var hasAnnouncedTargetFound = false
    
    // MARK: - Performance Optimization
    private var cachedVisionModel: VNCoreMLModel?
    private var frameCounter = 0
    private var adaptiveFrameSkip: Int = 5 // Default: ~6 FPS processing
    private var thermalStateObserver: NSObjectProtocol?
    
    // MARK: - Initialization
    init() {
        print("ObjectDetector initialized with Custom YOLO Model")
        setupModel()
        observeThermalState()
    }
    
    deinit {
        if let observer = thermalStateObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    // MARK: - Model Setup (One-time load)
    private func setupModel() {
        let config = MLModelConfiguration()
        // Use Neural Engine for power efficiency
        config.computeUnits = .cpuAndNeuralEngine
        
        guard let coreMLModel = try? best(configuration: config),
              let visionModel = try? VNCoreMLModel(for: coreMLModel.model) else {
            print("Failed to load model")
            return
        }
        
        cachedVisionModel = visionModel
        print("Model cached successfully with Neural Engine")
    }
    
    // MARK: - Thermal State Monitoring
    private func observeThermalState() {
        // Initial check
        updateFrameSkipForThermalState(ProcessInfo.processInfo.thermalState)
        
        // Observe changes
        thermalStateObserver = NotificationCenter.default.addObserver(
            forName: ProcessInfo.thermalStateDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            let state = ProcessInfo.processInfo.thermalState
            self?.updateFrameSkipForThermalState(state)
        }
    }
    
    private func updateFrameSkipForThermalState(_ state: ProcessInfo.ThermalState) {
        switch state {
        case .nominal:
            adaptiveFrameSkip = 5  // ~6 FPS - Normal operation
            print("Thermal: Nominal - Frame skip: 5")
        case .fair:
            adaptiveFrameSkip = 8  // ~4 FPS - Slightly warm
            print("Thermal: Fair - Frame skip: 8")
        case .serious:
            adaptiveFrameSkip = 12 // ~2.5 FPS - Getting hot
            print("Thermal: Serious - Frame skip: 12")
        case .critical:
            adaptiveFrameSkip = 20 // ~1.5 FPS - Very hot, minimal processing
            print("Thermal: Critical - Frame skip: 20")
        @unknown default:
            adaptiveFrameSkip = 10
        }
    }
    
    // MARK: - Frame Processing
    func processFrame(_ pixelBuffer: CVPixelBuffer) {
        frameCounter += 1
        guard frameCounter >= adaptiveFrameSkip else { return }
        frameCounter = 0
        
        guard !isProcessing else { return }
        guard cachedVisionModel != nil else { return }
        
        isProcessing = true
        
        processingQueue.async { [weak self] in
            self?.detectObjects(in: pixelBuffer)
        }
    }
    
    private func detectObjects(in pixelBuffer: CVPixelBuffer) {
        guard let visionModel = cachedVisionModel else {
            isProcessing = false
            return
        }
        
        let request = VNCoreMLRequest(model: visionModel) { [weak self] request, error in
            self?.handleDetectionResults(request: request, error: error)
        }
        
        // Scale image to fit model
        request.imageCropAndScaleOption = .scaleFill
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .right, options: [:])
        
        do {
            try handler.perform([request])
        } catch {
            print("Detection failed: \(error.localizedDescription)")
        }
        
        isProcessing = false
    }
    
    private func handleDetectionResults(request: VNRequest, error: Error?) {
        guard error == nil, let results = request.results as? [VNRecognizedObjectObservation] else { return }
        
        // Filter and transform
        let filteredResults = results.filter { $0.confidence >= confidenceThreshold }.prefix(maxDetections)
        
        let newDetections = filteredResults.map { observation -> DetectedObject in
            let label = observation.labels.first?.identifier.capitalized ?? "Unknown"
            let position = calculateSpatialPosition(boundingBox: observation.boundingBox)
            
            return DetectedObject(
                label: label,
                confidence: observation.confidence,
                boundingBox: observation.boundingBox,
                spatialPosition: position
            )
        }
        
        updateDetections(Array(newDetections))
    }
    
    private func updateDetections(_ newDetections: [DetectedObject]) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.detectedObjects = newDetections
            self.checkForTargetObject()
        }
    }
    
    private func checkForTargetObject() {
        guard let target = targetObject else {
            isTargetFound = false
            return
        }
        
        let matchingObject = detectedObjects.first { object in
            object.label.lowercased().contains(target.lowercased())
        }
        
        let found = matchingObject != nil
        let wasFound = isTargetFound
        isTargetFound = found
        
        if found && !wasFound {
            if let object = matchingObject {
                audioManager.announceTargetFound(object: object, isFirstFind: true)
                hapticManager.triggerSuccessFeedback()
            }
        } else if !found && wasFound {
            audioManager.announceTargetLost(objectLabel: target)
        }
    }
    
    // MARK: - Spatial Position Calculation
    private func calculateSpatialPosition(boundingBox: CGRect) -> String {
        let centerX = boundingBox.midX
        let centerY = boundingBox.midY
        
        var horizontal: String
        var vertical: String
        
        // Vision coordinates: 0.0 left/bottom, 1.0 right/top
        if centerX < 0.35 { horizontal = "sol" }
        else if centerX > 0.65 { horizontal = "sağ" }
        else { horizontal = "orta" }
        
        if centerY < 0.35 { vertical = "alt" }
        else if centerY > 0.65 { vertical = "üst" }
        else { vertical = "orta" }
        
        if horizontal == "orta" && vertical == "orta" { return "ortada" }
        else if horizontal == "orta" { return vertical }
        else if vertical == "orta" { return horizontal }
        else { return "\(vertical) \(horizontal)" }
    }
    

    
    func clearTarget() {
        targetObject = nil
        isTargetFound = false
        hasAnnouncedTargetFound = false
    }
}
