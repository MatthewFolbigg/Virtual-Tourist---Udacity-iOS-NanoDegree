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
    @IBOutlet var newCollectionButton: UIBarButtonItem!
    @IBOutlet var loadingActivityIndicator: UIActivityIndicatorView!

    //MARK: Variables
    var dataController: DataController!
    var pin: Pin!
    
    var photosInfo: [FlickrPhotoInformation] = []
    var pagesAvailable: Int?
    var photos: [Photo] = [] //Data Source for collection View
    
    
    //MARK: Life Cycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
        navigationController?.toolbar.isHidden = false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadPhotos()
    }
    
    func loadPhotos() {
        loadingActivityIndicator.startAnimating()
        fetchPhotosFromPin() {
            if self.photos.count == 0 {
                self.searchForPhotosAtPin()
            }
        }
    }

    //MARK: Photo Load from coreData
    func fetchPhotosFromPin(completion: @escaping () -> Void) {
        let fetchRequest :NSFetchRequest<Photo> = Photo.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "pin == %@", argumentArray: [pin!])
        DispatchQueue.global().async {
            if let fetchedPhotos = try? self.dataController.viewContext.fetch(fetchRequest) {
                DispatchQueue.main.async {
                    if fetchedPhotos.count > 0 {
                        self.handelFetchedPhotos(photos: fetchedPhotos)
                    }
                    completion()
                }
            }
        }
    }
    
    func handelFetchedPhotos(photos: [Photo]) {
        print("Loaded from Core Data")
        self.photos = photos
        self.loadingActivityIndicator.stopAnimating()
        self.collectionView.reloadData()
    }
    
    //MARK: Photo Search/Download
    func searchForPhotosAtPin(page: Int = 1) {
        print("Searching Flickr")
        let latitude = String(pin.latitude)
        let longitude = String(pin.longitude)
        print("Page passed to Client: \(page)")
        FlickrApiClient.getPhotoInformationFor(Latitude: latitude, Longitude: longitude, precision: .tenKillometer, page: page, completion: handlePhotoSearchResults)
    }
    
    func handlePhotoSearchResults(response: FlickrSearchResponsePage) {
        pagesAvailable = response.numberOfPages
        if Int(response.totalNumberOfPhotos) == 0 {
            handelNoPhotosForPin()
        } else {
            photosInfo = response.photos
            for _ in photosInfo {
                let blankPhoto = Photo(context: dataController.viewContext)
                photos.append(blankPhoto)
            }
            self.loadingActivityIndicator.stopAnimating()
            newCollectionButton.isEnabled = true
            collectionView.reloadData()
        }
    }
    
    func downloadImageDataFor(photoInfo: FlickrPhotoInformation, completion: @escaping (Data) -> Void) {
        DispatchQueue.global().async {
            FlickrApiClient.getImageFor(photo: photoInfo, size: .large) { (imageData) in
                DispatchQueue.main.async {
                    completion(imageData)
                }
            }
        }
    }
    
    func handleAndSaveImageData(data: Data, to photo: Photo) {
        photo.data = data
        photo.pin = pin
        try? dataController.viewContext.save()
    }
    
    //MARK: Button Actions
    @IBAction func newCollectionBarButtonDidTapped() {
        loadingActivityIndicator.startAnimating()
        newCollectionButton.isEnabled = false
        
        //Remove data for previous page
        for photo in photos {
            dataController.viewContext.delete(photo)
            try? dataController.viewContext.save()
        }
        photos = []
        photosInfo = []
        
        //Get new page
        let page = getRandomFlickrPageNumber()
        searchForPhotosAtPin(page: page)
    }
        
    //MARK: Other Helpers
    func handelNoPhotosForPin() {
        //TODO: Present a message to the user so they know there is no photos rather than assuming something went wrong
        loadingActivityIndicator.stopAnimating()
        newCollectionButton.isEnabled = true
        print("No Photos at Location")
    }
    
    func getRandomFlickrPageNumber() -> Int {
        if let pages = pagesAvailable {
            //Flickr search can only return 4000 images but its total page count can be much higher. If you ask for a page that contains image in the range above 4000 it seems to return page 1. This if statement will make sure the random page is withing the 4000 photo maxium (4000 photos/30 perPage = 133.3pages) Since many searchs can contain 100,000s of pages without this flickr will return page 1 most of the time.
            if pages > 133 {
                return Int.random(in: 1...130)
            } else {
                return Int.random(in: 1...pages)
            }
        }
        return 1
    }

}

//MARK: Collection View Delegate
extension PhotoCollectionViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCollectionCell", for: indexPath) as! PhotoCollectionCell
        
        //Set Placeholder
        cell.photoImageView.image = nil
        cell.imageDownloadIndicator.startAnimating()
        
        if let photo = photos[indexPath.row].data {
            //Add image previously fetched from coreData
            cell.imageDownloadIndicator.stopAnimating()
            cell.photoImageView.image = UIImage(data: photo)
        } else {
            //Download Photo from Flickr
            let photoInformation = photosInfo[indexPath.row]
            let photo = self.photos[indexPath.row]
            downloadImageDataFor(photoInfo: photoInformation) { (imageData) in
                self.handleAndSaveImageData(data: imageData, to: photo)
                cell.imageDownloadIndicator.stopAnimating()
                cell.photoImageView.image = UIImage(data: imageData)
            }
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let destination = storyboard?.instantiateViewController(identifier: "PhotoDetailController") as! PhotoDetailController
        if let image = UIImage(data: photos[indexPath.row].data!) {
            destination.image = image
            navigationController?.pushViewController(destination, animated: true)
        }
    }
    
}
