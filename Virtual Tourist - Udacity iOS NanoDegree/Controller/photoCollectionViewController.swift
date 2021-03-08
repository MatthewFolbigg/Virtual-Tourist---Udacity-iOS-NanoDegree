//
//  photoCollectionViewController.swift
//  Virtual Tourist - Udacity iOS NanoDegree
//
//  Created by Matthew Folbigg on 08/03/2021.
//

import Foundation
import UIKit
import CoreData

class PhotoCollectionViewController: UICollectionViewController {

    var photosInfo: [FlickrPhotoInformation]!
    var photos: [UIImage] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getImagesFrom(photosData: photosInfo)
        print("Loaded")
    }
    
    func getImagesFrom(photosData: [FlickrPhotoInformation]) {
        if photosData.count > 0 {
            for data in photosData {
                FlickrApiClient.getImageFor(photo: data, size: .medium) { (image) in
                    self.photos.append(image)
                    //TODO: Insert animated instead of reloading
                    //TODO: Add UIIMage to pin and begin downlaods in mapview instead of only beggining now.
                    self.collectionView.reloadData()
                }
            }
        }
    }
}

//MARK: Collection View Delegate
extension PhotoCollectionViewController {
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        print("called cellfor")
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCollectionCell", for: indexPath) as! PhotoCollectionCell
        cell.photoImageView.image = photos[indexPath.row]
        return cell
        
    }
    
}
