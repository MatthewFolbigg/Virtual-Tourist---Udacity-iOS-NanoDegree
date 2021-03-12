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
    @IBOutlet var editBarButton: UIBarButtonItem!
    @IBOutlet var loadingActivityIndicator: UIActivityIndicatorView!
    @IBOutlet var noPhotosLabel: UILabel!
    @IBOutlet var tapToDeleteView: UIView!
    @IBOutlet var tapToDeleteViewHeight: NSLayoutConstraint!

    //MARK: Variables
    var dataController: DataController!
    var pin: Pin!
    var photosPerRow = 3
    
    var photosInfo: [FlickrPhotoInformation] = []
    var pagesAvailable: Int?
    var photos: [Photo] = [] //Data Source for collection View
    
    
    //MARK: Life Cycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
        navigationController?.setToolbarHidden(false, animated: true)
        noPhotosLabel.isHidden = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = pin.title
        loadPhotos()
    }
    
    func loadPhotos() {
        setCoreDataActivityTo(true)
        fetchPhotosFromPin() {
            if self.photos.count == 0 {
                self.searchForPhotosAtPin()
            }
            self.setCoreDataActivityTo(false)
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
            collectionView.reloadData()
        }
        newCollectionButton.isEnabled = true
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
        newCollectionButton.isEnabled = false
        collectionView.scrollToItem(at: IndexPath(item: 0, section: 0), at: .top, animated: true)
        noPhotosLabel.isHidden = true
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
    
    @IBAction func editButtonDidTapped() {
        collectionView.isEditing = !collectionView.isEditing
        if collectionView.isEditing {
            editBarButton.title = "Done"
            tapToDeleteViewHeight.constant = 40
            tapToDeleteView.layoutIfNeeded()
            UIView.animate(withDuration: 0.2) {
                self.tapToDeleteView.alpha = 0.9
            }
        } else {
            editBarButton.title = "Edit"
            UIView.animate(withDuration: 0.2) {
                self.tapToDeleteView.alpha = 0
            } completion: { (complete) in
                self.tapToDeleteViewHeight.constant = 0
                self.tapToDeleteView.layoutIfNeeded()
            }
        }
    }
        
    //MARK: Other Helpers
    func handelNoPhotosForPin() {
        noPhotosLabel.isHidden = false
        print("No Photos at Location")
    }
    
    func setCoreDataActivityTo(_ on: Bool) {
        if on {
            loadingActivityIndicator.startAnimating()
        } else {
            loadingActivityIndicator.stopAnimating()
        }
    }
    
    
    func getRandomFlickrPageNumber() -> Int {
        if let pages = pagesAvailable {
            //Flickr search can only return 4000 images but its total page count can be much higher. If you ask for a page that contains image in the range above 4000 it seems to return page 1. This if statement will make sure the random page is withing the 4000 photo maxium (4000 photos/30 perPage = 133.3pages) Since many searchs can contain 100,000s of pages without this flickr will return page 1 most of the time. Per Page is currently set in API Client
            //TODO: Move this functionality to the Flickr API Client so if perPage needs to be changed in the future this can automatically adjust instead of hard coding a number
            if pages > 133 && pages != 0{
                return Int.random(in: 1...130)
            } else if pages != 0 {
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
        
        if let photo = try photos[indexPath.row].data {
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
    
    
    
    func collectionView(_ collectionView: UICollectionView, canEditItemAt indexPath: IndexPath) -> Bool {
        true
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView.isEditing {
            //Delete Tapped Image
            let photo = photos[indexPath.row]
            dataController.viewContext.delete(photo)
            photos.remove(at: indexPath.row)
            collectionView.deleteItems(at: [indexPath])
            try? dataController.viewContext.save()
        } else {
            //Open Tapped Image
            let destination = storyboard?.instantiateViewController(identifier: "PhotoDetailController") as! PhotoDetailController
            if let image = UIImage(data: photos[indexPath.row].data!) {
                destination.image = image
                navigationController?.pushViewController(destination, animated: true)
            }
        }
    }
}

extension PhotoCollectionViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let padding = 1 * (photosPerRow + 1)
        let collectionWidth = collectionView.frame.width - CGFloat(padding)
        let itemWidth = collectionWidth / CGFloat(photosPerRow) //- CGFloat(6)
        return CGSize(width: itemWidth, height: itemWidth)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 1, left: 1, bottom: 1, right: 1)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
}
