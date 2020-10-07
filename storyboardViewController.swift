//
//  storyboardViewController.swift
//  PlantML
//
//  Created by Pritesh Nadiadhara on 10/5/20.
//  Copyright © 2020 PriteshN. All rights reserved.
//

// this version of VC only to check against progamatic UI issues

import UIKit
import CoreML
import Vision // Apply computer vision algorithms to perform a variety of tasks on input images and video
import Alamofire
import SwiftyJSON
import SDWebImage

class SBViewController: UIViewController {
    
    @IBOutlet weak var imageView : UIImageView!
    @IBOutlet weak var descriptionLabel: UITextView!
  
   
    
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
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.clipsToBounds = true
        scrollView.isScrollEnabled = true
        return scrollView
    }()
    
    
    
    private let descriptionLabelScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.clipsToBounds = true
        scrollView.isScrollEnabled = true
        return scrollView
    }()
    
    
    
    
    
    
    // MARK: - viewDidLoad
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .camera,
                                                            target: self,
                                                            action: #selector (didTapCameraButton))

        view.backgroundColor = .gray

        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        imagePicker.sourceType = .camera
        
        
        
    }
    
    
    

    
    //MARK: - Functions
    
    @objc func didTapCameraButton(){
        print("camera tapped")
        present(imagePicker, animated: true, completion: nil)
        
    }

    
    func setUpStackView(){
        stackView.translatesAutoresizingMaskIntoConstraints                                                          = false
        stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 8).isActive         = true
        stackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 8).isActive    = true
        stackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -8).isActive = true
        stackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8).isActive     = true
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
                
                self.descriptionLabel.text = flowerDescription
                self.descriptionLabel.adjustsFontForContentSizeCategory = true
                
                
                
                
            case .failure(_):
                print("failed to get wiki info")
                break
                
            }
        }
    }
    
}

extension SBViewController : UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let userPickedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage{
            DispatchQueue.main.async {
                guard let ciImage = CIImage(image: userPickedImage) else {
                    fatalError("Cannot convert to CI Image")
                }
                self.detectImage(image: ciImage)
            }
            
            
            
        }
        
        imagePicker.dismiss(animated: true, completion: nil)
    }
}

extension SBViewController: UINavigationControllerDelegate {
    
}
