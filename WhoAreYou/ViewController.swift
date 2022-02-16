//
//  ViewController.swift
//  WhoAreYou
//
//  Created by Nikita Petrov on 27-07-2019.
//  Copyright © 2019 M'haimdat omar. All rights reserved.
//

import UIKit
import AVKit
import Vision
import ARKit
import CoreML
import SceneKit

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate, ARSessionDelegate, UINavigationControllerDelegate  {
    
    // Основная сцена представления
    private let sceneView = ARSCNView(frame: UIScreen.main.bounds)
    // Флаг - покан алер или нет
    private var isShowAlert: Bool = false
    // Массив с данными
    private var infos: [InfoModel] = []
    // Модель для определения по фото
    private var faceModel: WhoAreYouTestModel!
    // Кнопка выбора фото
    private let button: UIButton = UIButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.getInfos() // Получение данных из json

        self.view.addSubview(sceneView)  // Добавление сцены в subview
        self.setButton()  // Метод установки кнопки
        self.sceneView.delegate = self // Установка делегата для view controller
        // sceneView.showsStatistics = true // Отображение статистики
        
        guard ARFaceTrackingConfiguration.isSupported else { return } // Эта конфигурация дает доступ к фронтальной камере TrueDepth
        let configuration = ARFaceTrackingConfiguration()
        configuration.isLightEstimationEnabled = true
        self.sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.faceModel = try? WhoAreYouTestModel(configuration: MLModelConfiguration.init())
    }
    
    // Действие при нажатии на кнопку
    @objc func buttonTap(_ sender: Any) {
        let picker = UIImagePickerController()
        picker.allowsEditing = false
        picker.delegate = self
        picker.sourceType = .photoLibrary
        present(picker, animated: true)
    }
    
    // Установка кнопки
    private func setButton() {
        self.button.backgroundColor = .white
        self.button.layer.cornerRadius = 16
        self.button.layer.borderWidth = 2
        self.button.layer.borderColor = UIColor(ciColor: .white).cgColor
        self.button.setTitle("Выбрать фото", for: .normal)
        self.button.setTitleColor(.black, for: .normal)
        self.button.addTarget(self, action: #selector(buttonTap(_:)), for: .touchUpInside)
        self.sceneView.addSubview(button)
        self.button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.button.topAnchor.constraint(equalTo: self.sceneView.topAnchor, constant: 50),
            self.button.leadingAnchor.constraint(equalTo: self.sceneView.leadingAnchor, constant: 50),
            self.button.trailingAnchor.constraint(equalTo: self.sceneView.trailingAnchor, constant: -50),
            self.button.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    
    // Получение данных из json
    private func getInfos() {
        guard let jsonUrl = Bundle.main.url(forResource: "Data", withExtension: "json") else {
            print("Файл не существует: Data.json")
            return
        }
        
        guard let json = try? String(contentsOf: jsonUrl, encoding: .utf8) else {
            print("Невозможно загрузить файл: \(jsonUrl)")
            return
        }
        
        let data = Data(json.utf8)
        do {
            if let jsonModel = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] {
                self.infos = jsonModel.compactMap({InfoModel(json: $0)})
            }
        } catch {
            print("Ошибка")
        }
    }
}

extension ViewController: ARSCNViewDelegate {
    
