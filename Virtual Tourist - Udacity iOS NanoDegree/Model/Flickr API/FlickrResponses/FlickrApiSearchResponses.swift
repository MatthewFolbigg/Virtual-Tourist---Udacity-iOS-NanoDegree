//
//  FlickrApiResponses.swift
//  Virtual Tourist - Udacity iOS NanoDegree
//
//  Created by Matthew Folbigg on 04/03/2021.
//

import Foundation

//MARK: Photo Seach Response
struct flickrSearchResponse: Codable {
    let responsePage: flickrSearchResponsePage
    let status: String
    
    enum CodingKeys: String, CodingKey {
        case responsePage = "photos"
        case status = "stat"
    }
}

//MARK: Response Page
struct flickrSearchResponsePage: Codable {
    let pageNumber: Int
    let numberOfPages: Int
    let photosPerPage: Int
    let totalNumberOfPhotos: String
    let photos: [flickrPhotoInformation]
    
    enum CodingKeys: String, CodingKey {
        case pageNumber = "page"
        case numberOfPages = "pages"
        case photosPerPage = "perpage"
        case totalNumberOfPhotos = "total"
        case photos = "photo"
    }
}

//MARK: Induvidual Photo Information
struct flickrPhotoInformation: Codable {
    let id: String
    let ownerId: String
    let secret: String
    let serverId: String
    let farmNumber: Int
    let title: String
    let isPublic: Int
    let isFriend: Int
    let isFamily: Int
    
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case ownerId = "owner"
        case secret = "secret"
        case serverId = "server"
        case farmNumber = "farm"
        case title = "title"
        case isPublic = "ispublic"
        case isFriend = "isfriend"
        case isFamily = "isfamily"
    }
}


        
