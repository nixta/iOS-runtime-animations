//
//  AnimateAlongPathVC.swift
//  MapAnimations
//
//  Created by Gagandeep Singh on 3/3/17.
//  Copyright © 2017 Gagandeep Singh. All rights reserved.
//

import UIKit
import ArcGIS

class AnimateAlongPathVC: AnimationDemoViewController, AnimateAlongPathHelperDelegate {

    @IBOutlet var mapView:AGSMapView!
    @IBOutlet var routeBBI:UIBarButtonItem!
    
    private var point1 = AGSPoint(x: -13051580.418701, y: 3859622.340737, spatialReference: AGSSpatialReference.webMercator())
    private var point2 = AGSPoint(x: -13034925.709800, y: 3851421.541825, spatialReference: AGSSpatialReference.webMercator())
    
    private var routeTask:AGSRouteTask!
    private var generatedRoute:AGSRoute!
    private var routeGraphic:AGSGraphic!
    
    private var stopGraphicsOverlay = AGSGraphicsOverlay()
    private var routeGraphicsOverlay = AGSGraphicsOverlay()
    private var carGraphicsOverlay = AGSGraphicsOverlay()
    
    private var animateAlongPathHelper:AnimateAlongPathHelper!
    private var carGraphic:AGSGraphic!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //initialize map with vector basemap
        let map = AGSMap(basemap: AGSBasemap.topographic())
        
        //assign map to the map view
        mapView.map = map
        
        //add the graphics overlays to the map view
        mapView.graphicsOverlays.addObjects(from: [routeGraphicsOverlay, carGraphicsOverlay, stopGraphicsOverlay])
        
        //zoom to viewpoint
        mapView.setViewpointCenter(AGSPoint(x: -13042254.715252, y: 3857970.236806, spatialReference: AGSSpatialReference(wkid: 3857)), scale: 1e5, completion: nil)
        
        //initialize route task
        routeTask = AGSRouteTask(url: URL(string: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/NetworkAnalysis/SanDiego/NAServer/Route")!)
        
        //add graphics
        addGraphics()
        
        //get default parameters
        getDefaultParameters()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - Graphic along line animation logic
    
    private func addCarGraphic() {
        
        if carGraphic == nil {
            //symbol for animating graphic
            let symbol = AGSPictureMarkerSymbol(image: #imageLiteral(resourceName: "CompassIcon"))
            symbol.angleAlignment = .map
            
            //graphic
            carGraphic = AGSGraphic(geometry: point1, symbol: symbol, attributes: nil)
        }
        
        //add graphics to the graphics overlay
        carGraphicsOverlay.graphics.add(carGraphic)
    }
    
    @IBAction func animate() {
        
        //works only if a route is already generated and referenced
        if let routeGeometry = generatedRoute?.routeGeometry {
            
            //add a car graphic
            addCarGraphic()

            //create an instance of helper class
            //use route geometry as the polyline, car graphic as the animating graphic
            animateAlongPathHelper = AnimateAlongPathHelper(polyline: routeGeometry,
                                                            animatingGraphic: carGraphic, speed: 2000)

            //start the animation
            animateAlongPathHelper.startAnimation()

            //assign self as delegate, will hide the car graphic once animation finishes
            animateAlongPathHelper.delegate = self


        }
    }
    
    //MARK: - AnimateAlongPathHelperDelegate
    
    func animateAlongPathHelperDidFinish(_ animateAlongPathHelper: AnimateAlongPathHelper) {
        
        //remove car graphic from the graphics overlay
        carGraphicsOverlay.graphics.remove(carGraphic)
    }
    
    //MARK: - Route logic
    
    private func addGraphics() {
        
        //symbol for start and stop points
        let symbol1 = AGSPictureMarkerSymbol(image: #imageLiteral(resourceName: "GreenMarker"))
        symbol1.offsetY = 22
        let symbol2 = AGSPictureMarkerSymbol(image: #imageLiteral(resourceName: "RedMarker"))
        symbol2.offsetY = 22
        
        //graphics
        let graphic1 = AGSGraphic(geometry: self.point1, symbol: symbol1, attributes: nil)
        let graphic2 = AGSGraphic(geometry: self.point2, symbol: symbol2, attributes: nil)
        
        //add these graphics to the overlay
        stopGraphicsOverlay.graphics.addObjects(from: [graphic1, graphic2])
    }
    
    func getDefaultParameters() {
        
        //get the default route parameters
        routeTask.defaultRouteParameters { [weak self] (params: AGSRouteParameters?, error: Error?) -> Void in
            if let error = error {
                SVProgressHUD.showError(withStatus: error.localizedDescription)
            }
            else {
                guard let defaultParams = params else {
                    SVProgressHUD.showError(withStatus: "Could not get default parameters!")
                    return
                }

                SVProgressHUD.dismiss()
                
                //enable bar button item
                self?.routeBBI.isEnabled = true
                
                self?.route(routeParameters:defaultParams)
            }
        }
    }
    
    @IBAction func route(routeParameters:AGSRouteParameters) {
        
        SVProgressHUD.show(withStatus: "Routing", maskType: SVProgressHUDMaskType.gradient)
        
        //clear routes
        routeGraphicsOverlay.graphics.removeAllObjects()
        
        //all calculations are in meters so need the directions geometry in web mercator
        routeParameters.outputSpatialReference = AGSSpatialReference.webMercator()
        
        //add stops
        routeParameters.setStops([AGSStop(point: point1), AGSStop(point: point2)])
        
        //solve route
        routeTask.solveRoute(with: routeParameters) { [weak self] (routeResult:AGSRouteResult?, error:Error?) -> Void in
            if let error = error {
                //show error
                SVProgressHUD.showError(withStatus: "\(error.localizedDescription) \((error as NSError).localizedFailureReason ?? "")")
            }
            else {
                //dismiss progress hud
                SVProgressHUD.dismiss()
                
                //if a route is found
                if let route = routeResult?.routes.first, let weakSelf = self {
                    
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
}
