//
//  ViewController.swift
//  Virtual Tourist - Udacity iOS NanoDegree
//
//  Created by Matthew Folbigg on 01/03/2021.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController {

    //MARK: IB Outlets
    @IBOutlet var mapView: MKMapView!
    
    //MARK: Variables
    var dataController: DataController!
    var placementPin: MKPointAnnotation!
    var currentPins: [Pin] = []
    //Haptic Generators
    var dropHaptic: UIImpactFeedbackGenerator?
    var placingHaptic: UISelectionFeedbackGenerator?
    var dragHaptic: UISelectionFeedbackGenerator?
    var errorHaptic: UINotificationFeedbackGenerator?
    
    //MARK: Life Cycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
        navigationController?.toolbar.isHidden = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadPinsFromCoreData()
        setUpMapGuestures()
        placementPin = getTemporaryPin()
    }
    
    func loadPinsFromCoreData() {
        let fetchRequest :NSFetchRequest<Pin> = Pin.fetchRequest()
        if let pins = try? dataController.viewContext.fetch(fetchRequest) {
            addAnnotationsFor(pins: pins)
            currentPins = pins
        }
    }
    
    func getCurrentPinFor(coordinate: CLLocationCoordinate2D) -> Pin? {
        for pin in currentPins {
            let lat = coordinate.latitude
            let long = coordinate.longitude
            if pin.latitude == lat && pin.longitude == long {
                return pin
            }
        }
        return nil
    }
    
    func openPhotoCollectionFor(pin: Pin) {
        let destination = self.storyboard?.instantiateViewController(identifier: "PhotoCollectionViewController") as! PhotoCollectionViewController
        destination.dataController = self.dataController
        destination.pin = pin
        self.navigationController?.pushViewController(destination, animated: true)
    }
    
    func prepareForHaptics(on: Bool) {
        placingHaptic = on ? UISelectionFeedbackGenerator() : nil
        placingHaptic?.prepare()
        dropHaptic = on ? UIImpactFeedbackGenerator(style: .rigid) : nil
        dragHaptic = on ? UISelectionFeedbackGenerator() : nil
        errorHaptic = on ? UINotificationFeedbackGenerator() : nil
    }
    
}

//MARK: Map View Delegate
extension MapViewController: MKMapViewDelegate {
    
    //MARK: Map Annotation Views
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        //TODO: Find a better way to differentiate annotation type other than title? Could cause an issue where the pin is misidentified if the user is ever able to set the pin title adn uses the same title as this switch.
        switch annotation.title {
        //Creates a moveable 'ghost' pin that shows the user where the pin will be dropped once they release their long press
        case "TemporaryPlacementPin":
            if let placementView = mapView.dequeueReusableAnnotationView(withIdentifier: "placementView") {
                return placementView
            } else {
                let placementView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "placementView")
                setTemporaryPinUI(for: placementView)
                return placementView
            }
        //Creates the final persistent dropped pin that acts as the users location selection.
        default:
            var droppedPinView = mapView.dequeueReusableAnnotationView(withIdentifier: "droppedPinView") as? MKPinAnnotationView
            if droppedPinView == nil {
                droppedPinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "droppedPinView")
                setDroppedPinUI(for: droppedPinView)
            }
            return droppedPinView
        }
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, didChange newState: MKAnnotationView.DragState, fromOldState oldState: MKAnnotationView.DragState) {
        if newState == .starting || oldState == .ending {
            dragHaptic?.selectionChanged()
        }
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if control == view.rightCalloutAccessoryView {
            guard let coordinate = view.annotation?.coordinate else {
                print("No coordinate associated with annotation")
                return
            }
            if let pin = getCurrentPinFor(coordinate: coordinate) {
                openPhotoCollectionFor(pin: pin)
            }
            
        }
    }
}

//MARK: Map Helpers
extension MapViewController {
    //MARK: Temporary Annotation & Pin Views
    func getTemporaryPin() -> MKPointAnnotation {
        //Defines a annotation that is used as a placement guide for the user. Once the user ends the long press this is replaced by a perminent pin
        let tempPin = MKPointAnnotation()
        tempPin.title = "TemporaryPlacementPin"
        return tempPin
    }
    
