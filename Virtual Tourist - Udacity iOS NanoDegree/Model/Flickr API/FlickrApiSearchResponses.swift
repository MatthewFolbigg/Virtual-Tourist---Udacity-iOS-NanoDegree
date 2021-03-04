//
//  FlickrApiResponses.swift
//  Virtual Tourist - Udacity iOS NanoDegree
//
//  Created by Matthew Folbigg on 04/03/2021.
//

import Foundation

//MARK: Photo Seach Response
struct flickrSearchResponse: Codable {
    let photos: flickrSearchResponsePage
    let stat: String
}

//MARK: Response Page
struct flickrSearchResponsePage: Codable {
    let page: Int
    let pages: Int
    let perpage: Int
    let total: String
    let photo: [flickrPhotoInformation]
}

//MARK: Induvidual Photo Information
struct flickrPhotoInformation: Codable {
    let id: String
    let owner: String
    let secret: String
    let server: String
    let farm: Int
    let title: String
    let ispublic: Int
    let isfriend: Int
    let isfamily: Int
}


        
