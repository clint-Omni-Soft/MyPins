//
//  MapViewController.swift
//  MyPins
//
//  Created by Clint Shank on 3/12/18.
//  Copyright © 2018 Omni-Soft, Inc. All rights reserved.
//


import UIKit
import MapKit



class MapViewController: UIViewController {
    
    // MARK: Public Variables

    @IBOutlet weak var myMapView: MKMapView!
    
    @IBOutlet var addBarButtonItem    : UIBarButtonItem!
    @IBOutlet var mapTypeBarButtonItem: UIBarButtonItem!


    // MARK: Private Variables
    
    private struct Constants {
        static let annotationIdentifier = "AnnotationIdentifier"
        static let mapTypeKey           = "MapType"
        static let noSelection          = -1
    }

    private struct StoryboardIds {
        static let locationEditor = "LocationEditorViewController"
    }

    private var coordinateToCenterMapOn  = CLLocationCoordinate2DMake( 0.0, 0.0 )
    private let deviceAccessControl      = DeviceAccessControl.sharedInstance
    private var ignoreRefresh            = false
    private var locationEstablished      = false
    private var locationManager          : CLLocationManager?
    private var centerMapOnUserLocation  = true
    private let pinCentral               = PinCentral.sharedInstance
    private var routeColor               = UIColor.green
    private var selectedPointAnnotation  : PointAnnotation?
    
    
    
    // MARK: UIViewController Lifecycle Methods
    
