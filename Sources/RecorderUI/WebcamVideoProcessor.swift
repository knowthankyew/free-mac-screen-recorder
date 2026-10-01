import AVFoundation
import CoreGraphics
import CoreImage
import CoreImage.CIFilterBuiltins
import Foundation
import OSLog
import Vision

/// Processes real-time camera frames from `AVCaptureVideoDataOutput`,
/// executing Apple's native Neural Engine person segmentation, Core Image
/// compositing (blur, backdrop replacement, cutout), mirroring, and aspect cropping.
public final class WebcamVideoProcessor: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, @unchecked Sendable {

    private let log = Logger(subsystem: "com.freemacscreenrecorder.app", category: "WebcamProcessor")
    private let segmentationRequest: VNGeneratePersonSegmentationRequest
    private let lock = NSLock()

    // Configurable state
    public var backgroundMode: WebcamBackgroundMode = .none
    public var blurStrength: WebcamBlurStrength = .balanced
    public var backgroundPreset: WebcamBackgroundPreset = .warmStudio
    public var customImageURL: URL? {
        didSet {
            if customImageURL != oldValue {
                lock.lock()
                cachedCustomImage = nil
                lock.unlock()
            }
        }
    }
    public var mirrored: Bool = true

    public weak var renderView: WebcamMetalView?

    // Cache
    private var cachedCustomImage: CIImage?
    private var cachedPresetImage: CIImage?
    private var lastCachedPreset: WebcamBackgroundPreset?
    private var lastCachedPresetSize: CGSize = .zero

    public override init() {
        let req = VNGeneratePersonSegmentationRequest()
        req.qualityLevel = .balanced
        req.outputPixelFormat = kCVPixelFormatType_OneComponent8
        self.segmentationRequest = req
        super.init()
    }

    // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

    public func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let sourceImage = CIImage(cvPixelBuffer: pixelBuffer)
        let sourceExtent = sourceImage.extent
        guard sourceExtent.width > 0 && sourceExtent.height > 0 else { return }

        let minDim = min(sourceExtent.width, sourceExtent.height)
        let cropRect = CGRect(
            x: (sourceExtent.width - minDim) / 2.0,
            y: (sourceExtent.height - minDim) / 2.0,
            width: minDim,
            height: minDim
        )

        // Read current settings under lock
        lock.lock()
        let mode = self.backgroundMode
        let strength = self.blurStrength
        let preset = self.backgroundPreset
        let customURL = self.customImageURL
        let isMirrored = self.mirrored
        lock.unlock()

        let squareSource = sourceImage
            .cropped(to: cropRect)
            .transformed(by: CGAffineTransform(translationX: -cropRect.origin.x, y: -cropRect.origin.y))

        let finalImage: CIImage

        if mode == .none {
            // Passthrough with zero segmentation overhead
            finalImage = applyMirror(image: squareSource, width: minDim, mirrored: isMirrored)
        } else {
            // Perform Neural Engine / GPU person segmentation
            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
            do {
                try handler.perform([segmentationRequest])
            } catch {
                log.error("Person segmentation failed: \(error.localizedDescription, privacy: .public)")
                finalImage = applyMirror(image: squareSource, width: minDim, mirrored: isMirrored)
                renderView?.update(image: finalImage)
                return
            }

            guard let maskPixelBuffer = segmentationRequest.results?.first?.pixelBuffer else {
                finalImage = applyMirror(image: squareSource, width: minDim, mirrored: isMirrored)
                renderView?.update(image: finalImage)
                return
            }

            let maskImage = CIImage(cvPixelBuffer: maskPixelBuffer)
            let scaleX = sourceExtent.width / maskImage.extent.width
            let scaleY = sourceExtent.height / maskImage.extent.height
            let scaledMask = maskImage
                .transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
                .cropped(to: cropRect)
                .transformed(by: CGAffineTransform(translationX: -cropRect.origin.x, y: -cropRect.origin.y))

            // Build target background
            let background = resolveBackground(
                mode: mode,
                strength: strength,
                preset: preset,
                customURL: customURL,
                squareSource: squareSource,
                size: CGSize(width: minDim, height: minDim)
            )

            // Blend foreground person over background using the matte mask
            let blendFilter = CIFilter.blendWithMask()
            blendFilter.inputImage = squareSource
            blendFilter.backgroundImage = background
            blendFilter.maskImage = scaledMask

            let composited = blendFilter.outputImage ?? squareSource
            finalImage = applyMirror(image: composited, width: minDim, mirrored: isMirrored)
        }

        renderView?.update(image: finalImage)
    }

    // MARK: - Helpers

    private func applyMirror(image: CIImage, width: CGFloat, mirrored: Bool) -> CIImage {
        guard mirrored else { return image }
        return image
            .transformed(by: CGAffineTransform(scaleX: -1, y: 1))
            .transformed(by: CGAffineTransform(translationX: width, y: 0))
    }

    private func resolveBackground(
        mode: WebcamBackgroundMode,
        strength: WebcamBlurStrength,
        preset: WebcamBackgroundPreset,
        customURL: URL?,
        squareSource: CIImage,
        size: CGSize
    ) -> CIImage {
        switch mode {
        case .none:
            return squareSource

        case .blur:
            let blur = CIFilter.gaussianBlur()
            blur.inputImage = squareSource.clampedToExtent()
            blur.radius = Float(strength.sigma)
            return blur.outputImage?.cropped(to: squareSource.extent) ?? squareSource

        case .preset:
            lock.lock()
            if let cached = cachedPresetImage, lastCachedPreset == preset, lastCachedPresetSize == size {
                lock.unlock()
                return cached
            }
            lock.unlock()

            let generated = preset.makeImage(size: size)
            lock.lock()
            cachedPresetImage = generated
            lastCachedPreset = preset
            lastCachedPresetSize = size
            lock.unlock()
            return generated

        case .customImage:
            if let url = customURL {
                lock.lock()
                if let cached = cachedCustomImage {
                    lock.unlock()
                    return cached
                }
                lock.unlock()

                if let loaded = CIImage(contentsOf: url) {
                    let extent = loaded.extent
                    let scale = max(size.width / extent.width, size.height / extent.height)
                    let scaled = loaded
                        .transformed(by: CGAffineTransform(translationX: -extent.origin.x, y: -extent.origin.y))
                        .transformed(by: CGAffineTransform(scaleX: scale, y: scale))
                    let cropOriginX = (scaled.extent.width - size.width) / 2.0
                    let cropOriginY = (scaled.extent.height - size.height) / 2.0
                    let centered = scaled
                        .cropped(to: CGRect(x: cropOriginX, y: cropOriginY, width: size.width, height: size.height))
                        .transformed(by: CGAffineTransform(translationX: -cropOriginX, y: -cropOriginY))

                    lock.lock()
                    cachedCustomImage = centered
                    lock.unlock()
                    return centered
                }
            }
            // Fallback to warm studio preset if image could not be loaded
            return WebcamBackgroundPreset.warmStudio.makeImage(size: size)

        case .cutout:
            return CIImage(color: CIColor(red: 0, green: 0, blue: 0, alpha: 0)).cropped(to: squareSource.extent)
        }
    }
}
