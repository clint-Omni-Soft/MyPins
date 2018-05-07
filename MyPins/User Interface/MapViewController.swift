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
                         MKMapViewDelegate,
                         PinCentralDelegate,
                         PinEditViewControllerDelegate,
                         UIPopoverPresentationControllerDelegate
{
    let NO_SELECTION         = -1
    let KEY_MAP_TYPE         = "MapType"
    let STORYBOARD_ID_EDITOR = "PinEditViewController"
    
    struct MapTypes
    {
        static let eStandard            = 0
        static let eSatellite           = 1
        static let eHybrid              = 2
        static let eSatelliteFlyover    = 3
        static let eHybridFlyover       = 4
        static let eMutedStandard       = 5
    }

    
    
    @IBOutlet weak var myMapView:               MKMapView!
    
    @IBOutlet var addBarButtonItem:        UIBarButtonItem!
    @IBOutlet var directionsBarButtonItem: UIBarButtonItem!
    @IBOutlet var mapTypeBarButtonItem:    UIBarButtonItem!

    private var     coordinateToCenterMapOn:        CLLocationCoordinate2D?
    private var     ignoreRefresh                 = false
    private var     locationEstablished           = false
    private var     locationManager:                CLLocationManager?
    private var     centerMapOnUserLocation       = true
    private var     routeColor                    = UIColor.green
    private var     selectedPointAnnotation:        PointAnnotation!
    private var     showingDirectionsOverlay      = false
    private var     showingPinEditor              = false
    
    
    
    // MARK: UIViewController Lifecycle Methods
    
    override func viewDidLoad()
    {
        NSLog( "%@:%@[%d] - %@", description(), #function, #line, "" )
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
        NSLog( "%@:%@[%d] - %@", description(), #function, #line, "" )
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
                                                name:     NSNotification.Name( rawValue: pinCentral.NOTIFICATION_CENTER_MAP ),
                                                object:   nil )
        NotificationCenter.default.addObserver( self,
                                                selector: #selector( MapViewController.pinsUpdated( notification: ) ),
                                                name:     NSNotification.Name( rawValue: pinCentral.NOTIFICATION_PINS_UPDATED ),
                                                object:   nil )
    }
    
    
    override func viewWillDisappear(_ animated: Bool)
    {
        NSLog( "%@:%@[%d] - %@", description(), #function, #line, "" )
        super.viewWillDisappear( animated )
        
        NotificationCenter.default.removeObserver( self )
    }
    
    
    override func didReceiveMemoryWarning()
    {
        NSLog( "%@:%@[%d] - %@", description(), #function, #line, "MEMORY WARNING!!!" )
        super.didReceiveMemoryWarning()
    }
    
    
    
    // MARK: CLLocationManagerDelegate Methods
    
    func locationManager(_ manager: CLLocationManager,
                           didFailWithError error: Error )
    {
        NSLog( "%@:%@[%d] - %@", description(), #function, #line, error.localizedDescription )
        presentAlert( title: NSLocalizedString( "AlertTitle.Error", comment: "Error!" ),
                      message: error.localizedDescription )
    }
    
    
    func locationManager(_ manager: CLLocationManager,
                           didUpdateLocations locations: [CLLocation] )
    {
        if !locationEstablished && centerMapOnUserLocation
        {
            NSLog( "%@:%@[%d] - %@", description(), #function, #line, "" )
            self.zoomInOnUser()
        }
        
    }
    
    
    
    // MARK: MKMapViewDelegate Methods
    
    func mapView(_ mapView: MKMapView,
                   annotationView view: MKAnnotationView,
                   calloutAccessoryControlTapped control: UIControl )
    {
        if view.annotation is PointAnnotation
        {
            let     pointAnnotation = view.annotation as! PointAnnotation
            let     index           = pointAnnotation.pinIndex!


//            NSLog( "%@:%@[%d] - index[ %d ]", description(), #function, #line, index )
            launchPinEditorForPinAt( index: index )
        }
        else if view.annotation is MKUserLocation
        {
//            NSLog( "%@:%@[%d] - %@", description(), #function, #line, "Got a MKUserLocation ... ignoring" )
        }
        else
        {
            NSLog( "%@:%@[%d] - %@", description(), #function, #line, "Whazat???" )
        }
        
    }
    
    
    func mapView(_ mapView: MKMapView,
                   annotationView view: MKAnnotationView,
                   didChange newState: MKAnnotationViewDragState,
                   fromOldState oldState: MKAnnotationViewDragState )
    {
        let     pointAnnotation = view.annotation as! PointAnnotation
        

//        NSLog( "%@:%@[%d] - [ %f, %f ]  [ %@ ]->[ %@ ]",
//               description(), #function, #line, pointAnnotation.coordinate.latitude, pointAnnotation.coordinate.longitude, titleForDragState( state: oldState ), titleForDragState( state: newState ) )
        
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
    
    
    func mapView(_ mapView: MKMapView,
                   didDeselect view: MKAnnotationView )
    {
//        NSLog( "%@:%@[%d] - %@", description(), #function, #line, "" )
        
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
        

        let     pointAnnotation = view.annotation as! PointAnnotation
        
        
        directionsBarButtonItem.isEnabled = true
        selectedPointAnnotation           = pointAnnotation
//        NSLog( "%@:%@[%d] - selected pin[ %d ]", description(), #function, #line, pointAnnotation.pinIndex! )
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
                NSLog( "%@:%@[%d] - setting map center [ %f, %f ] on user location", description(), #function, #line, userLocation.location!.coordinate.latitude, userLocation.location!.coordinate.longitude )
                zoomInOn( coordinate: userLocation.location!.coordinate )
            }
            else
            {
                NSLog( "%@:%@[%d] - Setting map center [ %f, %f ] on requested by PinEdit[0]", description(), #function, #line, coordinateToCenterMapOn!.longitude, coordinateToCenterMapOn!.latitude )
                centerMapOnUserLocation = true
                zoomInOn( coordinate: coordinateToCenterMapOn! )
            }

            locationEstablished = true
        }
        else if !centerMapOnUserLocation
        {
            NSLog( "%@:%@[%d] - Setting map center [ %f, %f ] on requested by PinEdit[1]", description(), #function, #line, coordinateToCenterMapOn!.longitude, coordinateToCenterMapOn!.latitude )
            centerMapOnUserLocation = true
            zoomInOn( coordinate: coordinateToCenterMapOn! )
        }

    }
    

    func mapView(_ mapView: MKMapView,
                   didFailToLocateUserWithError error: Error )
    {
        NSLog( "%@:%@[%d] - %@", description(), #function, #line, error.localizedDescription )
        presentAlert( title: NSLocalizedString( "AlertTitle.Error", comment: "Error!" ),
                      message: error.localizedDescription )
    }
    
    
    func mapView(_ mapView: MKMapView,
                   rendererFor overlay: MKOverlay ) -> MKOverlayRenderer
    {
        NSLog( "%@:%@[%d] - %@", description(), #function, #line, "" )
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
//            NSLog( "%@:%@[%d] - %@", description(), #function, #line, "Our location" )
            return nil      // This allows us to retain the blue dot & circle animation for the user's location (instead of our mapPin image)
        }
        
        
        let     annotationIdentifier = "AnnotationIdentifier"
        let     annotationView       = mapView.dequeueReusableAnnotationView( withIdentifier: annotationIdentifier )
        let     pinAnnotationView: MKPinAnnotationView!
        let     pointAnnotation      = annotation as! PointAnnotation
        let     pin                  = PinCentral.sharedInstance.pinArray![pointAnnotation.pinIndex!]
        
        
        if nil == annotationView
        {
//            NSLog( "%@:%@[%d] - %@", description(), #function, #line, "New pin" )
            pinAnnotationView = MKPinAnnotationView( annotation: annotation, reuseIdentifier: annotationIdentifier )
            
//          pinAnnotationView.animatesDrop   = true
            pinAnnotationView.canShowCallout = true
            pinAnnotationView.isDraggable    = true
            pinAnnotationView.pinTintColor   = pinColorArray[Int( pin.pinColor )]
            pinAnnotationView.rightCalloutAccessoryView = UIButton( type: .detailDisclosure )
        }
        else
        {
//            NSLog( "%@:%@[%d] - %@", description(), #function, #line, "Existing pin" )
            pinAnnotationView = annotationView as! MKPinAnnotationView
            
            pinAnnotationView!.annotation   = annotation
            pinAnnotationView!.pinTintColor = pinColorArray[Int( pin.pinColor )]
        }
        
        return pinAnnotationView
    }
    
    
    func mapViewDidStopLocatingUser(_ mapView: MKMapView )
    {
        NSLog( "%@:%@[%d] - %@", description(), #function, #line, "" )
    }
    
    
    func mapViewWillStartLocatingUser(_ mapView: MKMapView )
    {
        NSLog( "%@:%@[%d] - %@", description(), #function, #line, "" )
    }

    

    // MARK: NSNotification Methods
    
    @objc func centerMap( notification: NSNotification )
    {
        let     latitude   = notification.userInfo![ PinCentral.sharedInstance.USER_INFO_LATITUDE  ] as! Double
        let     longitude  = notification.userInfo![ PinCentral.sharedInstance.USER_INFO_LONGITUDE ] as! Double
        let     coordinate = CLLocationCoordinate2DMake( latitude, longitude )
        
        
        if locationEstablished
        {
            NSLog( "%@:%@[%d] - at [ %f, %f ] ... right now", description(), #function, #line, latitude, longitude )
            let     pinCentral = PinCentral.sharedInstance
            
            
            zoomInOn( coordinate: coordinate )
            
            for annotation in myMapView.annotations
            {
                if annotation is PointAnnotation
                {
                    let     pointAnnotation = annotation as! PointAnnotation
                    
                    
                    if pinCentral.indexOfSelectedPin == pointAnnotation.pinIndex
                    {
                        myMapView.selectAnnotation( annotation, animated: true )
                        break
                    }
                    
                }
                
            }
            
        }
        else
        {
            NSLog( "%@:%@[%d] - at [ %f, %f ] ... wait for location to be established", description(), #function, #line, latitude, longitude )
            coordinateToCenterMapOn = coordinate
            centerMapOnUserLocation = false
        }
        
    }
    
    
    @objc func pinsUpdated( notification: NSNotification )
    {
        NSLog( "%@:%@[%d] - %@", description(), #function, #line, "" )
        
        // The reason we are using Notifications is because this view can be up in two different places on the iPad at the same time.
        // This approach allows a change in one to immediately be reflected in the other.
        
        refreshMapAnnotations()
    }
    
    
    
    // MARK: PinCentralDelegate Methods
    
    func pinCentral( pinCentral: PinCentral,
                     didOpenDatabase: Bool )
    {
        NSLog( "%@:%@[%d] - didOpenDatabase[ %@ ]", self.description(), #function, #line, stringForBool( boolValue: didOpenDatabase ) )
        if didOpenDatabase
        {
            pinCentral.fetchPins()
        }
        else
        {
            presentAlert( title: NSLocalizedString( "AlertTitle.Error", comment: "Error!" ),
                          message: NSLocalizedString( "AlertMessage.CannotOpenDatabase", comment: "Fatal Error!  Cannot open database." ) )
        }

    }
    
    
    func pinCentralDidReloadPinArray( pinCentral: PinCentral )
    {
        NSLog( "%@:%@[%d] - loaded [ %d ] pins", description(), #function, #line, pinCentral.pinArray!.count )
        if ignoreRefresh
        {
            ignoreRefresh = false
        }
        else
        {
            refreshMapAnnotations()
        }

    }
    
    
    
    // MARK: PinEditViewControllerDelegate Methods
    
    func pinEditViewController( pinEditViewController: PinEditViewController,
                                  didEditPinData: Bool )
    {
        NSLog( "%@:%@[%d] - didEditPinData[ %@ ]", self.description(), #function, #line, stringForBool( boolValue: didEditPinData ) )
        let     pinCentral = PinCentral.sharedInstance
        
        
        pinCentral.delegate = self

        refreshMapAnnotations()
        
        if pinCentral.NEW_PIN != pinCentral.newPinIndex
        {
            let     newPin     = pinCentral.pinArray![pinCentral.newPinIndex!]
            
            
            centerMapOnUserLocation = false
            coordinateToCenterMapOn = CLLocationCoordinate2DMake( newPin.latitude, newPin.longitude )
            NSLog( "%@:%@[%d] - center map on pin[ %d ]", self.description(), #function, #line, pinCentral.newPinIndex! )
        }
        
    }

    
    func pinEditViewController( pinEditViewController: PinEditViewController,
                                wantsToCenterMapAt coordinate: CLLocationCoordinate2D )
    {
        NSLog( "%@:%@[%d] - %@", description(), #function, #line, "" )
        

        coordinateToCenterMapOn = coordinate
        centerMapOnUserLocation = false
    }
    
    

    // MARK: Target/Action Methods
    
    @IBAction @objc func addBarButtonItemTouched(_ sender: UIBarButtonItem )
    {
        NSLog( "%@:%@[%d] - %@", description(), #function, #line, "" )
        PinCentral.sharedInstance.delegate = self
        
        launchPinEditorForPinAt( index: PinCentral.sharedInstance.NEW_PIN )
   }
    
    
    @IBAction func dartBarButtonItemTouched(_ sender: UIBarButtonItem )
    {
        NSLog( "%@:%@[%d] - %@", description(), #function, #line, "" )
        let     pinCentral = PinCentral.sharedInstance
        
        
        if pinCentral.locationEstablished
        {
            let     adjustedAltitude = ( ( DISPLAY_UNITS_FEET == pinCentral.displayUnits() ) ? String.init( format: "%7.1f", ( pinCentral.currentAltitude! * FEET_PER_METER ) ) :
                                                                                               String.init( format: "%7.1f",   pinCentral.currentAltitude! ) )
            let     message = String( format: "%@, %@\n%7.4f, %7.4f\n\n%@ = %@ %@",
                                      NSLocalizedString( "LabelText.Latitude",  comment: "Latitude"  ),
                                      NSLocalizedString( "LabelText.Longitude", comment: "Longitude" ),
                                      ( pinCentral.currentLocation?.latitude  )!,
                                      ( pinCentral.currentLocation?.longitude )!,
                                      NSLocalizedString( "LabelText.Altitude",  comment: "Altitude"  ),
                                      adjustedAltitude,
                                      pinCentral.displayUnits() )
            
            presentAlert( title: NSLocalizedString( "AlertTitle.CurrentCoordinates", comment: "Current Coordinates" ),
                          message: message )
        }
        
    }
    
    
    @IBAction @objc func directionsBarButtonItemTouched(_ sender: UIBarButtonItem )
    {
        NSLog( "%@:%@[%d] - %@", description(), #function, #line, "" )
        manageDirectionsOverlay()
    }
    
    
    @IBAction @objc func mapTypeBarButtonItemTouched(_ sender: UIBarButtonItem )
    {
        NSLog( "%@:%@[%d] - %@", description(), #function, #line, "" )
        presentMapOptions()
    }
    
    
    
    // MARK: UIPopoverPresentationControllerDelegate Methods
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle
    {
        return UIModalPresentationStyle.none
    }
    
    
    
    // MARK: Utility Methods
    
    private func description() -> String
    {
        return "MapViewController"
    }
    
    
    private func examinePointAnnotation( pointAnnotation: PointAnnotation )
    {
        DispatchQueue.main.asyncAfter(deadline: ( .now() + 1.0 ), execute:
        {
            NSLog( "%@:%@[%d] - %@", self.description(), #function, #line, "" )
            let     pin = PinCentral.sharedInstance.pinArray![pointAnnotation.pinIndex!]
            
            
            if ( ( pointAnnotation.coordinate.latitude != pin.latitude ) || ( pointAnnotation.coordinate.longitude != pin.longitude ) )
            {
                self.ignoreRefresh = true
                self.updatePinCoordinatesUsing( pointAnnotation: pointAnnotation )
            }
            
        } )
        
    }

    
    private func launchPinEditorForPinAt( index: Int )
    {
        NSLog( "%@:%@[%d] - %@", description(), #function, #line, "" )
        let         pinEditVC: PinEditViewController = iPhoneViewControllerWithStoryboardId( storyboardId: STORYBOARD_ID_EDITOR ) as! PinEditViewController

        
        pinEditVC.delegate                = self
        pinEditVC.indexOfItemBeingEdited  = index
        pinEditVC.launchedFromDetailView  = ( .pad == UIDevice.current.userInterfaceIdiom )
        
        if PinCentral.sharedInstance.NEW_PIN == index
        {
            pinEditVC.centerOfMap    = myMapView.centerCoordinate
            pinEditVC.useCenterOfMap = true
        }
        else
        {
            pinEditVC.useCenterOfMap = false
        }

        if .phone == UIDevice.current.userInterfaceIdiom
        {
            navigationController?.pushViewController( pinEditVC, animated: true )
        }
        else
        {
            let     navigationController = UINavigationController.init( rootViewController: pinEditVC )
            
            
            navigationController.modalPresentationStyle = .formSheet
            
            present( navigationController, animated: true, completion: nil )
            
            navigationController.popoverPresentationController?.delegate                 = self
            navigationController.popoverPresentationController?.permittedArrowDirections = .any
            navigationController.popoverPresentationController?.sourceRect               = view.frame
            navigationController.popoverPresentationController?.sourceView               = view
        }
        
        showingPinEditor = true
    }
    
    
    private func loadBarButtonItems()
    {
        NSLog( "%@:%@[%d] - %@", description(), #function, #line, "" )
        addBarButtonItem        = UIBarButtonItem.init( barButtonSystemItem: .add,
                                                        target: self,
                                                        action: #selector( addBarButtonItemTouched(_:) ) )
        let     dartBarButtonItem = UIBarButtonItem.init( image:  UIImage.init(named: "dart" ),
                                                          style: .plain,
                                                          target: self,
                                                          action: #selector( dartBarButtonItemTouched(_:) ) )
        directionsBarButtonItem = UIBarButtonItem.init( title: NSLocalizedString( "ButtonTitle.Directions", comment: "Directions" ),
                                                        style: .plain,
                                                        target: self,
                                                        action: #selector( directionsBarButtonItemTouched(_:) ) )
        mapTypeBarButtonItem    = UIBarButtonItem.init( title: NSLocalizedString( "ButtonTitle.MapType", comment: "Map Type" ),
                                                        style: .plain,
                                                        target: self,
                                                        action: #selector( mapTypeBarButtonItemTouched(_:) ) )
        
        navigationItem.leftBarButtonItems  = [dartBarButtonItem, directionsBarButtonItem]
        navigationItem.rightBarButtonItems = [addBarButtonItem, mapTypeBarButtonItem]
        
        directionsBarButtonItem.isEnabled = false
    }


    private func manageDirectionsOverlay()
    {
        NSLog( "%@:%@[%d] - %@", description(), #function, #line, "" )
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
            
            
            request.destination             = MKMapItem( placemark: MKPlacemark( coordinate: selectedPointAnnotation         .coordinate, addressDictionary: nil ) )
            request.requestsAlternateRoutes = true
            request.source                  = MKMapItem( placemark: MKPlacemark( coordinate: myMapView.userLocation.location!.coordinate, addressDictionary: nil ) )
            request.transportType           = .automobile
            
            
            let     directions = MKDirections( request: request )
            
            
            directions.calculate
            { ( response, error ) -> Void in
                
                guard let response = response else
                {
                    if let error = error
                    {
                        let         errorMessage = String.init( format: "%@\n%@", NSLocalizedString( "AlertMessage.NoRoutesAvailable", comment: "Unable to find a route to this location." ), error.localizedDescription )
                        
                        
                        NSLog( "%@:%@[%d] - ERROR!  We failed to get directions!  Error[ %@ ]", self.description(), #function, #line, error.localizedDescription )
                        self.presentAlert( title: NSLocalizedString( "AlertTitle.Error", comment: "Error!" ),
                                           message: errorMessage )
                    }
                    
                    return
                }
                
                if ( 0 == response.routes.count )
                {
                    NSLog( "%@:%@[%d] - %@", self.description(), #function, #line, "Can't get there from here!  No routes!" )
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

    }

    
    private func presentMapOptions()
    {
        NSLog( "%@:%@[%d] - %@", description(), #function, #line, "" )
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
//        NSLog( "%@:%@[%d] - %@", description(), #function, #line, "" )
        let     pinCentral = PinCentral.sharedInstance
        var     annotationArray:[PointAnnotation] = Array.init()
        
        
        myMapView.removeAnnotations( myMapView.annotations )
        
        for index in 0..<pinCentral.pinArray!.count
        {
            let     pin = pinCentral.pinArray![index]
            let     annotation: PointAnnotation = PointAnnotation.init()
            
            
            annotation.initWith( pin: pin, atIndex: index )
            annotationArray.append( annotation )
        }
        
        if 0 < annotationArray.count
        {
            myMapView.addAnnotations( annotationArray )
        }
        
        NSLog( "%@:%@[%d] - Added %d pins", description(), #function, #line, annotationArray.count )
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
        
        NSLog( "%@:%@[%d] - [ %d ][ %@ ]", description(), #function, #line, savedMapType, typeName )
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
        NSLog( "%@:%@[%d] - %@", description(), #function, #line, "" )
        let     pinCentral = PinCentral.sharedInstance
        let     pin        = pinCentral.pinArray![pointAnnotation.pinIndex!]
        
        
        pin.latitude  = pointAnnotation.coordinate.latitude
        pin.longitude = pointAnnotation.coordinate.longitude
        
        pinCentral.delegate = self
        pinCentral.saveUpdatedPin( pin: pin )
    }
    
    
    private func zoomInOnUser()
    {
        guard let coordinate = myMapView.userLocation.location?.coordinate else
        {
            NSLog( "%@:%@[%d] - %@", description(), #function, #line, "no data yet... waiting" )
            return
        }
        
        zoomInOn( coordinate: coordinate )

        locationEstablished = true
    }
    
    
    private func zoomInOn( coordinate: CLLocationCoordinate2D )
    {
        let     region = MKCoordinateRegionMakeWithDistance( coordinate, 2000, 2000 )
        
        
        NSLog( "%@:%@[%d] - [ %f, %f ]", description(), #function, #line, coordinate.latitude, coordinate.longitude )
        
        myMapView.setRegion( region, animated: true )
    }

    
    
    
    
    
    
    
    
    
    
    
    
    
    
    // MARK: Dumpster Diving Area
/*
    @IBAction func zoomBarButtonItemTouched(_ sender: UIBarButtonItem )
    {
        NSLog( "%@:%@[%d] - %@", description(), #function, #line, "" )
        let     region = MKCoordinateRegionMakeWithDistance( myMapView.userLocation.location!.coordinate, 2000, 2000 )

        
        myMapView.setRegion( region, animated: true )
        myMapView.showAnnotations( myMapView.annotations, animated: true )
    }

    
    func mapView(_ mapView: MKMapView,
                 viewFor annotation: MKAnnotation ) -> MKAnnotationView?
    {
        if annotation is MKUserLocation
        {
            NSLog( "%@:%@[%d] - %@", description(), #function, #line, "Our location" )
            return nil      // This keeps the blue dot & circle animation for the user's location (instead of our mapPin image)
        }
        
        
        let     annotationIdentifier = "AnnotationIdentifier"
        var     annotationView       = mapView.dequeueReusableAnnotationView( withIdentifier: annotationIdentifier )
        
        
        if nil == annotationView
        {
            NSLog( "%@:%@[%d] - %@", description(), #function, #line, "New pin" )
            annotationView = MKAnnotationView( annotation: annotation,
                                               reuseIdentifier: annotationIdentifier )
            
            annotationView!.canShowCallout = true
            annotationView!.isDraggable    = true
            annotationView!.rightCalloutAccessoryView = UIButton( type: .detailDisclosure )
        }
        else
        {
            NSLog( "%@:%@[%d] - %@", description(), #function, #line, "Existing pin" )
            annotationView!.annotation = annotation
        }
        
        annotationView!.image = UIImage( named: "mapPin" )
        
        return annotationView
    }
*/
    


}