    func addAnnotationsFor(pins: [Pin]) {
        //Called both when pins are created and loaded from coreData
        for pin in pins {
            let annotation = MKPointAnnotation()
            annotation.coordinate.latitude = pin.latitude
            annotation.coordinate.longitude = pin.longitude
            annotation.title = pin.title
            mapView.addAnnotation(annotation)
        }
    }
    
    //MARK: Map Gesture adjustments
    func gestureIsNearEdgeOfMapView(point: CGPoint) -> Bool {
        let displayRect = mapView.bounds
        let border: CGFloat = 5
        if point.x < border || point.x > displayRect.maxX - border ||
        point.y < border || point.y > displayRect.maxY - border {
            return true
        } else {
            return false
        }
    }
    
    //MARK: Annotation UIs
    //UI for placement guide pin
    func setTemporaryPinUI(for view: MKPinAnnotationView) {
        view.animatesDrop = true
        view.pinTintColor = .label
        view.alpha = 0.5
        view.isDraggable = true
    }
    
    //UI for dropped pin
    func setDroppedPinUI(for view: MKPinAnnotationView?) {
        view?.animatesDrop = false
        view?.pinTintColor = .red
        view?.isDraggable = true
        view?.canShowCallout = true

        //MARK:Photos Button
        let button = UIButton(type: .detailDisclosure)
        let buttonImage = UIImage(systemName: "photo.on.rectangle.angled")
        button.setImage(buttonImage, for: .normal)
        view?.rightCalloutAccessoryView = button
    }
}

//MARK: Map Guesture Recognizers
extension MapViewController: UIGestureRecognizerDelegate {
 
    func setUpMapGuestures() {
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(mapLongPressHandler(sender:)))
        longPress.delegate = self
        mapView.addGestureRecognizer(longPress)
    }
    
    @objc func mapLongPressHandler(sender: UILongPressGestureRecognizer) {
        prepareForHaptics(on: true)
        if let map = mapView {
            var currentPoint = sender.location(in: map)

            //Prevents pin being dropped in event users runs finger off the edge of the display
            if gestureIsNearEdgeOfMapView(point: currentPoint) {
                sender.state = .cancelled
            }
            let hiddenByFingerOffset: CGFloat = 30
            currentPoint.y -= hiddenByFingerOffset
            let currentCoordinate = map.convert(currentPoint, toCoordinateFrom: map)
            
            switch sender.state {
            case .began :
                startPlacementPin(forMap: map, at: currentCoordinate)
            case .changed :
                movePlacementPin(to: currentCoordinate)
            case .cancelled :
                abortPinPlacement()
            case .ended :
                dropPin(onMap: map, at: currentCoordinate)
            default:
                abortPinPlacement()
            }
            prepareForHaptics(on: false)
        }
    }
    //TODO: Add haptics
    //MARK: Long Press Began
    func startPlacementPin(forMap map: MKMapView, at coordinate: CLLocationCoordinate2D) {
        placementPin.coordinate = coordinate
        mapView.addAnnotation(placementPin)
        placingHaptic?.selectionChanged()
    }
    
    //MARK: Long Press Changed
    func movePlacementPin(to coordinate: CLLocationCoordinate2D) {
        placementPin.coordinate = coordinate
    }
    
    //MARK: Long Press Abort
    func abortPinPlacement() {
        mapView.removeAnnotation(placementPin)
        errorHaptic?.notificationOccurred(.error)
    }
    
    //MARK: Long Press Ended
    func dropPin(onMap map: MKMapView, at coordinate: CLLocationCoordinate2D) {
        mapView.removeAnnotation(placementPin)

        let pin = Pin(context: dataController.viewContext)
        pin.latitude = coordinate.latitude
        pin.longitude = coordinate.longitude
        pin.title = "Test"
        addAnnotationsFor(pins: [pin])
        currentPins.append(pin)
        openPhotoCollectionFor(pin: pin)
        try? dataController.viewContext.save()
    }
    
}
