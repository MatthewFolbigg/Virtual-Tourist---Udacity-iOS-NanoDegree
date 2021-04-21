# Virtual Touist
Virtual Tourist is a project completed as part of the Udacity iOS Developer Nanodegree to practice:
* concurrency and elegantly displaying images from an api in a collection view
* Persisting data using the Apple Core Data framework

Additional Learning:
* First time implementing device haptics
* Custom MKAnnotationViews
* Built custom instructional views for dropping a pin on the map view and edit/deletion in the photo collection view

Built using the [Flickr API](https://www.flickr.com/services/api/)

## Functionality
#### Drop a pin
* Press and hold to begin placing a pin on the map
* Once the pin is in the desired locaion let go to place it

#### View location photos
* Once a pin is dropped, or an existing pin is selceted phtos for that location are retreived and displayed in a collection view
* If the loaction ahs previouly been view the photos will be fetched from a core data store
* If its a new location photos are downloaded from the Flickr API
* Unwanted photos can be removed view the collection view edit button
* If a photo is tapped it is displayed in its own view

## Images
#### Adding Pins
<img src="https://github.com/MatthewFolbigg/VirtualTourist-iOSUdacityNanodegree/blob/4199028e2ea4532e4f5b7c21cad41be73708739d/Images/Map.png" width="150"> <img src="https://github.com/MatthewFolbigg/VirtualTourist-iOSUdacityNanodegree/blob/4199028e2ea4532e4f5b7c21cad41be73708739d/Images/TappedPin.png" width="150"> <img src="https://github.com/MatthewFolbigg/VirtualTourist-iOSUdacityNanodegree/blob/4199028e2ea4532e4f5b7c21cad41be73708739d/Images/AddingPin.png" width="150">

#### Photos
<img src="https://github.com/MatthewFolbigg/VirtualTourist-iOSUdacityNanodegree/blob/4199028e2ea4532e4f5b7c21cad41be73708739d/Images/Photos.png" width="150"> <img src="https://github.com/MatthewFolbigg/VirtualTourist-iOSUdacityNanodegree/blob/4199028e2ea4532e4f5b7c21cad41be73708739d/Images/EditPhotos.png" width="150"> <img src="https://github.com/MatthewFolbigg/VirtualTourist-iOSUdacityNanodegree/blob/4199028e2ea4532e4f5b7c21cad41be73708739d/Images/ViewPhoto.png" width="150">



