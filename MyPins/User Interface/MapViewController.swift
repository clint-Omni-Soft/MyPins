//
//  MapViewController.swift
//  MyPins
//
//  Created by Clint Shank on 3/12/18.
//  Copyright © 2018 Omni-Soft, Inc. All rights reserved.
//


import UIKit
import MapKit



class MapViewController: UIViewController,
                         CLLocationManagerDelegate,
                         LocationEditorViewControllerDelegate,
                         MKMapViewDelegate,
                         PinCentralDelegate,
                         UIPopoverPresentationControllerDelegate
{
    let     KEY_MAP_TYPE                  = "MapType"
    let     NO_SELECTION                  = -1
    let     STORYBOARD_ID_LOCATION_EDITOR = "LocationEditorViewController"

    struct MapTypes
    {
        static let eStandard         = 0
        static let eSatellite        = 1
        static let eHybrid           = 2
        static let eSatelliteFlyover = 3
        static let eHybridFlyover    = 4
        static let eMutedStandard    = 5
    }

    
    
    @IBOutlet weak var myMapView:               MKMapView!
    
    @IBOutlet var addBarButtonItem:        UIBarButtonItem!
    @IBOutlet var directionsBarButtonItem: UIBarButtonItem!
    @IBOutlet var mapTypeBarButtonItem:    UIBarButtonItem!

    private var coordinateToCenterMapOn  = CLLocationCoordinate2DMake( 0.0, 0.0 )
    private var ignoreRefresh            = false
    private var locationEstablished      = false
    private var locationManager          : CLLocationManager?
    private var centerMapOnUserLocation  = true
    private var routeColor               = UIColor.green
    private var selectedPointAnnotation  : PointAnnotation?
    private var showingDirectionsOverlay = false
    private var showingPinEditor         = false
    
    
    
    // MARK: UIViewController Lifecycle Methods
    
    override func viewDidLoad()
    {
        logTrace()
        super.viewDidLoad()
        
        title = NSLocalizedString( "Title.Map", comment: "Map" )
        
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
    
    
    override func viewWillAppear(_ animated: Bool)
    {
        logTrace()
        super.viewWillAppear( animated )
        

        let     pinCentral = PinCentral.sharedInstance

        
        loadBarButtonItems()
        
        pinCentral.delegate = self
        
        if showingPinEditor
        {
            showingPinEditor = false
        }
        else
        {
            if !pinCentral.didOpenDatabase
            {
                pinCentral.openDatabase()
            }
            else
            {
                refreshMapAnnotations()
            }

        }
        
        NotificationCenter.default.addObserver( self,
                                                selector: #selector( MapViewController.centerMap( notification: ) ),
                                                name:     NSNotification.Name( rawValue: NOTIFICATION_CENTER_MAP ),
                                                object:   nil )
        NotificationCenter.default.addObserver( self,
                                                selector: #selector( MapViewController.pinsUpdated( notification: ) ),
                                                name:     NSNotification.Name( rawValue: NOTIFICATION_PINS_UPDATED ),
                                                object:   nil )
    }
    
    
    override func viewWillDisappear(_ animated: Bool)
    {
        logTrace()
        super.viewWillDisappear( animated )
        
        NotificationCenter.default.removeObserver( self )
    }
    
    
    override func didReceiveMemoryWarning()
    {
        logTrace( "MEMORY WARNING!!!" )
        super.didReceiveMemoryWarning()
    }
    
    
    
    // MARK: CLLocationManagerDelegate Methods
    
    func locationManager(_ manager: CLLocationManager,
                           didFailWithError error: Error )
    {
        logVerbose( "[ %@ ]", error.localizedDescription )
//        presentAlert( title: NSLocalizedString( "AlertTitle.Error", comment: "Error!" ),
//                      message: error.localizedDescription )
    }
    
    
    func locationManager(_ manager: CLLocationManager,
                           didUpdateLocations locations: [CLLocation] )
    {
        if !locationEstablished && centerMapOnUserLocation
        {
            logTrace()
            self.zoomInOnUser()
        }
        
    }
    
    
    
    // MARK: LocationEditorViewControllerDelegate Methods
    
    func locationEditorViewController( locationEditorViewController: LocationEditorViewController,
                                       didEditLocationData: Bool )
    {
        logVerbose( "didEditLocationData[ %@ ]", stringFor( didEditLocationData ) )
        let     pinCentral = PinCentral.sharedInstance
        
        
        pinCentral.delegate = self
        
        refreshMapAnnotations()
        
        if NEW_PIN != pinCentral.newPinIndex
        {
            let     newPin = pinCentral.pinArray[pinCentral.newPinIndex]
            
            
            centerMapOnUserLocation = false
            coordinateToCenterMapOn = CLLocationCoordinate2DMake( newPin.latitude, newPin.longitude )
            logVerbose( "center map on pin[ %d ]", pinCentral.newPinIndex )
        }
        
    }
    
    
    func locationEditorViewController( locationEditorViewController: LocationEditorViewController,
                                       wantsToCenterMapAt coordinate: CLLocationCoordinate2D )
    {
        logTrace()
        coordinateToCenterMapOn = coordinate
        centerMapOnUserLocation = false
    }
    
    
    
    // MARK: MKMapViewDelegate Methods
    
    func mapView(_ mapView: MKMapView,
                   annotationView view: MKAnnotationView,
                   calloutAccessoryControlTapped control: UIControl )
    {
        if view.annotation is PointAnnotation
        {
            if let pointAnnotation = view.annotation as? PointAnnotation,
               let index           = pointAnnotation.pinIndex
            {
//              logVerbose( "Requesting edit of pin at index[ %@ ]", String( index ) )
                launchLocationEditorForPinAt( index: index )
            }
            else
            {
                logTrace( "ERROR: Could NOT convert view.annotation to PointAnnotation OR pointAnnotation.pinIndex could NOT be unwrapped!" )
            }

        }
        else if view.annotation is MKUserLocation
        {
//            logVerbose( "Got a MKUserLocation ... ignoring" )
        }
        else
        {
            logTrace( "Whazat???" )
        }
        
    }
    
    
    func mapView(_ mapView: MKMapView,
                   annotationView view: MKAnnotationView,
                   didChange newState: MKAnnotationViewDragState,
                   fromOldState oldState: MKAnnotationViewDragState )
    {
        if let pointAnnotation = view.annotation as? PointAnnotation
        {
//        logVerbose( "[ %f, %f ]  [ %@ ]->[ %@ ]", pointAnnotation.coordinate.latitude, pointAnnotation.coordinate.longitude, titleForDragState( state: oldState ), titleForDragState( state: newState ) )
            
            switch newState
            {
            case .dragging: break
                
            case .starting:
                view.dragState = .dragging
                
            case .canceling, .ending:
                view.dragState = .none
                examinePointAnnotation( pointAnnotation: pointAnnotation )
                
            default:    // .none
                
                // This ia KLUDGE!  For some reason we don't get .canceling or .end after some dragging events start
                //  ... instead we get a .none even though the pin was moved!  This allows us to capture that data.
                
                examinePointAnnotation( pointAnnotation: pointAnnotation )
                break
            }

        }
        else
        {
            logTrace( "ERROR: Could NOT convert view.annotation to PointAnnotation!" )
        }
        
    }
    
    
    func mapView(_ mapView: MKMapView,
                   didDeselect view: MKAnnotationView )
    {
//        logTrace()
        directionsBarButtonItem.isEnabled = false
        selectedPointAnnotation           = nil
    }
    
    
    func mapView(_ mapView: MKMapView,
                   didSelect view: MKAnnotationView )
    {
        if view.annotation is MKUserLocation
        {
            return
        }
        
        if let pointAnnotation = view.annotation as? PointAnnotation,
           let pinIndex        = pointAnnotation.pinIndex
        {
            directionsBarButtonItem.isEnabled = true
            selectedPointAnnotation           = pointAnnotation
            
            logVerbose( "selected pin[ %d ]", pinIndex )
        }
        else
        {
            logTrace( "ERROR: Could NOT convert view.annotation to PointAnnotation OR could NOT unwrap pointAnnotation.pinIndex!" )
        }
        
    }
    
    
    func mapView(_ mapView: MKMapView,
                   didUpdate userLocation: MKUserLocation )
    {
        // NOTE: When you set this the mapView immediately centers on the user's location,
        // Consequently, you don't want to be doing this a lot or it will frustrate the user

        if !locationEstablished
        {
            if centerMapOnUserLocation
            {
                if let location = userLocation.location
                {
                    logVerbose( "Setting map center [ %f, %f ] on user location", location.coordinate.latitude, location.coordinate.longitude )
                    zoomInOn( coordinate: location.coordinate )
                }
                else
                {
                    logTrace( "ERROR: Could NOT unwrap userLocation.location!" )
                }
            }
            else
            {
                logVerbose( "Setting map center [ %f, %f ] on requested by PinEdit[0]", coordinateToCenterMapOn.longitude, coordinateToCenterMapOn.latitude )
                centerMapOnUserLocation = true
                zoomInOn( coordinate: coordinateToCenterMapOn )
            }

            locationEstablished = true
        }
        else if !centerMapOnUserLocation
        {
            logVerbose( "Setting map center [ %f, %f ] on requested by PinEdit[1]", coordinateToCenterMapOn.longitude, coordinateToCenterMapOn.latitude )
            centerMapOnUserLocation = true
            zoomInOn( coordinate: coordinateToCenterMapOn )
        }

    }
    

    func mapView(_ mapView: MKMapView,
                   didFailToLocateUserWithError error: Error )
    {
        logVerbose( "ERROR: [ %@ ]", error.localizedDescription )
//        presentAlert( title: NSLocalizedString( "AlertTitle.Error", comment: "Error!" ),
//                      message: error.localizedDescription )
    }
    
    
    func mapView(_ mapView: MKMapView,
                   rendererFor overlay: MKOverlay ) -> MKOverlayRenderer
    {
        logTrace()
        if overlay is MKPolyline
        {
            let     polylineRenderer = MKPolylineRenderer( overlay: overlay )
            
            
            polylineRenderer.lineWidth   = 3
            polylineRenderer.strokeColor = routeColor
            
            routeColor = UIColor.yellow
            
            return polylineRenderer
        }
        
        return MKOverlayRenderer()
    }
    
    
    func mapView(_ mapView: MKMapView,
                   viewFor annotation: MKAnnotation ) -> MKAnnotationView?
    {
        if annotation is MKUserLocation
        {
//            logTrace( "Our location" )
            return nil      // This allows us to retain the blue dot & circle animation for the user's location (instead of our mapPin image)
        }
        
        
        let     annotationIdentifier = "AnnotationIdentifier"
        let     annotationView       = mapView.dequeueReusableAnnotationView( withIdentifier: annotationIdentifier )
        let     pinAnnotationView    : MKPinAnnotationView!
        let     pointAnnotation      = annotation as! PointAnnotation
        let     pin                  = PinCentral.sharedInstance.pinArray[pointAnnotation.pinIndex!]
        
        
        guard annotationView != nil else
        {
            logTrace( "Creating New Pin" )
            pinAnnotationView = MKPinAnnotationView( annotation: annotation, reuseIdentifier: annotationIdentifier )
            
//          pinAnnotationView.animatesDrop   = true
            pinAnnotationView.canShowCallout = true
            pinAnnotationView.isDraggable    = true
            pinAnnotationView.pinTintColor   = pinColorArray[Int( pin.pinColor )]
            pinAnnotationView.rightCalloutAccessoryView = UIButton( type: .detailDisclosure )
            
            return pinAnnotationView
        }
        
        if let pinAnnotationView = annotationView as? MKPinAnnotationView
        {
            logTrace( "Use Existing Pin" )
            pinAnnotationView.annotation   = annotation
            pinAnnotationView.pinTintColor = pinColorArray[Int( pin.pinColor )]
            
            return pinAnnotationView
        }
            
        logTrace( "ERROR: Could NOT convert annotationView to MKPinAnnotationView!" )
        return nil
    }
    
    
    func mapViewDidStopLocatingUser(_ mapView: MKMapView )
    {
        logTrace()
    }
    
    
    func mapViewWillStartLocatingUser(_ mapView: MKMapView )
    {
        logTrace()
    }

    

    // MARK: NSNotification Methods
    
    @objc func centerMap( notification: NSNotification )
    {
        if let userInfo = notification.userInfo
        {
            let     latitude   = userInfo[ USER_INFO_LATITUDE  ] as! Double
            let     longitude  = userInfo[ USER_INFO_LONGITUDE ] as! Double
            let     coordinate = CLLocationCoordinate2DMake( latitude, longitude )
            
            
            if locationEstablished
            {
                logVerbose( "locationEstablished at [ %f, %f ] ... right now", latitude, longitude )
                let     pinCentral = PinCentral.sharedInstance
                
                
                zoomInOn( coordinate: coordinate )
                
                for annotation in myMapView.annotations
                {
                    if let pointAnnotation = annotation as? PointAnnotation
                    {
                        if pinCentral.indexOfSelectedPin == pointAnnotation.pinIndex
                        {
                            myMapView.selectAnnotation( annotation, animated: true )
                            break
                        }
                        
                    }
                    else
                    {
                        logTrace( "ERROR: Could NOT convert annotation to PointAnnotation!" )
                    }
                    
                }
                
            }
            else
            {
                logVerbose( "at [ %f, %f ] ... wait for location to be established", latitude, longitude )
                coordinateToCenterMapOn = coordinate
                centerMapOnUserLocation = false
            }
        
        }
        else
        {
            logTrace( "ERROR: Could NOT unwrap notification.userInfo!" )
        }

    }
    
    
    @objc func pinsUpdated( notification: NSNotification )
    {
        logTrace()
        
        // The reason we are using Notifications is because this view can be up in two different places on the iPad at the same time.
        // This approach allows a change in one to immediately be reflected in the other.
        
        refreshMapAnnotations()
    }
    
    
    
    // MARK: PinCentralDelegate Methods
    
    func pinCentral( pinCentral: PinCentral,
                     didOpenDatabase: Bool )
    {
        logVerbose( "[ %@ ]", stringFor( didOpenDatabase ) )
        if didOpenDatabase
        {
            pinCentral.fetchPins()
        }
        else
        {
            presentAlert( title: NSLocalizedString( "AlertTitle.Error", comment: "Error!" ),
                          message: NSLocalizedString( "AlertMessage.CannotOpenDatabase", comment: "Fatal ERROR: Cannot open database." ) )
        }

    }
    
    
    func pinCentralDidReloadPinArray( pinCentral: PinCentral )
    {
        logVerbose( "loaded [ %d ] pins", pinCentral.pinArray.count )
        if ignoreRefresh
        {
            ignoreRefresh = false
        }
        else
        {
            refreshMapAnnotations()
        }

    }
    
    
    
    // MARK: Target/Action Methods
    
    @IBAction @objc func addBarButtonItemTouched(_ sender: UIBarButtonItem )
    {
        logTrace()
        PinCentral.sharedInstance.delegate = self
        
        launchLocationEditorForPinAt( index: NEW_PIN )
   }
    
    
    @IBAction func dartBarButtonItemTouched(_ sender: UIBarButtonItem )
    {
        logTrace()
        let     pinCentral = PinCentral.sharedInstance
        
        
        if pinCentral.locationEstablished
        {
            let     adjustedAltitude = ( ( DISPLAY_UNITS_FEET == pinCentral.displayUnits() ) ? String.init( format: "%7.1f", ( pinCentral.currentAltitude * FEET_PER_METER ) ) :
                                                                                               String.init( format: "%7.1f",   pinCentral.currentAltitude ) )
            let     message = String( format: "%@, %@\n%7.4f, %7.4f\n\n%@ = %@ %@",
                                      NSLocalizedString( "LabelText.Latitude",  comment: "Latitude"  ),
                                      NSLocalizedString( "LabelText.Longitude", comment: "Longitude" ),
                                      pinCentral.currentLocation.latitude,
                                      pinCentral.currentLocation.longitude,
                                      NSLocalizedString( "LabelText.Altitude",  comment: "Altitude"  ),
                                      adjustedAltitude,
                                      pinCentral.displayUnits() )
            
            presentAlert( title: NSLocalizedString( "AlertTitle.CurrentCoordinates", comment: "Current Coordinates" ),
                          message: message )
        }
        
    }
    
    
    @IBAction @objc func directionsBarButtonItemTouched(_ sender: UIBarButtonItem )
    {
        logTrace()
        manageDirectionsOverlay()
    }
    
    
    
    @IBAction func homeZoomButtonTouched(_ sender: UIButton )
    {
        logTrace()
        zoomInOnUser()
    }
    
    
    @IBAction @objc func mapTypeBarButtonItemTouched(_ sender: UIBarButtonItem )
    {
        logTrace()
        presentMapOptions()
    }
    
    
    
    // MARK: UIPopoverPresentationControllerDelegate Methods
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle
    {
        return UIModalPresentationStyle.none
    }
    
    
    
    // MARK: Utility Methods
    
    private func examinePointAnnotation( pointAnnotation: PointAnnotation )
    {
        if let pinIndex = pointAnnotation.pinIndex
        {
            logVerbose( "Fetching annotation at index[ %d ]", pinIndex )
            let     pin = PinCentral.sharedInstance.pinArray[pinIndex]
            
            
            if ( ( pointAnnotation.coordinate.latitude != pin.latitude ) || ( pointAnnotation.coordinate.longitude != pin.longitude ) )
            {
                self.ignoreRefresh = true
                DispatchQueue.main.asyncAfter(deadline: ( .now() + 1.0 ), execute:
                {
                    self.updatePinCoordinatesUsing( pointAnnotation: pointAnnotation )
                } )
                
            }
            
        }
        else
        {
            logTrace( "ERROR: pointAnnotation.pinIndex could NOT be unwrapped!" )
        }
            
    }

    
    private func launchLocationEditorForPinAt( index: Int )
    {
        logVerbose( "[ %d ]", index )
        if let locationEditorVC: LocationEditorViewController = iPhoneViewControllerWithStoryboardId( storyboardId: STORYBOARD_ID_LOCATION_EDITOR ) as? LocationEditorViewController
        {
            locationEditorVC.delegate                = self
            locationEditorVC.indexOfItemBeingEdited  = index
            locationEditorVC.launchedFromDetailView  = ( .pad == UIDevice.current.userInterfaceIdiom )
            
            if NEW_PIN == index
            {
                locationEditorVC.centerOfMap    = myMapView.centerCoordinate
                locationEditorVC.useCenterOfMap = true
            }
            else
            {
                locationEditorVC.useCenterOfMap = false
            }
            
            if .phone == UIDevice.current.userInterfaceIdiom
            {
                navigationController?.pushViewController( locationEditorVC, animated: true )
            }
            else
            {
                let     navigationController = UINavigationController.init( rootViewController: locationEditorVC )
                
                
                navigationController.modalPresentationStyle = .formSheet
                
                present( navigationController, animated: true, completion: nil )
                
                navigationController.popoverPresentationController?.delegate                 = self
                navigationController.popoverPresentationController?.permittedArrowDirections = .any
                navigationController.popoverPresentationController?.sourceRect               = view.frame
                navigationController.popoverPresentationController?.sourceView               = view
            }
            
            showingPinEditor = true
        }
        else
        {
            logTrace( "ERROR: Could NOT load LocationEditorViewController!" )
        }
        
    }
    
    
    private func loadBarButtonItems()
    {
        logTrace()
        addBarButtonItem          = UIBarButtonItem.init( barButtonSystemItem: .add,
                                                          target: self,
                                                          action: #selector( addBarButtonItemTouched(_:) ) )
        let     dartBarButtonItem = UIBarButtonItem.init( image:  UIImage.init(named: "dart" ),
                                                          style: .plain,
                                                          target: self,
                                                          action: #selector( dartBarButtonItemTouched(_:) ) )
        directionsBarButtonItem   = UIBarButtonItem.init( title: NSLocalizedString( "ButtonTitle.Directions", comment: "Directions" ),
                                                          style: .plain,
                                                          target: self,
                                                          action: #selector( directionsBarButtonItemTouched(_:) ) )
        mapTypeBarButtonItem      = UIBarButtonItem.init( title: NSLocalizedString( "ButtonTitle.MapType", comment: "Map Type" ),
                                                          style: .plain,
                                                          target: self,
                                                          action: #selector( mapTypeBarButtonItemTouched(_:) ) )
        
        navigationItem.leftBarButtonItems  = [dartBarButtonItem, directionsBarButtonItem]
        navigationItem.rightBarButtonItems = [addBarButtonItem, mapTypeBarButtonItem]
        
        directionsBarButtonItem.isEnabled = false
    }


    private func manageDirectionsOverlay()
    {
        logTrace()
        if showingDirectionsOverlay
        {
            for overlay in myMapView.overlays
            {
                myMapView.remove( overlay )
            }
            
            myMapView.setUserTrackingMode( .none, animated: true )

            directionsBarButtonItem.title = NSLocalizedString( "ButtonTitle.Directions", comment: "Directions" )
            showingDirectionsOverlay      = false
            routeColor                    = UIColor.green   // Re-establishes the default
            
            zoomInOnUser()
        }
        else
        {
            let     request = MKDirectionsRequest()
            
            
            if let myAnnotation = selectedPointAnnotation,
               let location     = myMapView.userLocation.location
            {
                request.destination             = MKMapItem( placemark: MKPlacemark( coordinate: myAnnotation.coordinate, addressDictionary: nil ) )
                request.requestsAlternateRoutes = true
                request.source                  = MKMapItem( placemark: MKPlacemark( coordinate: location.coordinate, addressDictionary: nil ) )
                request.transportType           = .automobile
                
                
                let     directions = MKDirections( request: request )
                
                
                directions.calculate
                    { ( response, error ) -> Void in
                        
                        guard let response = response else
                        {
                            if let error = error
                            {
                                let         errorMessage = String.init( format: "%@\n%@", NSLocalizedString( "AlertMessage.NoRoutesAvailable", comment: "Unable to find a route to this location." ), error.localizedDescription )
                                
                                
                                logVerbose( "ERROR: We failed to get directions!  [ %@ ]", error.localizedDescription )
                                self.presentAlert( title: NSLocalizedString( "AlertTitle.Error", comment: "Error!" ),
                                                   message: errorMessage )
                            }
                            
                            return
                        }
                        
                        if ( 0 == response.routes.count )
                        {
                            logTrace( "Can't get there from here!  No routes!" )
                            self.presentAlert( title: NSLocalizedString( "AlertTitle.Error", comment: "Error!" ),
                                               message: NSLocalizedString( "AlertMessage.NoRoutesAvailable", comment: "Unable to find a route to this location." ) )
                        }
                        else
                        {
                            self.myMapView.add( response.routes[0].polyline )
                            
                            if 1 < response.routes.count
                            {
                                self.myMapView.add( response.routes[1].polyline )
                            }
                            
                            self.myMapView.mapType = .hybrid
                            self.myMapView.setUserTrackingMode( .follow, animated: true )
                            self.myMapView.setVisibleMapRect( response.routes[0].polyline.boundingMapRect, animated: true )
                            
                            self.directionsBarButtonItem.title = NSLocalizedString( "ButtonTitle.EndDirections", comment: "End Directions" )
                            self.showingDirectionsOverlay      = true
                        }
                        
                }

            }
            else
            {
                logTrace( "ERROR: Count NOT assign selectedPointAnnotation OR unwrap myMapView.userLocation.location!" )
            }
            
        }

    }

    
    private func presentMapOptions()
    {
        logTrace()
        let     alert = UIAlertController.init( title: NSLocalizedString( "AlertTitle.SelectMapType", comment: "Select Map Type" ),
                                                message: nil,
                                                preferredStyle: .actionSheet )
        
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

        if showingDirectionsOverlay
        {
            alert.addAction( hybridAction           )
            alert.addAction( standardAction         )
        }
        else
        {
            alert.addAction( hybridAction           )
            alert.addAction( hybridFlyoverAction    )
            alert.addAction( mutedStandardAction    )
            alert.addAction( satelliteAction        )
            alert.addAction( satelliteFlyoverAction )
            alert.addAction( standardAction         )
        }
        
        alert.addAction( cancelAction )
        
        if .pad == UIDevice.current.userInterfaceIdiom
        {
            modalPresentationStyle = .popover
            
            present( alert, animated: true, completion: nil )
            
            alert.popoverPresentationController?.delegate                 = self
            alert.popoverPresentationController?.permittedArrowDirections = .any
            alert.popoverPresentationController?.barButtonItem            = mapTypeBarButtonItem
        }
        else
        {
            present( alert, animated: true, completion: nil )
        }
        
    }
    
    
    private func refreshMapAnnotations()
    {
//        logTrace()
        let     pinCentral = PinCentral.sharedInstance
        var     annotationArray:[PointAnnotation] = Array.init()
        
        
        myMapView.removeAnnotations( myMapView.annotations )
        
        for index in 0..<pinCentral.pinArray.count
        {
            let     pin = pinCentral.pinArray[index]
            let     annotation: PointAnnotation = PointAnnotation.init()
            
            
            annotation.initWith( pin: pin, atIndex: index )
            annotationArray.append( annotation )
        }
        
        if 0 < annotationArray.count
        {
            myMapView.addAnnotations( annotationArray )
        }
        
        logVerbose( "Added [ %d ] pins", annotationArray.count )
    }
    
   
    private func saveMapTypeInUserDefaults( mapType: Int )
    {
        UserDefaults.standard.set( mapType, forKey: self.KEY_MAP_TYPE )
        UserDefaults.standard.synchronize()
    }
    
    
    private func setMapTypeFromUserDefaults()
    {
        let     savedMapType = UserDefaults.standard.integer( forKey: KEY_MAP_TYPE )
        var     typeName     = "Standard"
        
        
        switch savedMapType
        {
        case MapTypes.eHybrid:             myMapView.mapType = .hybrid;             typeName = "Hybrid"
        case MapTypes.eHybridFlyover:      myMapView.mapType = .hybridFlyover;      typeName = "Hybrid Flyover"
        case MapTypes.eMutedStandard:      myMapView.mapType = .mutedStandard;      typeName = "Muted Standard"
        case MapTypes.eSatellite:          myMapView.mapType = .satellite;          typeName = "Satellite"
        case MapTypes.eSatelliteFlyover:   myMapView.mapType = .satelliteFlyover;   typeName = "Satellite Flyover"
        default:                           myMapView.mapType = .standard
        }
        
        logVerbose( "[ %d ][ %@ ]", savedMapType, typeName )
    }
    
    
    private func titleForDragState( state: MKAnnotationViewDragState ) -> String
    {
        var     title = "none     "
        
        
        switch state
        {
        case .canceling:    title = "canceling"
        case .dragging:     title = "dragging "
        case .ending:       title = "ending   "
        case .starting:     title = "starting "
        default: break
        }
        
        return title
    }

    
    private func updatePinCoordinatesUsing( pointAnnotation: PointAnnotation )
    {
        if let pinIndex = pointAnnotation.pinIndex
        {
            logVerbose( "pointAnnotation.pinIndex[ %d ]", pinIndex )
            let     pinCentral = PinCentral.sharedInstance
            let     pin        = pinCentral.pinArray[pinIndex]
            
            
            pin.latitude  = pointAnnotation.coordinate.latitude
            pin.longitude = pointAnnotation.coordinate.longitude
            
            pinCentral.delegate = self
            pinCentral.saveUpdatedPin( pin: pin )
        }
        else
        {
            logVerbose( "ERROR: pointAnnotation.pinIndex cound NOT be unwrapped!" )
        }
        
    }
    
    
    private func zoomInOnUser()
    {
        guard let coordinate = myMapView.userLocation.location?.coordinate else
        {
            logTrace( "no data yet... waiting" )
            return
        }
        
        zoomInOn( coordinate: coordinate )

        locationEstablished = true
    }
    
    
    private func zoomInOn( coordinate: CLLocationCoordinate2D )
    {
        let     region = MKCoordinateRegionMakeWithDistance( coordinate, 2000, 2000 )
        
        
        logVerbose( "[ %f, %f ]", coordinate.latitude, coordinate.longitude )
        myMapView.setRegion( region, animated: true )
    }

    
    
    
    
    
    
    
    
    
    
    
    
    
    
    // MARK: Dumpster Diving Area
/*
    @IBAction func zoomBarButtonItemTouched(_ sender: UIBarButtonItem )
    {
        logTrace()
        let     region = MKCoordinateRegionMakeWithDistance( myMapView.userLocation.location!.coordinate, 2000, 2000 )

        
        myMapView.setRegion( region, animated: true )
        myMapView.showAnnotations( myMapView.annotations, animated: true )
    }

    
    func mapView(_ mapView: MKMapView,
                 viewFor annotation: MKAnnotation ) -> MKAnnotationView?
    {
        if annotation is MKUserLocation
        {
            return nil      // This keeps the blue dot & circle animation for the user's location (instead of our mapPin image)
        }
        
        
        let     annotationIdentifier = "AnnotationIdentifier"
        var     annotationView       = mapView.dequeueReusableAnnotationView( withIdentifier: annotationIdentifier )
        
        
        if nil == annotationView
        {
            annotationView = MKAnnotationView( annotation: annotation,
                                               reuseIdentifier: annotationIdentifier )
            
            annotationView!.canShowCallout = true
            annotationView!.isDraggable    = true
            annotationView!.rightCalloutAccessoryView = UIButton( type: .detailDisclosure )
        }
        else
        {
            annotationView!.annotation = annotation
        }
        
        annotationView!.image = UIImage( named: "mapPin" )
        
        return annotationView
    }
*/
    


}
