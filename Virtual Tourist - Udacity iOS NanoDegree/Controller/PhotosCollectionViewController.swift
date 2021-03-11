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
    
    //MARK: Outlets
    @IBOutlet var collectionView: UICollectionView!

    //MARK: Variables
    var dataController: DataController!
    var pin: Pin!
    var photosInfo: [FlickrPhotoInformation] = []
    var photos: [UIImage] = []
    
    //MARK: Life Cycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fetchPhotosFromCoreData { (photos) in
            if photos.count > 0 {
                print("Loading from Core Data")
                for photo in photos {
                    self.displayImageFrom(photo: photo)
                }
            } else {
                print("Loading From Flickr")
                self.searchForPhotosAtPin()
            }
        }
    }

    //MARK: Photo Loading
    func fetchPhotosFromCoreData(completion: @escaping ([Photo]) -> Void) {
        let fetchRequest :NSFetchRequest<Photo> = Photo.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "pin == %@", argumentArray: [pin!])
        DispatchQueue.global().async {
            if let savedPhotosFromPin = try? self.dataController.viewContext.fetch(fetchRequest) {
                completion(savedPhotosFromPin)
            }
        }
    }
    
    //MARK: Photo Search/Download
    func searchForPhotosAtPin() {
        let latitude = String(pin.latitude)
        let longitude = String(pin.longitude)
        let page = 1
        FlickrApiClient.getPhotoInformationFor(Latitude: latitude, Longitude: longitude, precision: .killometer, page: page, completion: handlePhotoSearchResults)
    }
    
    func handlePhotoSearchResults(response: FlickrSearchResponsePage) {
        if Int(response.totalNumberOfPhotos) == 0 {
            handelNoPhotosForPin()
        } else {
        //    photosInfo = response.photos
        }
        let photosInfo = response.photos
        for photoInformation in photosInfo {
            FlickrApiClient.getImageFor(photo: photoInformation, size: .large, completion: handleAndSaveImageData(data:))
        }
    }
    
    func handleAndSaveImageData(data: Data) {
        let photo = Photo(context: dataController.viewContext)
        photo.data = data
        photo.pin = pin
        self.displayImageFrom(photo: photo)
        try? dataController.viewContext.save()
    }
    
    //MARK: Display image from downloaded/loaded data
    func displayImageFrom(photo: Photo) {
        guard let photoData = photo.data else { return }
        if let image = UIImage(data: photoData) {
            DispatchQueue.main.async {
                self.photos.append(image)
                let indexPath = IndexPath(row: self.photos.count-1, section: 0)
                self.collectionView.insertItems(at: [indexPath])
            
            }
        }
    }
    
    //MARK: Other Helpers
    func handelNoPhotosForPin() {
        //TODO: Present a message to the user so they know there is no photos rather than assuming something went wrong
        print("No Photos at Location")
    }
    

}

//MARK: Collection View Delegate
extension PhotoCollectionViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCollectionCell", for: indexPath) as! PhotoCollectionCell
        cell.photoImageView.image = photos[indexPath.row]
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let destination = storyboard?.instantiateViewController(identifier: "PhotoDetailController") as! PhotoDetailController
        destination.image = photos[indexPath.row]
        navigationController?.pushViewController(destination, animated: true)
    }
    
}
