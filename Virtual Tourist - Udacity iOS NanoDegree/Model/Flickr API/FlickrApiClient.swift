//
//  FlickrApiClient.swift
//  Virtual Tourist - Udacity iOS NanoDegree
//
//  Created by Matthew Folbigg on 04/03/2021.
//

import Foundation

class FlickrApiClient {
    
    /*
     Provides Functionality to:
     - Search for a list of photo objects based on a latiude and longitude
     - Use the photo information provided by the search to request individual image files
    */
    
    //MARK: Endpoint Construction
    enum Endpoints {
        
        private static let photoHostString = "https://live.staticflickr.com/"
        private static let searchHostString = "https://www.flickr.com/services/"
        private static let apiKeyQueryString = "api_key=\(flickrPrivate.shared.apiKey)"
        private static let searchMethodPathString = "rest/?method=flickr.photos.search"
        private static let searchResponseFormatQueryString = "&format=json&nojsoncallback=1"
        
        //MARK: Endpoints
        // Documentation: https://www.flickr.com/services/api/flickr.photos.search.html
        case getPhotoIDsForLocation(lat: String, long: String)
        // Documentation: https://www.flickr.com/services/api/misc.urls.html
        case getPhoto(serverID: String, photoID: String, secret: String, sizeTag: sizeTag)
        
        //MARK: Endpoint URLs
        var url: URL { URL(string: self.urlString)! }
        
        private var urlString: String {
            switch self {
            
            case .getPhotoIDsForLocation(let lat, let lon) :
                return
                    Endpoints.searchHostString +
                    Endpoints.searchMethodPathString + "&" +
                    Endpoints.apiKeyQueryString +
                    "&lat=\(lat)" + "&lon=\(lon)" +
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
}

//MARK: GET Requests
extension FlickrApiClient {
    
    //MARK: Get Photo Information
    class func getPhotoInformationFor(Latitude: String, Longitude: String, completion: @escaping ([flickrPhotoInformation]) -> Void) {
        
        let url = Endpoints.getPhotoIDsForLocation(lat: Latitude, long: Longitude).url
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            
            guard let data = data else {
                print("error: No Data from flickr. url: \(url)")
                return
            }
            
            let decoder = JSONDecoder()
            do {
                let decodedData = try decoder.decode(flickrSearchResponse.self, from: data)
                completion(decodedData.photos.photo)
            } catch {
                print("Decoding Failed")
                print(error)
            }
            
        }
        task.resume()
        
        
    }
}
