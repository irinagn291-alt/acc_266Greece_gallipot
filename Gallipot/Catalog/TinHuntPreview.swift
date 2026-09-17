import AVFoundation
import CoreMedia
import SwiftUI
import UIKit
import Vision

/// The only UIViewRepresentable. Owns AVCaptureVideoPreviewLayer for tin codes.
struct TinHuntPreview: UIViewRepresentable {
    var isActive: Bool
    var onPayload: @MainActor (String) -> Void

    func makeCoordinator() -> TinHuntBroker {
        TinHuntBroker()
    }

    func makeUIView(context: Context) -> TinHuntView {
        let view = TinHuntView()
        let layer = AVCaptureVideoPreviewLayer(session: context.coordinator.session)
        layer.videoGravity = .resizeAspectFill
        view.preview = layer
        view.layer.addSublayer(layer)
        context.coordinator.attachPreview(layer)
        return view
    }

    func updateUIView(_ uiView: TinHuntView, context: Context) {
        context.coordinator.onPayload = { payload in
            Task { @MainActor in
                onPayload(payload)
            }
        }
        uiView.preview?.frame = uiView.bounds
        if isActive {
            context.coordinator.start()
        } else {
            context.coordinator.stop()
        }
    }

    static func dismantleUIView(_ uiView: TinHuntView, coordinator: TinHuntBroker) {
        coordinator.stop()
    }
}

final class TinHuntView: UIView {
    var preview: AVCaptureVideoPreviewLayer?

    override func layoutSubviews() {
        super.layoutSubviews()
        preview?.frame = bounds
        if let connection = preview?.connection, connection.isVideoRotationAngleSupported(90) {
            connection.videoRotationAngle = 90
        }
    }
}

/// Capture session lives on a dedicated queue. The representable is the sole owner.
final class TinHuntBroker: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, @unchecked Sendable {
    let session = AVCaptureSession()
    var onPayload: ((String) -> Void)?

    private let queue = DispatchQueue(label: "gallipot.tinhunt")
    private var configured = false
    private var frameIndex = 0
    private var lastFire: CFTimeInterval = 0
    private weak var preview: AVCaptureVideoPreviewLayer?

    func attachPreview(_ layer: AVCaptureVideoPreviewLayer) {
        preview = layer
    }

    func start() {
        queue.async { [weak self] in
            guard let self else { return }
            self.configureIfNeeded()
            if !self.session.isRunning {
                self.session.startRunning()
            }
        }
    }

    func stop() {
        queue.async { [weak self] in
            guard let self, self.session.isRunning else { return }
            self.session.stopRunning()
        }
    }

    private func configureIfNeeded() {
        guard !configured else { return }
        session.beginConfiguration()
        defer {
            session.commitConfiguration()
            configured = true
        }
        session.sessionPreset = session.canSetSessionPreset(.hd1280x720) ? .hd1280x720 : .high
        guard let device = AVCaptureDevice.default(for: .video) else { return }
        do {
            let input = try AVCaptureDeviceInput(device: device)
            if session.canAddInput(input) {
                session.addInput(input)
            }
        } catch {
            return
        }
        if device.isFocusModeSupported(.continuousAutoFocus) || device.isExposureModeSupported(.continuousAutoExposure) {
            do {
                try device.lockForConfiguration()
                if device.isFocusModeSupported(.continuousAutoFocus) {
                    device.focusMode = .continuousAutoFocus
                }
                if device.isExposureModeSupported(.continuousAutoExposure) {
                    device.exposureMode = .continuousAutoExposure
                }
                device.unlockForConfiguration()
            } catch {
                // Default focus remains if the device rejects the lock.
            }
        }
        let output = AVCaptureVideoDataOutput()
        output.alwaysDiscardsLateVideoFrames = true
        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        output.setSampleBufferDelegate(self, queue: queue)
        if session.canAddOutput(output) {
            session.addOutput(output)
        }
        if let connection = output.connection(with: .video), connection.isVideoRotationAngleSupported(90) {
            connection.videoRotationAngle = 90
        }
    }

    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        frameIndex += 1
        guard frameIndex % 3 == 0 else { return }
        let now = CACurrentMediaTime()
        guard now - lastFire >= StillroomMeasure.huntCooldown else { return }
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let request = VNDetectBarcodesRequest { [weak self] request, error in
            guard error == nil,
                  let results = request.results as? [VNBarcodeObservation],
                  let payload = results.first?.payloadStringValue
            else { return }
            guard let self else { return }
            self.lastFire = CACurrentMediaTime()
            DispatchQueue.main.async {
                self.onPayload?(payload)
            }
        }
        request.symbologies = [.qr, .ean13, .ean8, .upce, .code128, .code39, .code93]
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .right, options: [:])
        do {
            try handler.perform([request])
        } catch {
            return
        }
    }
}
