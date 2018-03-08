//
//  FlightPathsViewController.swift
//  MapAnimations
//
//  Created by Gagandeep Singh on 3/4/17.
//  Copyright © 2017 Gagandeep Singh. All rights reserved.
//

import UIKit
import ArcGIS

private let kHeadingAttribute = "HEADING"

private func randomTimeInterval(maxSecondsFromNow seconds:Double) -> Double {
    return Double(arc4random_uniform(UInt32(seconds * 33000))) / 33000
}

private func randomSpeed() -> Double {
    return 10000 * (Double(arc4random_uniform(9)) + 1)
}

class FlightPathsViewController: AnimationDemoViewController {

    @IBOutlet var mapView:AGSMapView!
    
    private var airportGraphicsOverlay = AGSGraphicsOverlay()
    private var planeGraphicsOverlay:AGSGraphicsOverlay = {
        let overlay = AGSGraphicsOverlay()

        let planeSymbol = AGSPictureMarkerSymbol(image: #imageLiteral(resourceName: "plane"))
        planeSymbol.angleAlignment = .map

        let renderer = AGSSimpleRenderer()
        renderer.rotationExpression = "[\(kHeadingAttribute)]"
        renderer.symbol = planeSymbol

        overlay.renderer = renderer

        return overlay
    }()
    private var routeGraphicsOverlay = AGSGraphicsOverlay()
    private var hiddenRouteGraphicsOverlay = AGSGraphicsOverlay()
    
    private var lineTraceAnimationHelpers:[AnimateLineTraceHelper]!
    private var animateAlongPathHelpers:[AnimateAlongPathHelper]!

    private let flightPathsFromLHR:[Airport:AGSPolyline] = {
        return FlightRouteTools.flightPathsFrom(airport: .lhr, geodesic: true, maxAltitudeInMeters: 10000)
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let map = AGSMap(basemap: AGSBasemap.topographic())
        self.mapView.map = map
        
        self.mapView.graphicsOverlays.addObjects(from: [self.airportGraphicsOverlay, self.routeGraphicsOverlay, self.planeGraphicsOverlay])
        
        self.createFlightRoutes()
    }
    
    @IBAction func animatePlanes() {
        
        //clear graphics
        self.clearGraphics()

        AnimationManager.reset()
        
        //initialize array
        self.animateAlongPathHelpers = [AnimateAlongPathHelper]()
        
        for (airport, flightPath) in flightPathsFromLHR {

            let planeGraphic = AGSGraphic(geometry: nil, symbol: nil, attributes: [
                "Destination": airport,
                kHeadingAttribute: 0
                ])
            
            let randomTime = randomTimeInterval(maxSecondsFromNow: 15)
            let speed = randomSpeed()

            let animateAlongPathHelper = AnimateAlongPathHelper(polyline: flightPath,
                                                                animatingGraphic: planeGraphic,
                                                                speed: speed)
            animateAlongPathHelper.headingAttribute = kHeadingAttribute

            DispatchQueue.main.asyncAfter(deadline: .now() + randomTime, execute: { [weak self] in
                guard self != nil else {
                    // The view has been destroyed - we're not watching this demo any more so let's
                    // just pass on the opportunity to kick off an animation that'll never be seen.
                    return
                }

                self?.planeGraphicsOverlay.graphics.add(planeGraphic)
                animateAlongPathHelper.startAnimation()
            })
            
            self.animateAlongPathHelpers.append(animateAlongPathHelper)
        }
    }
    
    @IBAction func animateRoutes() {
        
        //clear existing graphics
        self.clearGraphics()

        AnimationManager.reset()
        
        //initialize array to store helper objects
        self.lineTraceAnimationHelpers = [AnimateLineTraceHelper]()
        
        //loop through each polyline to create and start animation
        for (airport, flightPath) in flightPathsFromLHR {
            
            //
            let symbol = AGSSimpleLineSymbol(style: .solid, color: UIColor.blue, width: 2)
            let graphic = AGSGraphic(geometry: nil, symbol: symbol, attributes: [
                "Destination": airport,
                kHeadingAttribute: 0
                ])
            
            let randomTime = randomTimeInterval(maxSecondsFromNow: 15)
            let speed = randomSpeed()

            let lineTraceAnimationHelper = AnimateLineTraceHelper(polyline: flightPath, animatingGraphic: graphic, speed: speed)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + randomTime, execute: { [weak self] in
                guard self != nil else {
                    // The view has been destroyed - we're not watching this demo any more so let's
                    // just pass on the opportunity to kick off an animation that'll never be seen.
                    return
                }

                lineTraceAnimationHelper.startAnimation()
                self?.routeGraphicsOverlay.graphics.add(graphic)
            })
            
            self.lineTraceAnimationHelpers.append(lineTraceAnimationHelper)
        }
    }
    
