//
//  PhotosViewController.swift
//  Virtual Tourist - Udacity iOS NanoDegree
//
//  Created by Matthew Folbigg on 01/03/2021.
//

import Foundation
import UIKit

class PhotoDetailController: UIViewController {
    
    @IBOutlet var imageView: UIImageView!
    var image: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imageView.image = image
    }
    
}

