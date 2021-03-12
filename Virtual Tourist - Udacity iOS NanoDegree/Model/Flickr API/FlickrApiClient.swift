//
//  FlickrApiClient.swift
//  Virtual Tourist - Udacity iOS NanoDegree
//
//  Created by Matthew Folbigg on 04/03/2021.
//

import Foundation
import UIKit

class FlickrApiClient {
    
    /*
     Provides Functionality to:
     - Search for a list of photo objects based on a latiude and longitude
     - Use the photo information provided by the search to request individual image files
    */
    
    //&sort=date-posted-desc
    
    //MARK: Endpoint Construction
    enum Endpoints {
        
        private static let photoHostString = "https://live.staticflickr.com/"
        private static let searchHostString = "https://www.flickr.com/services/"
        private static let apiKeyQueryString = "api_key=\(flickrPrivate.shared.apiKey)"
        private static let searchMethodPathString = "rest/?method=flickr.photos.search"
        private static let searchResponseFormatQueryString = "&format=json&nojsoncallback=1"
        private static let sortByDateDescending = "&sort=date-posted-desc"
        
        //MARK: Endpoints
        // Documentation: https://www.flickr.com/services/api/flickr.photos.search.html
        case getPhotoIDsForLocation(lat: String, long: String, precision: locationPrecision, page: Int = 1)
        // Documentation: https://www.flickr.com/services/api/misc.urls.html
        case getPhoto(serverID: String, photoID: String, secret: String, sizeTag: sizeTag)
        
        //MARK: Endpoint URLs
        var url: URL { URL(string: self.urlString)! }
        
        private var urlString: String {
            switch self {
            
            case .getPhotoIDsForLocation(let lat, let lon, let precision, let page) :
                let bbox = FlickrApiClient.getBbox(precision: precision, lati: lat, long: lon)
                //TODO: Add content type to only return photos (To not include screenshots etc)
                return
                    Endpoints.searchHostString +
                    Endpoints.searchMethodPathString + "&" +
                    Endpoints.apiKeyQueryString +
                    "&bbox=" + bbox +
                    "&lat=\(lat)" + "&lon=\(lon)" +
                    Endpoints.sortByDateDescending +
                    "&per_page=30&page=\(page)" +
                    Endpoints.searchResponseFormatQueryString
                
            case .getPhoto(let serverID, let photoID, let secret, let sizeTag):
                return
                    Endpoints.photoHostString +
                    serverID + "/" +
                    photoID + "_" +
                    secret + "_" +
                    sizeTag.rawValue +
                    ".jpg"
            }
        }
    }
    
    enum sizeTag: String {
        //Full list of size tags: https://www.flickr.com/services/api/misc.urls.html
        case squareThumbnail = "q" //150
        case small = "w" //400
        case medium = "c" //800
        case large = "b" // 1024
    }
    
    enum locationPrecision {
        case meter
        case tenMeter
        case hundredMeter
        case killometer
        case tenKillometer
        
        //This is a rough description, exact number differs and precision of longitude will vary depedning on latitude.
        var boxSize: Double {
            switch self {
            case .meter: return 0.00001
            case .tenMeter: return 0.0001
            case .hundredMeter: return 0.001
            case .killometer: return 0.01
            case .tenKillometer: return 0.1
            }
        }
    }
    
    class func getBbox(precision: locationPrecision, lati: String, long: String) -> String {
        let sep = "%2C"
        let box = precision.boxSize
        let lat = Double(lati)!
        let lon = Double(long)!
        let minLat = String(lat - box)
        let minLon = String(lon - box)
        let maxLat = String(lat + box)
        let maxLon = String(lon + box)
        let bboxString: String = minLon + sep + minLat + sep + maxLon + sep + maxLat
        return bboxString
    }
}

//MARK: GET Requests
extension FlickrApiClient {
    
    //MARK: Get Photo Information
    class func getPhotoInformationFor(Latitude: String, Longitude: String, precision: locationPrecision, page: Int, completion: @escaping (FlickrSearchResponsePage) -> Void) {
        
        let url = Endpoints.getPhotoIDsForLocation(lat: Latitude, long: Longitude, precision: precision, page: page).url
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            
            guard let data = data else {
                print("error: No Data from flickr. url: \(url)")
                return
            }
            
            let decoder = JSONDecoder()
            do {
                let decodedData = try decoder.decode(FlickrSearchResponse.self, from: data)
                DispatchQueue.main.async {
                    let page = decodedData.responsePage
                    print("Page Number: \(page.pageNumber), Number of Pages: \(page.numberOfPages), Photos at Location: \(page.totalNumberOfPhotos)")
                    completion(decodedData.responsePage)
                }
            } catch {
                print("Decoding Failed")
                print(error)
            }
        }
        task.resume()
    }
    
    //MARK: Get Photo Image
    class func getImageFor(photo: FlickrPhotoInformation, size: sizeTag, completion: @escaping (Data) -> Void) {
        
        let url = Endpoints.getPhoto(serverID: photo.serverId, photoID: photo.id, secret: photo.secret, sizeTag: size).url
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard let data = data else {
                print("Error Downloading Photo Image")
                print(error?.localizedDescription ?? "")
                return
            }
        
            DispatchQueue.main.async {
                completion(data)
            }
        }
        task.resume()
        
    }
}
