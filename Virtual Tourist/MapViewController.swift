//
//  ViewController.swift
//  Virtual Tourist
//
//  Created by Christopher Weaver on 8/17/16.
//  Copyright © 2016 Christopher Weaver. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController, MKMapViewDelegate, UIGestureRecognizerDelegate {
    
    var fetchedResultsController: NSFetchedResultsController<Pin>!
    
    let fr = NSFetchRequest<Pin>(entityName: "Pin")
    let sortDescriptors = [NSSortDescriptor(key: "latitude", ascending: true),
    NSSortDescriptor(key: "longitude", ascending: false)]
    
    
    let delegate = UIApplication.shared.delegate as! AppDelegate
    
    var deleteAllowed: Bool = false
    
    var appHadStarted: Bool = false
    
    var annotations = [MKPointAnnotation]()
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var deleteTextView: UITextView!
    @IBOutlet weak var doneEditingButton: UIButton!
    
    @IBAction func doneEditingPushed(_ sender: AnyObject) {
        deleteAllowed = false
        doneEditingButton.isHidden = true
        editButton.isEnabled = true
        
        deleteTextView.frame.origin.y = (view.frame.height - deleteTextView.frame.height)
        
        UIView.beginAnimations(nil, context: nil)
        deleteTextView.frame.origin.y = view.frame.height
        mapView.frame.origin.y = 0
        UIView.commitAnimations()
        
        appHadStarted = true
    }
    
    @IBAction func editButtonPushed(_ sender: AnyObject) {
        deleteTextView.frame.origin.y = view.frame.height
        deleteTextView.isHidden = false
        doneEditingButton.isHidden = false
        editButton.isEnabled = false
        
        UIView.beginAnimations(nil, context: nil)
        deleteTextView.frame.origin.y -= deleteTextView.frame.height
        mapView.frame.origin.y -= deleteTextView.frame.height
        UIView.commitAnimations()
        
        deleteAllowed = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        
        doneEditingButton.isHidden = true
        deleteTextView.isHidden = true
        
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action:#selector(MapViewController.handleTap(_:)))
        gestureRecognizer.minimumPressDuration = 1.0
        gestureRecognizer.allowableMovement = 1
        gestureRecognizer.delegate = self
        mapView.addGestureRecognizer(gestureRecognizer)
        
        UIView.setAnimationDuration(0.5)
        UIView.setAnimationDelegate(self)
        UIView.setAnimationBeginsFromCurrentState(true)
        
        
        fr.sortDescriptors = sortDescriptors
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fr, managedObjectContext: (delegate.stack?.context)!, sectionNameKeyPath: nil, cacheName: nil)
        
        performFetch()
        
        for i in fetchedResultsController.fetchedObjects! {
            let managed = i as? NSManagedObject
            let managed2 = managed as? Pin
            let lat = CLLocationDegrees((managed2?.latitude)!)
            let long = CLLocationDegrees((managed2?.longitude)!)
            let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            annotations.append(annotation)
            generateMap()
        }
    }
    
    func generateMap() {
        mapView.addAnnotations(annotations)
    }
    
    func handleTap(_ gestureReconizer: UILongPressGestureRecognizer) {
        if (gestureReconizer.state == UIGestureRecognizerState.began) {
            if !deleteAllowed {
                let location = gestureReconizer.location(in: mapView)
                
                let coordinate = mapView.convert(location,toCoordinateFrom: mapView)
                
                let annotation = MKPointAnnotation()
                annotation.coordinate = coordinate
                
                annotations.append(annotation)
                
                generateMap()
                
                let newPin = Pin(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude, context: (self.fetchedResultsController.managedObjectContext))
                
                delegate.stack?.save()
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseId = "pins"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.pinColor = .red
        }
        else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {

        fr.sortDescriptors = sortDescriptors
        
        let pred1 = NSPredicate(format: "latitude = %@", argumentArray: [(view.annotation?.coordinate.latitude)!])
        
        let pred2 = NSPredicate(format: "longitude = %@", argumentArray: [(view.annotation?.coordinate.longitude)!])
        
        let andPredicate = NSCompoundPredicate(type: NSCompoundPredicate.LogicalType.and, subpredicates: [pred1, pred2])
        
        fr.predicate = andPredicate
        
        performFetch()
        
        let pinResults = fetchedResultsController?.fetchedObjects
        
        let selectedPin = pinResults![0]
 
            if deleteAllowed {
                var indexCounter = 0
                for items in annotations {
                    if selectedPin.latitude as! Double == items.coordinate.latitude && selectedPin.longitude as! Double == items.coordinate.longitude  {
                        mapView.removeAnnotations(annotations)
                        annotations.remove(at: indexCounter)
                        fetchedResultsController.managedObjectContext.delete(selectedPin)
                        delegate.stack?.save()
                        generateMap()
                        return
                    }
                    indexCounter += 1
                }
            } else {
                let CollectionVC = self.storyboard!.instantiateViewController(withIdentifier: "CollectionViewController") as! CollectionViewController
                CollectionVC.pin = selectedPin
                
                self.navigationController!.pushViewController(CollectionVC, animated: true)
                
                mapView.deselectAnnotation(view.annotation, animated: false)
                
                deleteTextView.isHidden = true
            }
        }
    
    func performFetch() {
        
        do{
            try fetchedResultsController.performFetch()
        }catch {
            print("Error while trying to perform a search")
        }
    }
    
    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        
        if deleteAllowed {
            deleteTextView.frame.origin.y = (view.frame.height - deleteTextView.frame.height)
            mapView.frame.origin.y = (0 - deleteTextView.frame.height)
        } else {
            deleteTextView.frame.origin.y = view.frame.height
            mapView.frame.origin.y = 0
        }
    }
}
