//
//  ViewController.swift
//  Virtual Tourist - Udacity iOS NanoDegree
//
//  Created by Matthew Folbigg on 01/03/2021.
//

import UIKit
import MapKit

class MapViewController: UIViewController {

    //MARK: IB Outlets
    @IBOutlet var mapView: MKMapView!
    
    //MARK: Variables
    var placementPin: MKPointAnnotation!
    var dropHaptic: UIImpactFeedbackGenerator?
    var placingHaptic: UISelectionFeedbackGenerator?
    var dragHaptic: UISelectionFeedbackGenerator?
    var errorHaptic: UINotificationFeedbackGenerator?
    
    //MARK: Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpGuestures()
        placementPin = getTemporaryPin()
        
        //TEST
        FlickrApiClient.getPhotoInformationFor(Latitude: "50", Longitude: "33") { (photosInfo) in
            for photo in photosInfo {
                print(photo.id)
            }
        }
        
    }
    
    func prepareForHaptics(on: Bool) {
        if on {
            placingHaptic = on ? UISelectionFeedbackGenerator() : nil
            placingHaptic?.prepare()
            dropHaptic = on ? UIImpactFeedbackGenerator(style: .rigid) : nil
            dragHaptic = on ? UISelectionFeedbackGenerator() : nil
            errorHaptic = on ? UINotificationFeedbackGenerator() : nil
        }
    }
    
}

//MARK: Map View Delegate
extension MapViewController: MKMapViewDelegate {
    
    //MARK: Map Annotation Views
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
       
        switch annotation.title { //TODO: Find a better way to differentiate annotation type
        case "TemporaryPlacementPin":
            if let placementView = mapView.dequeueReusableAnnotationView(withIdentifier: "placementView") {
                return placementView
            } else {
                let placementView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "placementView")
                setTemporaryPinUI(for: placementView)
                return placementView
            }
            
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
        //Callout Accessory
        view?.canShowCallout = true
        view?.leftCalloutAccessoryView = UIImageView(image: UIImage(systemName: "binoculars.fill"))
        view?.leftCalloutAccessoryView?.tintColor = .purple
    }
}

//MARK: Map Guesture Recognizers
extension MapViewController: UIGestureRecognizerDelegate {
 
    func setUpGuestures() {
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(mapLongPressHandler(sender:)))
        longPress.delegate = self
        mapView.addGestureRecognizer(longPress)
    }
    
    @objc func mapLongPressHandler(sender: UILongPressGestureRecognizer) {
        prepareForHaptics(on: true)
        var currentPoint = sender.location(in: mapView)
        let hiddenByFingerOffset: CGFloat = 30
        
        //Prevents pin being dropped in event users runs finger off the edge of the display
        if isNearEdgeOfMap(point: currentPoint) == true {
            sender.state = .cancelled
        }
        
        currentPoint.y -= hiddenByFingerOffset
        let currentCoordinate = mapView.convert(currentPoint, toCoordinateFrom: mapView)
        let map = mapView!
        
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
        let droppedPin = MKPointAnnotation()
        droppedPin.coordinate = coordinate
        droppedPin.title = "\(coordinate.latitude.rounded()) : \(coordinate.longitude.rounded())"
        mapView.addAnnotation(droppedPin)
        dropHaptic?.impactOccurred()
    }
    
    func isNearEdgeOfMap(point: CGPoint) -> Bool {
        let displayRect = mapView.bounds
        
        let border: CGFloat = 5
        
        if point.x < border || point.x > displayRect.maxX - border ||
        point.y < border || point.y > displayRect.maxY - border {
            return true
        } else {
            return false
        }
    }
}