    override func viewDidLoad() {
        logTrace()
        super.viewDidLoad()
        
        navigationItem.title = NSLocalizedString( "Title.Map", comment: "Map" )
        
        selectedPointAnnotation = nil
        
        myMapView.delegate          = self
        myMapView.showsCompass      = true
        myMapView.showsScale        = true
        myMapView.showsTraffic      = true
        myMapView.showsUserLocation = true

        setMapTypeFromUserDefaults()
        
        locationManager = CLLocationManager()
        
        locationManager?.delegate = self
        locationManager?.startUpdatingLocation()
        
        locationEstablished = false
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        logTrace()
        super.viewWillAppear( animated )
        
        loadBarButtonItems()

        if !pinCentral.didOpenDatabase {
            pinCentral.openDatabaseWith( self )
        }
        else {
            if !pinCentral.resigningActive {
                refreshMapAnnotations()
            }
            
        }
        
        NotificationCenter.default.addObserver( self, selector: #selector( MapViewController.centerMap(   notification: ) ), name: NSNotification.Name( rawValue: Notifications.centerMap         ), object: nil )
        NotificationCenter.default.addObserver( self, selector: #selector( MapViewController.pinsUpdated( notification: ) ), name: NSNotification.Name( rawValue: Notifications.pinsArrayReloaded ), object: nil )
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        logTrace()
        super.viewWillDisappear( animated )
        
        NotificationCenter.default.removeObserver( self )
    }
    
    

    // MARK: NSNotification Methods
    
    @objc func centerMap( notification: NSNotification ) {
        if let userInfo = notification.userInfo {
            let     latitude   = userInfo[ UserInfo.latitude  ] as! Double
            let     longitude  = userInfo[ UserInfo.longitude ] as! Double
            let     coordinate = CLLocationCoordinate2DMake( latitude, longitude )
            
            if locationEstablished {
                logVerbose( "locationEstablished at [ %f, %f ] ... right now", latitude, longitude )
                zoomInOn( coordinate: coordinate )
                
                for annotation in myMapView.annotations {
                    if let pointAnnotation = annotation as? PointAnnotation {
                        if pinCentral.indexPathOfSelectedPin == pointAnnotation.pinIndexPath {
                            myMapView.selectAnnotation( annotation, animated: true )
                            break
                        }
                        
                    }
                    else {
                        if let name = annotation.title {
                            if name != "My Location" {
                                logVerbose( "ERROR: Could NOT convert annotation[ %@ ] to PointAnnotation!", name ?? "Unknown" )
                            }
                            
                        }
                        else {
                            logVerbose( "ERROR: Could NOT convert annotation to PointAnnotation!" )
                        }
                        
                    }
                    
                }
                
            }
            else {
                logVerbose( "at [ %f, %f ] ... wait for location to be established", latitude, longitude )
                coordinateToCenterMapOn = coordinate
                centerMapOnUserLocation = false
            }
        
        }
        else {
            logTrace( "ERROR: Could NOT unwrap notification.userInfo!" )
        }

    }
    
    
    @objc func pinsUpdated( notification: NSNotification ) {
        logTrace()
        
        // The reason we are using Notifications is because this view can be up in two different places on the iPad at the same time.
        // This approach allows a change in one to immediately be reflected in the other.
        
        refreshMapAnnotations()
    }
    
    
    
    // MARK: Target/Action Methods
    
    @IBAction @objc func addBarButtonItemTouched(_ sender: UIBarButtonItem ) {
        logTrace()
        launchLocationEditorForPinAt( GlobalIndexPaths.newPin )
   }
    
    
    @IBAction func dartBarButtonItemTouched(_ sender: UIBarButtonItem ) {
        logTrace()
        if pinCentral.locationEstablished {
            let     adjustedAltitude = ( ( DisplayUnits.feet == pinCentral.displayUnits() ) ? String.init( format: "%7.1f", ( pinCentral.currentAltitude * GlobalConstants.feetPerMeter ) ) :
                                                                                              String.init( format: "%7.1f",   pinCentral.currentAltitude ) )
            let     message = String( format: "%@, %@\n%7.4f, %7.4f\n\n%@ = %@ %@",
                                      NSLocalizedString( "LabelText.Latitude",  comment: "Latitude"  ),
                                      NSLocalizedString( "LabelText.Longitude", comment: "Longitude" ),
                                      pinCentral.currentLocation.latitude,
                                      pinCentral.currentLocation.longitude,
                                      NSLocalizedString( "LabelText.Altitude",  comment: "Altitude"  ),
                                      adjustedAltitude,
                                      pinCentral.displayUnits() )
            
            presentAlert( title: NSLocalizedString( "AlertTitle.CurrentCoordinates", comment: "Current Coordinates" ), message: message )
        }
        
    }
    
    
    @IBAction @objc func compassBarButtonItemTouched(_ sender: UIBarButtonItem ) {
        logTrace()
        let coordinate = CLLocationCoordinate2DMake( (selectedPointAnnotation?.coordinate.latitude)!, (selectedPointAnnotation?.coordinate.longitude)! )
        let mapItem    = MKMapItem(placemark: MKPlacemark(coordinate: coordinate, addressDictionary: nil) )
        
        mapItem.name = NSLocalizedString( "LabelText.Destination", comment: "Destination"  )
        mapItem.openInMaps( launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving] )
    }
    
    
    @IBAction func homeZoomButtonTouched(_ sender: UIButton ) {
        logTrace()
        zoomInOnUser()
    }
    

    @IBAction func infoBarButtonTouched(_ sender : UIBarButtonItem ) {
        let     message = NSLocalizedString( "InfoText.Map1", comment: "MAP\n\nTouching the plus sign (+) bar button will take you to the Pin Editor where you can associate provide information about that pin.\n\n" ) +
                          NSLocalizedString( "InfoText.Map2", comment: "Touching the 'Map' bar button will produce a popover that will allow you to choose from the supported map display modes.\n\n" ) +
                          NSLocalizedString( "InfoText.Map3", comment: "Touching the 'Dart' bar button will produce a popover that will give the device's current latitude, longitude and altitude.\n\n" ) +
                          NSLocalizedString( "InfoText.Map4", comment: "When you tap on a pin, its description will displayed above it on the map and the 'Compass' bar button will be displayed. " ) +
                          NSLocalizedString( "InfoText.Map5", comment: "Touching the 'Compass' bar button will take you to the Apple Maps app which will display the available routes from your current position to the selected pin.  \n\n" )
        
        presentAlert( title: NSLocalizedString( "AlertTitle.GotAQuestion", comment: "Got a question?" ), message: message )
    }
    
    
    @IBAction @objc func mapTypeBarButtonItemTouched(_ sender: UIBarButtonItem ) {
        logTrace()
        presentMapOptions()
    }
    
    
    
    // MARK: Utility Methods
    
    private func examine(_ pointAnnotation: PointAnnotation ) {
        if let indexPath = pointAnnotation.pinIndexPath {
            let pin = pinCentral.pinAt( indexPath )
            
            if ( ( pointAnnotation.coordinate.latitude != pin.latitude ) || ( pointAnnotation.coordinate.longitude != pin.longitude ) ) {
                self.ignoreRefresh = true
                
                DispatchQueue.main.asyncAfter(deadline: ( .now() + 0.5 ), execute: {
                    self.updatePinCoordinatesUsing( pointAnnotation: pointAnnotation )
                } )
                
            }
            else {
//                logVerbose( "pin[ %d ] coordinates NOT changed!", pinIndex )
            }
            
        }
        else {
            logTrace( "ERROR: pointAnnotation.pinIndex could NOT be unwrapped!" )
        }
            
    }

    
    private func launchLocationEditorForPinAt(_ indexPath: IndexPath ) {
        guard let locationEditorVC: LocationEditorViewController = iPhoneViewControllerWithStoryboardId( storyboardId: StoryboardIds.locationEditor ) as? LocationEditorViewController else {
            logTrace( "ERROR: Could NOT load LocationEditorViewController!" )
            return
        }
        
        logVerbose( "[ %@ ]", stringFor( indexPath ) )
        locationEditorVC.delegate                   = self
        locationEditorVC.indexPathOfItemBeingEdited = indexPath
        locationEditorVC.launchedFromDetailView     = ( .pad == UIDevice.current.userInterfaceIdiom )
        
        if GlobalConstants.newPin == indexPath.section {
            locationEditorVC.centerOfMap    = myMapView.centerCoordinate
            locationEditorVC.useCenterOfMap = true
        }
        else {
            locationEditorVC.useCenterOfMap = false
        }
        
        if .phone == UIDevice.current.userInterfaceIdiom {
            navigationController?.pushViewController( locationEditorVC, animated: true )
        }
        else {
            let     navigationController = UINavigationController.init( rootViewController: locationEditorVC )
            
            navigationController.modalPresentationStyle = .popover
            navigationController.preferredContentSize   = CGSize( width: 400, height: 600 )

            navigationController.popoverPresentationController?.delegate                 = self
            navigationController.popoverPresentationController?.permittedArrowDirections = .any
            navigationController.popoverPresentationController?.sourceRect               = CGRectMake( 50, 20, 50, 50 )
            navigationController.popoverPresentationController?.sourceView               = view
            
            present( navigationController, animated: true, completion: nil )
        }
        
    }
    
    
    private func loadBarButtonItems() {
        logTrace()
        let dartBarButtonItem  = UIBarButtonItem.init( image: UIImage(named: "dart" ), style: .plain, target: self, action: #selector( dartBarButtonItemTouched(_:) ) )
        let infoBarButtonItem  = UIBarButtonItem.init( image: UIImage(named: "info" ), style: .plain, target: self, action: #selector( infoBarButtonTouched(_:) ) )
        var leftBarButtonItems = [infoBarButtonItem, dartBarButtonItem]
        
        if let _ = selectedPointAnnotation {
            let compassBarButtonItem = UIBarButtonItem.init( image: UIImage(named: "compass" ), style: .plain, target: self, action: #selector( compassBarButtonItemTouched(_:) ) )
            
            leftBarButtonItems.append( compassBarButtonItem )
        }

        addBarButtonItem     = UIBarButtonItem.init( barButtonSystemItem: .add,  target: self, action: #selector( addBarButtonItemTouched(_:) ) )
        mapTypeBarButtonItem = UIBarButtonItem.init( image: UIImage(named: "mapType" ), style: .plain, target: self, action: #selector( mapTypeBarButtonItemTouched(_:) ) )

        navigationItem.leftBarButtonItems  = leftBarButtonItems
        navigationItem.rightBarButtonItems = deviceAccessControl.byMe ? [addBarButtonItem, mapTypeBarButtonItem] : [mapTypeBarButtonItem]

//        directionsBarButtonItem.isEnabled = false
    }


    private func presentMapOptions() {
        logTrace()
        let     alert = UIAlertController.init( title: NSLocalizedString( "AlertTitle.SelectMapType", comment: "Select Map Type" ), message: nil, preferredStyle: .actionSheet )
        
        let     hybridAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.Hybrid", comment: "Hybrid" ), style: .default )
        { ( alertAction ) in
            self.myMapView.mapType = .hybrid
            self.saveMapTypeInUserDefaults( mapType: MapTypes.eHybrid )
        }

        let     hybridFlyoverAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.HybridFlyover", comment: "Hybrid Flyover" ), style: .default )
        { ( alertAction ) in
            self.myMapView.mapType = .hybridFlyover
            self.saveMapTypeInUserDefaults( mapType: MapTypes.eHybridFlyover )
        }

        let     mutedStandardAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.MutedStandard", comment: "Muted Standard" ), style: .default )
        { ( alertAction ) in
            self.myMapView.mapType = .mutedStandard
            self.saveMapTypeInUserDefaults( mapType: MapTypes.eMutedStandard )
        }

        let     satelliteAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.Satellite", comment: "Satellite" ), style: .default )
        { ( alertAction ) in
            self.myMapView.mapType = .satellite
            self.saveMapTypeInUserDefaults( mapType: MapTypes.eSatellite )
        }
        
        let     satelliteFlyoverAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.SatelliteFlyover", comment: "Satellite Flyover" ), style: .default )
        { ( alertAction ) in
            self.myMapView.mapType = .satelliteFlyover
            self.saveMapTypeInUserDefaults( mapType: MapTypes.eSatelliteFlyover )
        }
        
        let     standardAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.Standard", comment: "Standard" ), style: .default )
        { ( alertAction ) in
            self.myMapView.mapType = .standard
            self.saveMapTypeInUserDefaults( mapType: MapTypes.eStandard )
        }
        
        let     cancelAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.Cancel", comment: "Cancel" ), style: .cancel, handler: nil )

        alert.addAction( hybridAction           )
        alert.addAction( hybridFlyoverAction    )
        alert.addAction( mutedStandardAction    )
        alert.addAction( satelliteAction        )
        alert.addAction( satelliteFlyoverAction )
        alert.addAction( standardAction         )
        alert.addAction( cancelAction )
        
        if .pad == UIDevice.current.userInterfaceIdiom {
            modalPresentationStyle = .popover
            
            present( alert, animated: true, completion: nil )
            
            alert.popoverPresentationController?.delegate                 = self
            alert.popoverPresentationController?.permittedArrowDirections = .any
            alert.popoverPresentationController?.barButtonItem            = mapTypeBarButtonItem
        }
        else {
            present( alert, animated: true, completion: nil )
        }
        
    }
    
    
    private func refreshMapAnnotations() {
        logTrace()
        var     annotationArray:[PointAnnotation] = Array.init()
        
        myMapView.removeAnnotations( myMapView.annotations )
        
        if !pinCentral.pinArrayOfArrays.isEmpty {
            for section in 0...( pinCentral.pinArrayOfArrays.count - 1 ) {
                let sectionArray = pinCentral.pinArrayOfArrays[section]
                
                if !sectionArray.isEmpty {
                    for row in 0...( sectionArray.count - 1 ) {
                        let pin       = sectionArray[row]
                        let indexPath = IndexPath(row: row, section: section )
                        let annotation: PointAnnotation = PointAnnotation.init()

                        annotation.initWith( pin, atIndexPath: indexPath )
                        annotationArray.append( annotation )
                    }

                }

            }

        }
        
        if 0 < annotationArray.count {
            myMapView.addAnnotations( annotationArray )
        }
        
        logVerbose( "Added [ %d ] pins", annotationArray.count )
    }
    
   
    private func saveMapTypeInUserDefaults( mapType: Int ) {
        UserDefaults.standard.set( mapType, forKey: Constants.mapTypeKey )
        UserDefaults.standard.synchronize()
    }
    
    
    private func setMapTypeFromUserDefaults() {
        let     savedMapType = UserDefaults.standard.integer( forKey: Constants.mapTypeKey )
        var     typeName     = "Standard"
        
        switch savedMapType {
        case MapTypes.eHybrid:             myMapView.mapType = .hybrid;             typeName = "Hybrid"
        case MapTypes.eHybridFlyover:      myMapView.mapType = .hybridFlyover;      typeName = "Hybrid Flyover"
        case MapTypes.eMutedStandard:      myMapView.mapType = .mutedStandard;      typeName = "Muted Standard"
        case MapTypes.eSatellite:          myMapView.mapType = .satellite;          typeName = "Satellite"
        case MapTypes.eSatelliteFlyover:   myMapView.mapType = .satelliteFlyover;   typeName = "Satellite Flyover"
        default:                           myMapView.mapType = .standard
        }
        
        logVerbose( "[ %d ][ %@ ]", savedMapType, typeName )
    }
    
    
    private func updatePinCoordinatesUsing( pointAnnotation: PointAnnotation ) {
        if let indexPath = pointAnnotation.pinIndexPath {
            let pin = pinCentral.pinAt( indexPath )
            logVerbose( "Changing pin[ %@ ][ %f, %f ] -> [ %f, %f ]", stringFor( indexPath ), pin.latitude, pin.longitude, pointAnnotation.coordinate.latitude, pointAnnotation.coordinate.longitude )

            pin.latitude  = pointAnnotation.coordinate.latitude
            pin.longitude = pointAnnotation.coordinate.longitude
            
            pinCentral.saveUpdated( pin, self )
        }
        else {
            logVerbose( "ERROR: pointAnnotation.pinIndexPath cound NOT be unwrapped!" )
        }
        
    }
    
    
    private func zoomInOnUser() {
        guard let coordinate = myMapView.userLocation.location?.coordinate else {
            logTrace( "no data yet... waiting" )
            return
        }
        
        zoomInOn( coordinate: coordinate )
        locationEstablished = true
    }
    
    
    private func zoomInOn( coordinate: CLLocationCoordinate2D ) {
        let     region = MKCoordinateRegion.init( center: coordinate, latitudinalMeters: 2000, longitudinalMeters: 2000 )
        
        logVerbose( "[ %f, %f ]", coordinate.latitude, coordinate.longitude )
        myMapView.setRegion( region, animated: true )
    }


}



// MARK: CLLocationManagerDelegate Methods

extension MapViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error ) {
        logVerbose( "[ %@ ]", error.localizedDescription )
//        presentAlert( title: NSLocalizedString( "AlertTitle.Error", comment: "Error!" ), message: error.localizedDescription )
    }
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation] ) {
        if !locationEstablished && centerMapOnUserLocation {
//            logTrace()
            self.zoomInOnUser()
        }
        
    }
    

}


// MARK: LocationEditorViewControllerDelegate Methods

extension MapViewController: LocationEditorViewControllerDelegate {
    
    func locationEditorViewController(_ locationEditorViewController: LocationEditorViewController, didEditLocationData: Bool ) {
        logVerbose( "didEditLocationData[ %@ ]", stringFor( didEditLocationData ) )
        
        refreshMapAnnotations()
        
        if GlobalConstants.newPin != pinCentral.newPinIndexPath.section {
            let     newPin = pinCentral.pinAt( pinCentral.newPinIndexPath )
            
            centerMapOnUserLocation = false
            coordinateToCenterMapOn = CLLocationCoordinate2DMake( newPin.latitude, newPin.longitude )
            logVerbose( "center map on pin[ %@ ]", stringFor( pinCentral.newPinIndexPath ) )
        }
        
    }
    
    
}



// MARK: MKMapViewDelegate Methods

extension MapViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl ) {
        if !deviceAccessControl.byMe {
            return
        }
        