    @IBAction func animateBoth() {
        
        //clear graphics
        self.clearGraphics()

        AnimationManager.reset()
        
        //initialize arrays
        self.animateAlongPathHelpers = [AnimateAlongPathHelper]()
        self.lineTraceAnimationHelpers = [AnimateLineTraceHelper]()
        
        for (airport,flightPath) in flightPathsFromLHR {
            
            let planeGraphic = AGSGraphic(geometry: nil, symbol: nil, attributes: [
                "Destination": airport,
                kHeadingAttribute: 0
                ])
            
            let routeSymbol = AGSSimpleLineSymbol(style: .solid, color: UIColor.blue, width: 2)
            let routeGraphic = AGSGraphic(geometry: flightPath, symbol: routeSymbol, attributes: ["Destination":airport])
            
            let randomTime = randomTimeInterval(maxSecondsFromNow: 15)
            let speed = randomSpeed()
            
            let animateAlongPathHelper = AnimateAlongPathHelper(polyline: flightPath,
                                                                animatingGraphic: planeGraphic,
                                                                speed: speed)
            let lineTraceAnimationHelper = AnimateLineTraceHelper(polyline: flightPath,
                                                                  animatingGraphic: routeGraphic,
                                                                  speed: speed)

            animateAlongPathHelper.headingAttribute = kHeadingAttribute

            DispatchQueue.main.asyncAfter(deadline: .now() + randomTime, execute: { [weak self] in
                guard self != nil else {
                    // The view has been destroyed - we're not watching this demo any more so let's
                    // just pass on the opportunity to kick off an animation that'll never be seen.
                    return
                }

                lineTraceAnimationHelper.startAnimation()
                self?.routeGraphicsOverlay.graphics.add(routeGraphic)
                
                animateAlongPathHelper.startAnimation()
                self?.planeGraphicsOverlay.graphics.add(planeGraphic)
            })
            
            self.lineTraceAnimationHelpers.append(lineTraceAnimationHelper)
            self.animateAlongPathHelpers.append(animateAlongPathHelper)
        }
    }
    
    @IBAction func switchValueChanged(sender: UISwitch) {
        if sender.isOn {
            self.mapView.graphicsOverlays.insert(self.hiddenRouteGraphicsOverlay, at: 1)
        }
        else {
            self.mapView.graphicsOverlays.remove(self.hiddenRouteGraphicsOverlay)
        }
    }
    
    private func clearGraphics() {
        
        self.planeGraphicsOverlay.graphics.removeAllObjects()
        self.routeGraphicsOverlay.graphics.removeAllObjects()
        
        //stop animation
        self.animateAlongPathHelpers?.removeAll()
        self.lineTraceAnimationHelpers?.removeAll()
    }
    
    //MARK : - Helper
    
    func createFlightRoutes() {
        self.mapView.setViewpointCenter(Airport.lhr.mapPoint, scale: 6750011.74, completion: nil)
        
        let airportSymbol = AGSSimpleMarkerSymbol(style: .circle, color: UIColor.brown, size: 15)
        let airportGraphic = AGSGraphic(geometry: Airport.lhr.mapPoint, symbol: airportSymbol, attributes: nil)
        self.airportGraphicsOverlay.graphics.add(airportGraphic)
        
        let symbol = AGSSimpleLineSymbol(style: .solid, color: UIColor.orange, width: 2)

        for (airport, flightPath) in flightPathsFromLHR {
            let graphic = AGSGraphic(geometry: flightPath, symbol: symbol, attributes: ["Destination":airport])
            self.hiddenRouteGraphicsOverlay.graphics.add(graphic)
        }
    }

    private func randomColor() -> UIColor {
        //let r = CGFloat(arc4random_uniform(255)) / 255.0
        //let g = CGFloat(arc4random_uniform(255)) / 255.0
        //let b = CGFloat(arc4random_uniform(255)) / 255.0
        //return UIColor(red: r, green: g, blue: b, alpha: 1)
        
        let h = CGFloat(arc4random_uniform(255)) / 255.0
        return UIColor(hue: h, saturation: 1, brightness: 0.7, alpha: 1)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
