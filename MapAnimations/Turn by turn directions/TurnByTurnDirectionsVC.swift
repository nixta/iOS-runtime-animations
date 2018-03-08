//
//  TurnByTurnDirectionsVC.swift
//  MapAnimations
//
//  Created by Gagandeep Singh on 3/3/17.
//  Copyright © 2017 Gagandeep Singh. All rights reserved.
//

import UIKit
import ArcGIS

class TurnByTurnDirectionsVC: AnimationDemoViewController {

    @IBOutlet var mapView:AGSMapView!
    @IBOutlet var routeBBI:UIBarButtonItem!
    @IBOutlet var directionsView:UIView!
    @IBOutlet var directionsLabel:UILabel!
    
    private var point1 = AGSPoint(x: -13051580.418701, y: 3859622.340737, spatialReference: AGSSpatialReference.webMercator())
    private var point2 = AGSPoint(x: -13034925.709800, y: 3851421.541825, spatialReference: AGSSpatialReference.webMercator())
    
    private var routeTask:AGSRouteTask!
    private var routeParameters:AGSRouteParameters!
    private var generatedRoute:AGSRoute!
    private var routeGraphic:AGSGraphic!
    
    private var stopGraphicsOverlay = AGSGraphicsOverlay()
    private var routeGraphicsOverlay = AGSGraphicsOverlay()
    private lazy var directionsGraphicsOverlay:AGSGraphicsOverlay = {
        let overlay = AGSGraphicsOverlay()
        overlay.renderingMode = .dynamic
        let renderer = AGSSimpleRenderer()
        renderer.symbol = currentDirectionSymbol()
        overlay.renderer = renderer
        return overlay
    }()
    private var isDirectionsListVisible = false
    private var directionIndex = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //initialize map with vector basemap
        let map = AGSMap(basemap: AGSBasemap.topographic())
        
        //assign map to the map view
        self.mapView.map = map
        
        //add the graphics overlays to the map view
        self.mapView.graphicsOverlays.addObjects(from: [routeGraphicsOverlay, directionsGraphicsOverlay, stopGraphicsOverlay])
        
        //zoom to viewpoint
        self.mapView.setViewpointCenter(AGSPoint(x: -13042254.715252, y: 3857970.236806, spatialReference: AGSSpatialReference(wkid: 3857)), scale: 1e5, completion: nil)
        
        //initialize route task
        self.routeTask = AGSRouteTask(url: URL(string: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/NetworkAnalysis/SanDiego/NAServer/Route")!)
        
        //stylize directions view
        self.directionsView.layer.cornerRadius = 5
        self.directionsView.layer.shadowColor = UIColor.gray.cgColor
        self.directionsView.layer.shadowOffset = CGSize(width: 2, height: 2)
        self.directionsView.layer.shadowRadius = 10
        self.directionsView.layer.shadowOpacity = 1
        
        //hide the directions view initially
        self.directionsView.isHidden = true
        
        //add graphics
        self.addGraphics()
        
        //get default parameters
        self.getDefaultParameters()
        
    }
    
    //MARK: - Turns logic
    
    @IBAction func animate() {
        self.directionIndex = 0
        self.startManueverAnimation()
    }
    
    func startManueverAnimation() {
        
        self.focusOnManuever(atIndex: self.directionIndex, inAnimation: true) { [weak self] (finished) in
            
            if let weakSelf = self {
                
                self?.directionIndex += 1
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8, execute: {
                    guard self != nil else {
                        // The view has been destroyed - we're not watching this demo any more so let's
                        // just pass on the opportunity to kick off an animation that'll never be seen.
                        return
                    }

                    if weakSelf.directionIndex < weakSelf.generatedRoute.directionManeuvers.count {
                        self?.startManueverAnimation()
                    }
                    else {
                        //animation finished
                        
                        //reset view point to route's geometry
                        weakSelf.mapView.setViewpointRotation(0, completion: nil)
                        weakSelf.mapView.setViewpointGeometry(weakSelf.generatedRoute.routeGeometry!, padding: 20, completion: nil)
                        
                        //clear direction graphics
                        weakSelf.directionsGraphicsOverlay.graphics.removeAllObjects()
                        
                        //hide directions view
                        weakSelf.directionsView.isHidden = true
                    }
                })
            }
        }
    }
    
