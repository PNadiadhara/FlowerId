//
//  ViewController.swift
//  PlantML
//
//  Created by Pritesh Nadiadhara on 10/12/19.
//  Copyright © 2019 PriteshN. All rights reserved.
//

import UIKit
import CoreML
import Vision // Apply computer vision algorithms to perform a variety of tasks on input images and video
import Alamofire
import SwiftyJSON
import SDWebImage

class ViewController: UIViewController {
    
    let wikipediaURl = "https://en.wikipedia.org/w/api.php"
    private let imagePicker = UIImagePickerController()
    
    // MARK: - UI Elements
    private let stackView : UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.distribution = .fillEqually
        
        sv.spacing = 20
        return sv
    }()
    
    
    private let imageView : UIImageView = {
        let iv = UIImageView()
        iv.clipsToBounds = true
        iv.contentMode = .scaleAspectFit
        iv.image = UIImage(systemName: "camera")
        return iv
    }()
    
    private let descriptionTextView : UITextView = {
        let tv = UITextView()
        tv.clipsToBounds = true
        tv.isEditable = false
        tv.font = .systemFont(ofSize: 21)
        tv.text = "Take a Photo of a To ID a Flower"
        
        return tv
    }()
    
    
    
    // MARK: - viewDidLoad
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .camera,
                                                            target: self,
                                                            action: #selector (didTapCameraButton))

        view.backgroundColor = .gray
    
        // edgesFor stop view from going underneath nav bar
        edgesForExtendedLayout = []
        setUpStackView()
        
    
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        imagePicker.sourceType = .camera
        
        
        
    }
    
    func setUpStackView() {
        let stackView = UIStackView(arrangedSubviews: [imageView, descriptionTextView])
        stackView.frame = view.frame
        stackView.axis = .vertical
        stackView.distribution = .fillEqually
        stackView.spacing = 20
        view.addSubview(stackView)
        
    }
    
    
    
    //MARK: - Functions
    
    @objc func didTapCameraButton(){
        print("camera tapped")
        present(imagePicker, animated: true, completion: nil)
        
    }

    
    func detectImage(image: CIImage){
        // flower classifiers comes from auto generated .mlmodel
        guard let model = try? VNCoreMLModel(for: FlowerClassifier().model) else {
            fatalError("cannot import model")
        }
        let request = VNCoreMLRequest(model: model) { (request, error) in
            // this returns the flower type
            guard let classification = request.results?.first as? VNClassificationObservation else {
                fatalError("couldn't clasify image")
            }
            
            self.navigationItem.title = classification.identifier.capitalized
            self.requestWikiInfo(flowerName: classification.identifier)
        }
        
        let handler = VNImageRequestHandler(ciImage: image)
        do {
            try handler.perform([request])
        } catch {
            print(error)
        }
    }
    
    
    
    func requestWikiInfo(flowerName: String){
        let parameters : [String:String] = [
            "format" : "json",
            "action" : "query",
            "prop" : "extracts|pageimages",
            "exintro" : "",
            "explaintext" : "",
            "titles" : flowerName,
            "indexpageids" : "",
            "redirects" : "1",
            "pithumbsize" : "500"
        ]
        
        AF.request(wikipediaURl, method: .get, parameters: parameters).responseJSON { (response) in
            switch response.result {
            
            case .success(_):
                print("got wiki info")
                //print(response)
                
                let flowerJSON : JSON = JSON(response.value as Any)
                print("flowerJSON : ", flowerJSON)
                //page id required to get wiki blurb on flower
                
                let pageid = flowerJSON["query"]["pageids"][0].stringValue
                print("page id : " ,pageid)
                
                let flowerDescription = flowerJSON["query"]["pages"][pageid]["extract"].stringValue
                print("flower description : ", flowerDescription)
                
                let flowerImageURL = flowerJSON["query"]["pages"][pageid]["thumbnail"]["source"].stringValue
                print(flowerImageURL)
                self.imageView.sd_setImage(with: URL(string: flowerImageURL))
                
                self.descriptionTextView.text = flowerDescription
                self.descriptionTextView.adjustsFontForContentSizeCategory = true
                
                
                
                
            case .failure(_):
                print("failed to get wiki info")
                break
                
            }
        }
    }
    
}

extension ViewController : UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let userPickedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage{
            guard let ciImage = CIImage(image: userPickedImage) else {
                fatalError("Cannot convert to CI Image")
            }
            detectImage(image: ciImage)
            
        }
        
        imagePicker.dismiss(animated: true, completion: nil)
    }
}

extension ViewController: UINavigationControllerDelegate {
    
}
