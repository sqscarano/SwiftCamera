//
//  ContentView.swift
//  SwiftCamera
//
//  Created by Rolando Rodriguez on 10/15/20.
//

import SwiftUI
import Combine
import AVFoundation

final class CameraModel: ObservableObject {
    private let service = CameraService()
    
    @Published var photo: Photo!
    
    @Published var foregroundImage: UIImage?
    
    @Published var backgroundImage: UIImage? = UIImage(named: "bg-9")
    
    @Published var showAlertError = false
    
    @Published var isFlashOn = false
    
    @Published var willCapturePhoto = false
    
    @Published var detectedText: String?
    
    @Published var isTextMode = false
    
    var alertError: AlertError!
    
    var session: AVCaptureSession
    
    let webSocketTask = URLSession.shared.webSocketTask(with: URL(string: "ws://192.168.86.29:8383")!)
    
    private var subscriptions = Set<AnyCancellable>()
    
    init() {
        self.session = service.session
        
        service.$photo.sink { [weak self] (photo) in
            guard let pic = photo else { return }
            self?.photo = pic
            
            pic.getForegroundImage() { [weak self] image in
                guard let image = image else { return }

                self?.foregroundImage = image

                pic.recognizeText(image: image) { [weak self] string in
                    self?.detectedText = string
                }
            }
        }
        .store(in: &self.subscriptions)
        
        service.$shouldShowAlertView.sink { [weak self] (val) in
            self?.alertError = self?.service.alertError
            self?.showAlertError = val
        }
        .store(in: &self.subscriptions)
        
        service.$flashMode.sink { [weak self] (mode) in
            self?.isFlashOn = mode == .on
        }
        .store(in: &self.subscriptions)
        
        service.$willCapturePhoto.sink { [weak self] (val) in
            self?.willCapturePhoto = val
        }
        .store(in: &self.subscriptions)
    }
    
    func configure() {
        service.checkForPermissions()
        service.configure()
    }
    
    func capturePhoto() {
        service.capturePhoto()
    }
    
    // MARK: WebSockets
    
    func pastePhoto(scale: CGFloat) {
        guard let foregroundImage = foregroundImage, let data = foregroundImage.pngData() else {
            return
        }

        var message = ""
        if let text = detectedText, isTextMode {
            let cleanText = text.replacingOccurrences(of: "\"", with: "\\\"")
            message = "{\"text\": \"\(cleanText)\"}"
        } else {
            let base64data = data.base64EncodedString()
            message = "{\"image\": \"\(base64data)\", \"scale\": \(scale)}"
        }
        
        webSocketTask.send(URLSessionWebSocketTask.Message.string(message)) { error in
            if let error = error {
                print("error: \(error)")
            }
        }

        readWebsocketMessage(webSocketTask: webSocketTask)
        webSocketTask.resume()
    }
    
    func readWebsocketMessage(webSocketTask: URLSessionWebSocketTask) {
        webSocketTask.receive { [weak self] result in
            switch result {
            case .failure(let error):
                print("error: \(error)")
            case .success(let message):
                switch message {
                case .string(let text):
                    print("received: \(text)")
                default:
                    fatalError()
                }
            }
            
            self?.readWebsocketMessage(webSocketTask: webSocketTask)
        }
    }
    
    func flipCamera() {
        service.changeCamera()
    }
    
    func zoom(with factor: CGFloat) {
        service.set(zoom: factor)
    }
    
    func resetForegroundImage() {
        foregroundImage = nil
        detectedText = ""
    }
    
    func switchFlash() {
        service.flashMode = service.flashMode == .on ? .off : .on
    }
    
    func switchTextMode() {
        isTextMode = !isTextMode
    }
}

struct CameraView: View {
    @StateObject var model = CameraModel()
    
    @State var scale: CGFloat = 0.8
    
    var captureButton: some View {
        Button(action: {
            if model.foregroundImage == nil {
                model.capturePhoto()
            } else {
                model.pastePhoto(scale: scale)
            }
            
            model.resetForegroundImage()
            scale = 0.8
            
        }, label: {
            Circle()
                .foregroundColor(.white)
                .frame(width: 80, height: 80, alignment: .center)
                .overlay(
                    Circle()
                        .stroke(Color.black.opacity(0.8), lineWidth: 2)
                        .frame(width: 65, height: 65, alignment: .center)
                )
        })
    }
    
    var capturedObjectImage: some View {
        Group {
            if let image = model.foregroundImage {
                Image(uiImage: image).resizable().aspectRatio(contentMode: .fill)
            } else {
                EmptyView()
            }
        }
    }
    
    var backgroundImage: some View {
        Group {
            if let image = model.backgroundImage, model.foregroundImage != nil {
                Image(uiImage: image).resizable().aspectRatio(contentMode: .fill)
            } else {
                EmptyView()
            }
        }
    }
    
    var flipCameraButton: some View {
        Button(action: {
            model.flipCamera()
        }, label: {
            Circle()
                .foregroundColor(Color.gray.opacity(0.2))
                .frame(width: 45, height: 45, alignment: .center)
                .overlay(
                    Image(systemName: "camera.rotate.fill")
                        .foregroundColor(.white))
        })
    }
    
    var placeholderImage: some View {
        Group {
            if model.foregroundImage == nil {
                Image(uiImage: UIImage(named: "can")!).resizable().aspectRatio(contentMode: .fill)
            }
            else {
                EmptyView()
            }
        }
    }
    
    var detectedText: some View {
        Group {
            if let text = model.detectedText {
                Text(text).font(.body).foregroundColor(.white).padding(20.0)
            } else {
                EmptyView()
            }
        }
    }
    
    var body: some View {
        GeometryReader { reader in
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                VStack {
                    HStack {
                        Spacer()

                        Button(action: {
                            model.switchTextMode()
                        }, label: {
                            Image(systemName: model.isTextMode ? "textformat.abc.dottedunderline" : "textformat.abc" )
                                .font(.system(size: 20, weight: .medium, design: .default))
                        })
                        .accentColor(model.isTextMode ? .yellow : .white)
                        .padding(20.0)
                    }
                    
                    CameraPreview(session: model.session)
                        .onAppear {
                            model.configure()
                        }
                        .alert(isPresented: $model.showAlertError, content: {
                            Alert(title: Text(model.alertError.title), message: Text(model.alertError.message), dismissButton: .default(Text(model.alertError.primaryButtonTitle), action: {
                                model.alertError.primaryAction?()
                            }))
                        })
                        .overlay(
                            Group {
                                if model.willCapturePhoto {
                                    Color.white
                                }
                                
                                if model.isTextMode {
                                    detectedText
                                } else {
                                    capturedObjectImage.scaleEffect(self.scale).draggable()
                                }
                            }
                        )
                        .animation(.linear)
                        .gesture(MagnificationGesture().onChanged { value in
                            self.scale = value.magnitude
                        })
                    
                    HStack {
                        captureButton
                    }
                    .padding(.horizontal, 20)
                }.onTapGesture {
                    model.resetForegroundImage()
                    scale = 0.8
                }

            }
        }
    }
}

struct DraggableView: ViewModifier {
    @State var offset = CGPoint(x: 0, y: 0)
    
    func body(content: Content) -> some View {
        content
            .gesture(DragGesture(minimumDistance: 0)
                .onChanged { value in
                self.offset.x = value.location.x - value.startLocation.x
                self.offset.y = value.location.y - value.startLocation.y
            })
            .offset(x: offset.x, y: offset.y)
    }
}

extension View {
    func draggable() -> some View {
        return modifier(DraggableView())
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            CameraView()
            CameraView()
        }
    }
}
