//
//  photoCollectionViewController.swift
//  Virtual Tourist - Udacity iOS NanoDegree
//
//  Created by Matthew Folbigg on 08/03/2021.
//

import Foundation
import UIKit
import CoreData

class PhotoCollectionViewController: UIViewController {
    
    @IBOutlet var collectionView: UICollectionView!

    var dataController: DataController!
    var pin: Pin!
    var photosInfo: [FlickrPhotoInformation]!
    var photos: [Photo] = []
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
        if photos.count == 0 {
            self.getImagesFrom(photosData: self.photosInfo)
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func getImagesFrom(photosData: [FlickrPhotoInformation]) {
        if photosData.count > 0 {
            for data in photosData {
                FlickrApiClient.getImageFor(photo: data, size: .medium) { (image) in
                    let photo = Photo(context: self.dataController.viewContext)
                    photo.data = image.pngData()
                    photo.pin = self.pin
                    try? self.dataController.viewContext.save()
                    self.photos.append(photo)
                    let indexPath = IndexPath(row: self.photos.count - 1, section: 0)
                    self.collectionView.insertItems(at: [indexPath])
                }
            }
        }
    }
}

//MARK: Collection View Delegate
extension PhotoCollectionViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCollectionCell", for: indexPath) as! PhotoCollectionCell
        if let data = photos[indexPath.row].data {
            let image = UIImage(data: data)
            cell.photoImageView.image = image
        }
        return cell
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let destination = storyboard?.instantiateViewController(identifier: "PhotoDetailController") as! PhotoDetailController
        if let data = photos[indexPath.row].data {
            let image = UIImage(data: data)
            destination.image = image
        }
        navigationController?.pushViewController(destination, animated: true)
    }
    
}
