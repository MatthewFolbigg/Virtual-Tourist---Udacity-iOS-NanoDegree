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
    
    //MARK: Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpGuestures()
        placementPin = getTemporaryPin()
        
    }
    
}

//MARK: Map View Delegate
extension MapViewController: MKMapViewDelegate {
    
    //MARK: Map Annotation Views
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
       
        if annotation.title == "TemporaryPlacementPin" {
            if let placementView = mapView.dequeueReusableAnnotationView(withIdentifier: "placementView") {
                return placementView
            } else {
                let placementView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "placementView")
                setTemporaryPinView(view: placementView)
                return placementView
            }
        } else {
        
            if let droppedPinView = mapView.dequeueReusableAnnotationView(withIdentifier: "droppedPinView") {
                return droppedPinView
            } else {
                let droppedPinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "droppedPinView")
                setDroppedPinView(view: droppedPinView)
                return droppedPinView
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
    
    //MARK: Annotation UIs
    //UI for placement guide pin
    func setTemporaryPinView(view: MKPinAnnotationView) {
        view.animatesDrop = true
        view.pinTintColor = .red
        view.alpha = 0.5
    }
    
    //UI for dropped pin
    func setDroppedPinView(view: MKPinAnnotationView) {
        view.animatesDrop = false
        view.pinTintColor = .red
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
        
        let currentPoint = sender.location(in: mapView)
        let currentCoordinate = mapView.convert(currentPoint, toCoordinateFrom: mapView)
        let map = mapView!
        
        switch sender.state {
        case .began :
            createPin(forMap: map, at: currentCoordinate)
        case .changed :
            longPressMoved(to: currentCoordinate)
        case .cancelled :
            print("cancelled")
        case .possible :
            print("possible")
        case .ended :
            dropPin(onMap: map, at: currentCoordinate)
        default: break
        }
    }
    
    //TODO: Add haptics
    //MARK: Long Press Began
    func createPin(forMap map: MKMapView, at coordinate: CLLocationCoordinate2D) {
        placementPin.coordinate = coordinate
        mapView.addAnnotation(placementPin)
    }
    
    //MARK: Long Press Changed
    func longPressMoved(to coordinate: CLLocationCoordinate2D) {
        placementPin.coordinate = coordinate
    }
    
    //MARK: Long Press Ended
    func dropPin(onMap map: MKMapView, at coordinate: CLLocationCoordinate2D) {
        mapView.removeAnnotation(placementPin)
        let droppedPin = MKPointAnnotation()
        droppedPin.coordinate = coordinate
        mapView.addAnnotation(droppedPin)
    }
}

