import UIKit
import Vision

class ViewController: UIViewController {

    @IBOutlet weak var buttonCamera: UIButton!
    @IBOutlet weak var labelResult: UILabel!
    @IBOutlet weak var imageView: UIImageView!

    lazy var consoleClassificationRequest: VNCoreMLRequest? = {
        let configuration = MLModelConfiguration()
        do {
            let console = try Console(configuration: configuration)
            let visionModel = try VNCoreMLModel(for: console.model)
            let request = VNCoreMLRequest(model: visionModel) { request, error in
                self.processObservation(for: request)
            }
            request.imageCropAndScaleOption = .scaleFit
            return request
        } catch {
            print(error)
            return nil
        }
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if !UIImagePickerController.isSourceTypeAvailable(.camera) {
            buttonCamera.isHidden = true
        }
    }
    
    func classify(image: UIImage) {
        DispatchQueue.global().async {
            guard let ciimage = CIImage(image: image),
                  let consoleClassificationRequest = self.consoleClassificationRequest else {return}
            let orientation = image.imageOrientation
            let handler = VNImageRequestHandler(ciImage: ciimage, orientation: CGImagePropertyOrientation(orientation: orientation))
            do  {
                try handler.perform([consoleClassificationRequest])
            } catch {
                print(error)
            }
        }
    }
    
    private func processObservation(for request: VNRequest) {
        DispatchQueue.main.async {
            guard let observation = (request.results as? [VNClassificationObservation])?.first else {return}
            let confidence = "\(observation.confidence * 100)%"
            let identifier = observation.identifier
            self.labelResult.text = "Resultado: \(confidence) - \(identifier)"
        }
    }
    
    private func showPicker(sourceType: UIImagePickerController.SourceType) {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = self
        present(picker, animated: true, completion: nil)
    }

    @IBAction func showCamera(_ sender: UIButton) {
        showPicker(sourceType: .camera)
    }
    
    @IBAction func showLibrary(_ sender: UIButton) {
        showPicker(sourceType: .photoLibrary)
    }
}

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.originalImage] as? UIImage {
            imageView.image = image
            classify(image: image)
        }
        dismiss(animated: true, completion: nil)
    }
}

extension CGImagePropertyOrientation {
    init(orientation: UIImage.Orientation) {
        switch orientation {
        case .up:
            self = .up
        case .upMirrored:
            self = .upMirrored
        case .down:
            self = .down
        case .downMirrored:
            self = .downMirrored
        case .left:
            self = .left
        case .leftMirrored:
            self = .leftMirrored
        case .right:
            self = .right
        case .rightMirrored:
            self = .rightMirrored
        @unknown default:
            fatalError()
        }
    }
}