        if view.annotation is PointAnnotation {
            if let pointAnnotation = view.annotation as? PointAnnotation,
               let indexPath       = pointAnnotation.pinIndexPath {
                logVerbose( "Requesting edit of pin at index[ %@ ]", stringFor( indexPath ) )
                launchLocationEditorForPinAt( indexPath )
            }
            else {
                logTrace( "ERROR: Could NOT convert view.annotation to PointAnnotation OR pointAnnotation.pinIndex could NOT be unwrapped!" )
            }

        }
        else if view.annotation is MKUserLocation {
            logVerbose( "Got a MKUserLocation ... ignoring" )
        }
        else {
            logTrace( "Whazat???" )
        }
        
    }
    
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, didChange newState: MKAnnotationView.DragState, fromOldState oldState: MKAnnotationView.DragState ) {
        if let pointAnnotation = view.annotation as? PointAnnotation {
//            logVerbose( "[ %f, %f ]  [ %@ ]->[ %@ ]", pointAnnotation.coordinate.latitude, pointAnnotation.coordinate.longitude, titleForDragState( state: oldState ), titleForDragState( state: newState ) )
            
            switch newState {
            case .dragging:             break
            case .starting:             view.dragState = .dragging
            case .canceling, .ending:   view.dragState = .none
                                        examine( pointAnnotation )
            default:    // .none
                
                // This ia KLUDGE!  For some reason we don't get .canceling or .end after some dragging events start
                //  ... instead we get a .none even though the pin was moved!  This allows us to capture that data.
                
                examine( pointAnnotation )
                break
            }

        }
        else {
            logTrace( "ERROR: Could NOT convert view.annotation to PointAnnotation!" )
        }
        
    }
    
    
    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView ) {
        if let pointAnnotation = view.annotation as? PointAnnotation,
           let indexPath = pointAnnotation.pinIndexPath {
            logVerbose( "pin[ %d, %d ] @ [ %f, %f ] ", indexPath.section, indexPath.row, pointAnnotation.coordinate.latitude, pointAnnotation.coordinate.longitude )
            
            examine( pointAnnotation )
        }
//        else {
//            logTrace( "ERROR: Could NOT convert view.annotation to PointAnnotation OR could NOT unwrap pointAnnotation.pinIndex!" )
//        }

        selectedPointAnnotation = nil
        loadBarButtonItems()
    }
    
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView ) {
        if view.annotation is MKUserLocation {
            return
        }
        
        if let pointAnnotation = view.annotation as? PointAnnotation,
           let indexPath = pointAnnotation.pinIndexPath {
            logVerbose( "pin[ %d, %d ] @ [ %f, %f ] ", indexPath.section, indexPath.row, pointAnnotation.coordinate.latitude, pointAnnotation.coordinate.longitude )
            selectedPointAnnotation = pointAnnotation
            loadBarButtonItems()
        }
        else {
            logTrace( "ERROR: Could NOT convert view.annotation to PointAnnotation OR could NOT unwrap pointAnnotation.pinIndex!" )
        }
        
    }
    
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation ) {
        // NOTE: When you set this the mapView immediately centers on the user's location,
        // Consequently, you don't want to be doing this a lot or it will frustrate the user

        if !locationEstablished {
            if centerMapOnUserLocation {
                if let location = userLocation.location {
                    logVerbose( "Centering map on user location[ %f, %f ] ", location.coordinate.latitude, location.coordinate.longitude )
                    zoomInOn( coordinate: location.coordinate )
                }
                else {
                    logTrace( "ERROR: Could NOT unwrap userLocation.location!" )
                }
            }
            else {
                logVerbose( "Centering map on [ %f, %f ] as requested by PinEdit[0]", coordinateToCenterMapOn.longitude, coordinateToCenterMapOn.latitude )
                centerMapOnUserLocation = true
                zoomInOn( coordinate: coordinateToCenterMapOn )
            }

            locationEstablished = true
        }
        else if !centerMapOnUserLocation {
            logVerbose( "Centering map on [ %f, %f ] as requested by PinEdit[1]", coordinateToCenterMapOn.longitude, coordinateToCenterMapOn.latitude )
            centerMapOnUserLocation = true
            zoomInOn( coordinate: coordinateToCenterMapOn )
        }

    }
    

    func mapView(_ mapView: MKMapView, didFailToLocateUserWithError error: Error ) {
        logVerbose( "ERROR: [ %@ ]", error.localizedDescription )
//        presentAlert( title: NSLocalizedString( "AlertTitle.Error", comment: "Error!" ), message: error.localizedDescription )
    }
    
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay ) -> MKOverlayRenderer {
//        logTrace()
        if overlay is MKPolyline {
            let     polylineRenderer = MKPolylineRenderer( overlay: overlay )
            
            polylineRenderer.lineWidth   = 3
            polylineRenderer.strokeColor = routeColor
            
            routeColor = UIColor.yellow
            
            return polylineRenderer
        }
        
        return MKOverlayRenderer()
    }
    
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation ) -> MKAnnotationView? {
        if annotation is MKUserLocation {
//            logTrace( "Our location" )
            return nil      // This allows us to retain the blue dot & circle animation for the user's location (instead of our mapPin image)
        }
        
        let     annotationView    = mapView.dequeueReusableAnnotationView( withIdentifier: Constants.annotationIdentifier )
        let     pinAnnotationView : MKPinAnnotationView!
        let     pointAnnotation   = annotation as! PointAnnotation
        let     pin               = pinCentral.pinAt( pointAnnotation.pinIndexPath! )
        
        
        guard annotationView != nil else {
//            logTrace( "Creating New Pin" )
            pinAnnotationView = MKPinAnnotationView( annotation: annotation, reuseIdentifier: Constants.annotationIdentifier )
            
            pinAnnotationView.animatesDrop   = true
            pinAnnotationView.canShowCallout = true
            pinAnnotationView.isDraggable    = true
            pinAnnotationView.pinTintColor   = pinColorArray[Int( pin.pinColor )]
            pinAnnotationView.rightCalloutAccessoryView = UIButton( type: .detailDisclosure )
            
            return pinAnnotationView
        }
        
        if let pinAnnotationView = annotationView as? MKPinAnnotationView {
//            logTrace( "Use Existing Pin" )
            pinAnnotationView.annotation     = annotation
            pinAnnotationView.animatesDrop   = true
            pinAnnotationView.canShowCallout = true
            pinAnnotationView.isDraggable    = true
            pinAnnotationView.pinTintColor   = pinColorArray[Int( pin.pinColor )]
            pinAnnotationView.rightCalloutAccessoryView = UIButton( type: .detailDisclosure )

            return pinAnnotationView
        }
            
        logTrace( "ERROR: Could NOT convert annotationView to MKPinAnnotationView!" )
        return nil
    }
    
    
    func mapViewDidStopLocatingUser(_ mapView: MKMapView ) {
//        logTrace()
    }
    
    
    func mapViewWillStartLocatingUser(_ mapView: MKMapView ) {
//        logTrace()
    }

    
    
    // MARK: MKMapViewDelegate Utility Methods

    private func titleForDragState( state: MKAnnotationView.DragState ) -> String {
        var     title = "none     "
        
        switch state {
        case .canceling:    title = "canceling"
        case .dragging:     title = "dragging "
        case .ending:       title = "ending   "
        case .starting:     title = "starting "
        default: break
        }
        
        return title
    }


}


// MARK: PinCentralDelegate Methods

extension MapViewController: PinCentralDelegate {
    
    func pinCentral(_ pinCentral: PinCentral, didOpenDatabase: Bool ) {
        logVerbose( "[ %@ ]", stringFor( didOpenDatabase ) )
        
        if didOpenDatabase {
            pinCentral.fetchPinsWith( self )
        }
        else {
            presentAlert( title:   NSLocalizedString( "AlertTitle.Error", comment: "Error!" ),
                          message: NSLocalizedString( "AlertMessage.CannotOpenDatabase", comment: "Fatal ERROR: Cannot open database." ) )
        }

    }
    
    
    func pinCentralDidReloadPinArray(_ pinCentral: PinCentral ) {
        logVerbose( "loaded [ %d ] pins ... ignoreRefresh[ %@ ]", pinCentral.numberOfPinsLoaded, stringFor( ignoreRefresh ) )
        
        if ignoreRefresh {
            ignoreRefresh = false
        }
        else {
            refreshMapAnnotations()
        }

    }
    
    
}



// MARK: UIPopoverPresentationControllerDelegate Methods

extension MapViewController: UIPopoverPresentationControllerDelegate {
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.none
    }
    
    
}
