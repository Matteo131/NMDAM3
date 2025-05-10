//
//  QRCodeScannerView.swift
//  NMDA MARK 3
//
//  Created by Matteo Ricci on 04/05/2025.
//

import SwiftUI
import AVFoundation

struct QRCodeScannerView: View {
    @Environment(\.presentationMode) var presentationMode
    var onCodeScanned: (String) -> Void
    
    @State private var isScanning = true
    
    var body: some View {
        ZStack {
            QRCodeScannerRepresentable(
                isScanning: $isScanning,
                onCodeFound: { code in
                    onCodeScanned(code)
                    presentationMode.wrappedValue.dismiss()
                }
            )
            .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Cancel")
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(8)
                }
                .padding(.bottom, 40)
            }
        }
        .onDisappear {
            isScanning = false
        }
    }
}

struct QRCodeScannerRepresentable: UIViewControllerRepresentable {
    @Binding var isScanning: Bool
    var onCodeFound: (String) -> Void
    
    func makeUIViewController(context: Context) -> QRScannerController {
        let controller = QRScannerController()
        controller.delegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: QRScannerController, context: Context) {
        if isScanning {
            uiViewController.startScanning()
        } else {
            uiViewController.stopScanning()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, QRScannerControllerDelegate {
        var parent: QRCodeScannerRepresentable
        
        init(_ parent: QRCodeScannerRepresentable) {
            self.parent = parent
        }
        
        func qrScanningDidFail() {
            // Handle failure
        }
        
        func qrScanningSucceededWithCode(_ code: String) {
            parent.onCodeFound(code)
        }
        
        func qrScanningDidStop() {
            parent.isScanning = false
        }
    }
}

protocol QRScannerControllerDelegate: AnyObject {
    func qrScanningDidFail()
    func qrScanningSucceededWithCode(_ code: String)
    func qrScanningDidStop()
}

class QRScannerController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var captureSession: AVCaptureSession?
    var previewLayer: AVCaptureVideoPreviewLayer?
    weak var delegate: QRScannerControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCaptureSession()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startScanning()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopScanning()
    }
    
    func setupCaptureSession() {
        let captureSession = AVCaptureSession()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video),
              let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice),
              captureSession.canAddInput(videoInput) else {
            delegate?.qrScanningDidFail()
            return
        }
        
        captureSession.addInput(videoInput)
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            delegate?.qrScanningDidFail()
            return
        }
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        self.captureSession = captureSession
        self.previewLayer = previewLayer
    }
    
    func startScanning() {
        if let captureSession = captureSession, !captureSession.isRunning {
            captureSession.startRunning()
        }
    }
    
    func stopScanning() {
        if let captureSession = captureSession, captureSession.isRunning {
            captureSession.stopRunning()
            delegate?.qrScanningDidStop()
        }
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if let metadataObject = metadataObjects.first,
           let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
           let stringValue = readableObject.stringValue {
            
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            delegate?.qrScanningSucceededWithCode(stringValue)
        }
    }
}
