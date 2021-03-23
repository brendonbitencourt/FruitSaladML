//
//  ViewController.swift
//  FruitSaladML
//
//  Created by Brendon Bitencourt Braga on 2021-03-22.
//

import UIKit
import CoreML
import Vision

class ViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var classificationLabel: UILabel!
    
    // MARK: - Variable
    lazy var classificationRequest: VNCoreMLRequest = {
        do {
            let config = MLModelConfiguration()
            let model = try VNCoreMLModel(for: FruitClassifier(configuration: config).model)
            let request = VNCoreMLRequest(model: model) { (request, error) in
                self.processClassifications(for: request, error: error)
            }
            request.imageCropAndScaleOption = .centerCrop
            return request
        } catch {
            fatalError(error.localizedDescription)
        }
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    @IBAction func cameraButtonClicked(_ sender: Any) {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            presentPhotoPicker(sourceType: .photoLibrary)
            return
        }
        
        let photoSourcePicker = UIAlertController()
        let takePhotoAction = UIAlertAction(title: "Take Photo", style: .default) { _ in
            self.presentPhotoPicker(sourceType: .camera)
        }
        let choosePhotoAction = UIAlertAction(title: "Choose Photo", style: .default) { _ in
            self.presentPhotoPicker(sourceType: .photoLibrary)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        photoSourcePicker.addAction(takePhotoAction)
        photoSourcePicker.addAction(choosePhotoAction)
        photoSourcePicker.addAction(cancelAction)
        
        present(photoSourcePicker, animated: true, completion: nil)
    }
    
    private func presentPhotoPicker(sourceType: UIImagePickerController.SourceType) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = sourceType
        present(picker, animated: true, completion: nil)
    }
    
    private func processClassifications(for request: VNRequest, error: Error?) {
        guard let classifications = request.results as? [VNClassificationObservation] else {
            self.classificationLabel.text = "Unable to classify image.\n\(error?.localizedDescription ?? "Error")"
            return
        }
        
        if classifications.isEmpty {
            self.classificationLabel.text = "Nothing recognized.\nPlease try again."
        } else {
            let topClassifications = classifications.prefix(2)
            let descriptions = topClassifications.map { (classification) in
                return String(format: "%.2f", classification.confidence * 100) + "% - " + classification.identifier
            }
            
            self.classificationLabel.text = "Classification:\n" + descriptions.joined(separator: "\n")
        }
    }
    
    private func updateClassification(for image: UIImage) {
        classificationLabel.text = "Classifying..."
        
        let orientationRawValue = UInt32(image.imageOrientation.rawValue)
        guard
            let orientation = CGImagePropertyOrientation(rawValue: orientationRawValue),
            let ciImage = CIImage(image: image) else { return }
        
        let handler = VNImageRequestHandler(ciImage: ciImage, orientation: orientation)
        do {
            try handler.perform([classificationRequest])
        } catch {
            print(error.localizedDescription)
        }
    }
}

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        picker.dismiss(animated: true, completion: nil)
        
        if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            imageView.image = image
            updateClassification(for: image)
        }
    }
    
}

