//
//  DataController.swift
//  Virtual Tourist - Udacity iOS NanoDegree
//
//  Created by Matthew Folbigg on 05/03/2021.
//

import Foundation
import CoreData

class DataController {
    
    let persistentContainer: NSPersistentContainer
    var viewContext: NSManagedObjectContext { persistentContainer.viewContext }
    
    init(modelName: String) {
        persistentContainer = NSPersistentContainer(name: modelName)
    }
    
    func load(completeion: (() -> Void)? = nil) {
        persistentContainer.loadPersistentStores { (storeDescription, error) in
            guard error == nil else {
                print("Error Loading Persistent Stores")
                fatalError(error!.localizedDescription)
            }
            completeion?()
        }
    }
    
}