    func focusOnManuever(atIndex index:Int, inAnimation:Bool, completion: ((Bool) -> Void)?) {
        guard let route = self.generatedRoute, index < route.directionManeuvers.count else {
            completion?(true)
            return
        }

        self.directionsGraphicsOverlay.graphics.removeAllObjects()

        // get current direction and add it to the graphics layer
        let directions = self.generatedRoute.directionManeuvers
        let currentManeuver = directions[index]

        guard let currPolyline = currentManeuver.geometry as? AGSPolyline else {
            print("Maneuver doesn't have a polyline geometry!")
            completion?(true)
            return
        }

        guard let turnPoint = currPolyline.parts[0].startPoint else {
            print("Current polyline has no points!")
            completion?(true)
            return
        }

        let previousManeuver:AGSDirectionManeuver? = index > 0 ? directions[index-1] : nil

        let length:Double = 100

        let geometryBuilder = AGSPolylineBuilder(spatialReference: currentManeuver.geometry?.spatialReference)
        if let previousManeuver = previousManeuver, let prevPolyline = previousManeuver.geometry as? AGSPolyline {
            geometryBuilder.addPart(with: prevPolyline.parts[0].points.array())
            geometryBuilder.add(currPolyline.parts[0].points.array(), toPartAt: 0)
        } else {
            geometryBuilder.addPart(with: currPolyline.parts[0].points.array())
        }

        //            var combinedPolyline:AGSPolyline = prevGeom == nil ? currGeom! : AGSGeometryEngine.union(ofGeometry1: prevGeom!, geometry2: currGeom!) as! AGSPolyline

        guard let cutGeom = AGSGeometryEngine.bufferGeometry(turnPoint, byDistance: length) else {
            print("Unexpectedly the buffer around the turn point is empty!")
            completion?(true)
            return
        }

        guard let routeGeometry = route.routeGeometry else {
            print("No overall route geometry!")
            completion?(true)
            return
        }

        guard let turnPolyline = AGSGeometryEngine.intersection(ofGeometry1: routeGeometry, geometry2: cutGeom) as? AGSPolyline else {
            print("Failed to get a polyline by cutting the source polyline with the buffer")
            completion?(true)
            return
        }

        let graphic = AGSGraphic(geometry: turnPolyline, symbol: self.currentDirectionSymbol(), attributes: nil)


        if inAnimation {
            let rotationAngle = self.angleOfRotationForPolyline(turnPolyline)
            let viewpoint = AGSViewpoint(center: turnPoint, scale: 10000, rotation: rotationAngle)

            self.mapView.setViewpoint(viewpoint, duration: 0.5, curve: .linear, completion: { (finished) in
                completion?(finished)
            })

            //unhide the directions view
            if self.directionsView.isHidden {
                self.directionsView.isHidden = false
            }

            //update directions label
            let directionText = directions[index].directionText
            self.directionsLabel.text = directionText

                self.directionsGraphicsOverlay.graphics.add(graphic)
            }
        else {
            completion?(true)
        }
    }
    
    func angleOfRotationForPolyline(_ polyline:AGSPolyline) -> Double {
        //consider single part polyline
        guard polyline.parts[0].points.count > 1 else {
            return 0
        }
        //let totalPoint = polyline.parts[0].pointCount
        let p1 = polyline.parts[0].point(at: 0)
        let p2 = polyline.parts[0].point(at: 1)

        return AGSGeometryEngine.geodeticDistanceBetweenPoint1(p1, point2: p2, distanceUnit: AGSLinearUnit.meters(), azimuthUnit: AGSAngularUnit.degrees(), curveType: AGSGeodeticCurveType.geodesic)?.azimuth1 ?? 0
    }
    
    //composite symbol for the direction graphic
    func currentDirectionSymbol() -> AGSCompositeSymbol {
        let compositeSymbol = AGSCompositeSymbol()
        
        let outerLineSymbol = AGSSimpleLineSymbol()
        outerLineSymbol.color = UIColor.white
        outerLineSymbol.style = .solid
        outerLineSymbol.width = 8
        compositeSymbol.symbols.append(outerLineSymbol)
        
        let innerLineSymbol = AGSSimpleLineSymbol()
        innerLineSymbol.color = UIColor.orange
        innerLineSymbol.style = .solid
        innerLineSymbol.width = 5
        innerLineSymbol.markerStyle = .arrow
        innerLineSymbol.markerPlacement = .end
        compositeSymbol.symbols.append(innerLineSymbol)

        return compositeSymbol
    }
    