    // Обнаружение лица
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        if !self.isShowAlert {
            guard let device = sceneView.device else {
                return nil
            }
            
            let faceGeometry = ARSCNFaceGeometry(device: device)
            let node = SCNNode(geometry: faceGeometry)
            node.geometry?.firstMaterial?.fillMode = .lines
            return node
        }
        return nil
    }
    
    // Обновление сцены
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        if !self.isShowAlert {
            guard let faceAnchor = anchor as? ARFaceAnchor,
                  let faceGeometry = node.geometry as? ARSCNFaceGeometry else {
                return
            }
            
            faceGeometry.update(from: faceAnchor.geometry)
            
            // Добавляем фреймы в модель
            guard let model = try? VNCoreMLModel(for: self.faceModel.model) else {
                fatalError("Unable to load model")
            }
            
            let coreMlRequest = VNCoreMLRequest(model: model) {[weak self] request, error in
                guard let results = request.results as? [VNClassificationObservation],
                      let topResult = results.first
                else {
                    fatalError("Unexpected results")
                }
                
                var identifier = topResult.identifier
                if topResult.confidence < 0.69 {
                    identifier = "Unknown"
                }
                
                DispatchQueue.main.async {[weak self] in
                    results.forEach({
                        print($0.identifier)
                        print($0.confidence)
                    })
                    guard let strongSelf = self else { return }
                    strongSelf.isShowAlert = true
                    // Отображение основной информации 
                    strongSelf.showAlert(identifier: identifier, infos: strongSelf.infos, handler: {_ in
                        self?.isShowAlert = false
                    })
                }
            }
            
            // Получаем фреймы с камеры
            guard let pixelBuffer = self.sceneView.session.currentFrame?.capturedImage else { return }
            
            
            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
            DispatchQueue.global().async {
                do {
                    try handler.perform([coreMlRequest])
                } catch {
                    print(error)
                }
            }
        }
    }
}

// Обработка галерии при выборе изображения
extension ViewController: UIImagePickerControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        
        /// рендеринг изображения для НС
        guard let image = info[UIImagePickerController.InfoKey(rawValue: "UIImagePickerControllerOriginalImage")] as? UIImage else { return }
        /// Создает графический контекст на основе растровых изображений с указанными параметрами
        UIGraphicsBeginImageContextWithOptions(CGSize(width: 227, height: 227), true, 2.0)
        /// Рисуем изображение приемника в переданном прямоугольнике.
        image.draw(in: CGRect(x: 0, y: 0, width: 227, height: 227))
        /// Возвращаем изображение из содержимого текущего графического контекста на основе растровых изображений.
        let newImage = UIGraphicsGetImageFromCurrentImageContext()!
        /// Удаляем текущий графический контекст на основе растровых изображений из верхней части стека.
        UIGraphicsEndImageContext()
        
        /// kCVPixelBufferCGImageCompatibilityKey - Логическое значение, указывающее, совместим ли пиксельный буфер с типами CGImage.
        /// kCVPixelBufferCGBitmapContextCompatibilityKey - Логическое значение, указывающее, совместим ли пиксельный буфер с контекстами растрового изображения Core Graphics
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        /// Буфер изображения, который содержит пиксели в основной памяти.
        var pixerBuffer: CVPixelBuffer?
        /// Создается буфер с одним пикселем для заданного размера и пиксельного формата.
        let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(newImage.size.width), Int(newImage.size.height), kCVPixelFormatType_32ARGB, attrs, &pixerBuffer)
        /// Проверяем статус
        guard (status == kCVReturnSuccess) else {
            return
        }
        
        /// Блокируем базовый адрес пиксельного буфера.
        CVPixelBufferLockBaseAddress(pixerBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(pixerBuffer!)
        
        /// Создаем зависимое от устройства цветовое пространство RGB.
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: pixelData, width: Int(newImage.size.width), height: Int(newImage.size.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixerBuffer!), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
        
        context?.translateBy(x: 0, y: newImage.size.height)
        context?.scaleBy(x: 1.0, y: -1.0)
        /// Делаем указанный графический контекст текущим контекстом.
        UIGraphicsPushContext(context!)
        newImage.draw(in: CGRect(x: 0, y: 0, width: newImage.size.width, height: newImage.size.height))
        /// Удаляет текущий графический контекст из верхней части стека, восстанавливая предыдущий контекст.
        UIGraphicsPopContext()
        /// Разблокируем базовый адрес пиксельного буфера.
        CVPixelBufferUnlockBaseAddress(pixerBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        
        /// результат
        guard let prediction = try? self.faceModel.prediction(image: pixerBuffer!) else {
            return
        }
        self.isShowAlert = true
        self.showAlert(identifier: prediction.classLabel, infos: self.infos, handler: {_ in
            self.isShowAlert = false
        })
    }
}