    //MARK: - Route logic
    
    private func addGraphics() {
        
        //symbol for start and stop points
        let symbol1 = AGSPictureMarkerSymbol(image: UIImage(named: "GreenMarker")!)
        symbol1.offsetY = 22
        let symbol2 = AGSPictureMarkerSymbol(image: UIImage(named: "RedMarker")!)
        symbol2.offsetY = 22
        
        //graphics
        let graphic1 = AGSGraphic(geometry: self.point1, symbol: symbol1, attributes: nil)
        let graphic2 = AGSGraphic(geometry: self.point2, symbol: symbol2, attributes: nil)
        
        //add these graphics to the overlay
        self.stopGraphicsOverlay.graphics.addObjects(from: [graphic1, graphic2])
    }
    
    func getDefaultParameters() {
        
        //get the default route parameters
        self.routeTask.defaultRouteParameters { [weak self] (params: AGSRouteParameters?, error: Error?) -> Void in
            if let error = error {
                SVProgressHUD.showError(withStatus: error.localizedDescription)
            }
            else {
                SVProgressHUD.dismiss()
                
                //keep a reference
                self?.routeParameters = params
                
                //enable bar button item
                self?.routeBBI.isEnabled = true
                
                self?.route()
            }
        }
    }
    
    @IBAction func route() {
        
        SVProgressHUD.show(withStatus: "Routing", maskType: SVProgressHUDMaskType.gradient)
        
        //clear routes
        self.routeGraphicsOverlay.graphics.removeAllObjects()
        
        //all calculations are in meters so need the directions geometry in web mercator
        self.routeParameters.outputSpatialReference = AGSSpatialReference.webMercator()
        
        //return directions
        self.routeParameters.returnDirections = true
        
        //add stops
        self.routeParameters.setStops([AGSStop(point: point1), AGSStop(point: point2)])
        
        //solve route
        self.routeTask.solveRoute(with: self.routeParameters) { [weak self] (routeResult:AGSRouteResult?, error:Error?) -> Void in
            if let error = error {
                //show error
                SVProgressHUD.showError(withStatus: "\(error.localizedDescription) \((error as NSError).localizedFailureReason ?? "")")
            }
            else {
                //dismiss progress hud
                SVProgressHUD.dismiss()
                
                //if a route is found
                if let route = routeResult?.routes[0], let weakSelf = self {
                    
                    //create graphic for the route
                    let routeGraphic = AGSGraphic(geometry: route.routeGeometry, symbol: weakSelf.routeSymbol(false), attributes: nil)
                    
                    //add route graphic to route graphics overlay
                    weakSelf.routeGraphicsOverlay.graphics.add(routeGraphic)
                    
                    //keep reference to route, for animation
                    weakSelf.generatedRoute = route
                }
            }
        }
    }
    
    //composite symbol for route graphic
    func routeSymbol(_ dashed: Bool) -> AGSCompositeSymbol {
        
        let compositeSymbol = AGSCompositeSymbol()
        
        //outer/wider line symbol
        let outerLineSymbol = AGSSimpleLineSymbol()
        outerLineSymbol.color = UIColor(red: 0, green: 174.0/255.0, blue: 231.0/255.0, alpha: 1)
        outerLineSymbol.style = dashed ? .dash : .solid
        outerLineSymbol.width = 8
        
        //inner/thinner line symbol
        let innerLineSymbol = AGSSimpleLineSymbol()
        innerLineSymbol.color = UIColor(red: 52.0/255.0, green: 203.0/255.0, blue: 252.0/255.0, alpha: 1)
        innerLineSymbol.style = dashed ? .dash : .solid
        innerLineSymbol.width = 4
        
        //add both the symbols to the composite symbol in order
        compositeSymbol.symbols.append(contentsOf: [outerLineSymbol, innerLineSymbol])
        
        return compositeSymbol
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
