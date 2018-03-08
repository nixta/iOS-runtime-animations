//
//  FlightPathsViewController.swift
//  MapAnimations
//
//  Created by Gagandeep Singh on 3/4/17.
//  Copyright © 2017 Gagandeep Singh. All rights reserved.
//

import UIKit
import ArcGIS

private let kHeadingField = "HEADING"
private let kPitchField = "PITCH"
private let kRollField = "ROLL"

class FlightPaths3DViewController: AnimationDemoViewController, AGSGeoViewTouchDelegate {

    @IBOutlet weak var sceneView: AGSSceneView!
    
    private lazy var airportGraphicsOverlay:AGSGraphicsOverlay = {
        let overlay = AGSGraphicsOverlay()
        let renderer = AGSSimpleRenderer()
        renderer.symbol = AGSSimpleMarkerSymbol(style: .circle, color: UIColor.brown, size: 15)

        overlay.renderer = renderer
        overlay.sceneProperties?.surfacePlacement = .absolute

        return overlay
    }()

    private lazy var planeGraphicsOverlay:AGSGraphicsOverlay = {
        let overlay = AGSGraphicsOverlay()

        let renderer = AGSSimpleRenderer()
        renderer.symbol = makePlaneModelSymbol()
        renderer.sceneProperties?.headingExpression = "[\(kHeadingField)]"
        renderer.sceneProperties?.pitchExpression = "\(kPitchField)"
        renderer.sceneProperties?.rollExpression = "\(kRollField)"

        overlay.renderer = renderer
        overlay.renderingMode = .dynamic
        overlay.sceneProperties?.surfacePlacement = .relative

        return overlay
    }()

    private lazy var routeGraphicsOverlay:AGSGraphicsOverlay = {
        let overlay = AGSGraphicsOverlay()
        let renderer = AGSSimpleRenderer()
        renderer.symbol = AGSSimpleLineSymbol(style: .solid, color: UIColor.blue.withAlphaComponent(0.7), width: 2)

        overlay.renderer = renderer
        overlay.renderingMode = .dynamic
        overlay.sceneProperties?.surfacePlacement = .relative

        return overlay
    }()

    private lazy var hiddenRouteGraphicsOverlay:AGSGraphicsOverlay = {
        let overlay = AGSGraphicsOverlay()
        let renderer = AGSSimpleRenderer()
        renderer.symbol = AGSSimpleLineSymbol(style: .solid, color: UIColor.orange, width: 2)

        overlay.renderer = renderer
        overlay.sceneProperties?.surfacePlacement = .draped

        return overlay
    }()
    
    private var lineTraceAnimationHelpers:[AnimateLineTraceHelper]!
    private var animateAlongPathHelpers:[AnimateAlongPathHelper]!

    private var cameraController:AGSOrbitGeoElementCameraController? {
        didSet {
            if cameraController == nil {
                sceneView.cameraController = AGSGlobeCameraController()
            } else {
                sceneView.cameraController = cameraController
            }
        }
    }

    private let flightPathsFromLHR:[Airport:AGSPolyline] = {
//        let destinationAirport = Airport.den
//        return [destinationAirport:FlightRouteTools.flightPathFrom(airport: .lhr, to: destinationAirport, geodesic: true, maxAltitudeInMeters: 10000)]
        return FlightRouteTools.flightPathsFrom(airport: .lhr, maxDestinations: 20, geodesic: true, maxAltitudeInMeters: 10000)
    }()

    private func makePlaneModelSymbol() -> AGSSymbol {
        let smallPlaneSymbol = AGSModelSceneSymbol(name: "Bristol", extension: "dae", scale: 500)
        let mediumPlaneSymbol = AGSModelSceneSymbol(name: "Bristol", extension: "dae", scale: 2200)
        let largeConeSymbol = AGSSimpleMarkerSceneSymbol(style: .cone, color: UIColor(red:0.48, green:0.71, blue:0.98, alpha:1.00), height: 12000, width: 6000, depth: 6000, anchorPosition: .center)
        largeConeSymbol.pitch = -90
        let hugeConeSymbol = AGSSimpleMarkerSceneSymbol(style: .cone, color: UIColor(red:0.48, green:0.71, blue:0.98, alpha:1.00), height: 60000, width: 25000, depth: 25000, anchorPosition: .center)
        hugeConeSymbol.pitch = -90

        let planeSymbol = AGSDistanceCompositeSceneSymbol()
        planeSymbol.ranges.append(AGSDistanceSymbolRange(symbol: smallPlaneSymbol, minDistance: 0, maxDistance: 10000))
        planeSymbol.ranges.append(AGSDistanceSymbolRange(symbol: mediumPlaneSymbol, minDistance: 10001, maxDistance: 900000))
        planeSymbol.ranges.append(AGSDistanceSymbolRange(symbol: largeConeSymbol, minDistance: 900001, maxDistance: 2000000))
        planeSymbol.ranges.append(AGSDistanceSymbolRange(symbol: hugeConeSymbol, minDistance: 2000001, maxDistance: 0))

        return planeSymbol
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let scene = AGSScene(basemap: AGSBasemap.topographic())
        self.sceneView.scene = scene

        let elevationSource = AGSArcGISTiledElevationSource(url: URL(string: "https://elevation3d.arcgis.com/arcgis/rest/services/WorldElevation3D/Terrain3D/ImageServer")!)
        let surface = AGSSurface()
        surface.elevationSources.append(elevationSource)
        surface.elevationExaggeration = 10
        scene.baseSurface = surface
        
        self.sceneView.graphicsOverlays.addObjects(from: [self.airportGraphicsOverlay, self.routeGraphicsOverlay, self.planeGraphicsOverlay])

        self.createFlightRoutes()

        sceneView.touchDelegate = self
    }

    func createFlightRoutes() {
        let departureAirport = Airport.lhr

        self.sceneView.setViewpoint(AGSViewpoint(center: departureAirport.mapPoint, scale: 6750000))

        let startAirportGraphic = AGSGraphic(geometry: departureAirport.mapPoint, symbol: nil, attributes: nil)
        self.airportGraphicsOverlay.graphics.add(startAirportGraphic)

        for (destinationAirport, flightPath) in flightPathsFromLHR {
            let endAirportGraphic = AGSGraphic(geometry: destinationAirport.mapPoint, symbol: nil, attributes: nil)
            self.airportGraphicsOverlay.graphics.add(endAirportGraphic)

            let flightPathGraphic = AGSGraphic(geometry: flightPath, symbol: nil, attributes: [
                "Departure":departureAirport,
                "Destination": destinationAirport])
            self.hiddenRouteGraphicsOverlay.graphics.add(flightPathGraphic)
        }
    }


    @IBAction func animateBoth() {

        //clear graphics
        self.clearGraphics()

        //initialize arrays
        self.animateAlongPathHelpers = [AnimateAlongPathHelper]()
        self.lineTraceAnimationHelpers = [AnimateLineTraceHelper]()

        for (airport, flightPath) in flightPathsFromLHR {

            let planeGraphic = AGSGraphic(geometry: nil, symbol: nil, attributes: [
                kHeadingField: 0,
                kPitchField: 0,
                kRollField: 0,
                "Destination":"\(airport)"])

            let routeGraphic = AGSGraphic(geometry: flightPath, symbol: nil, attributes: ["Destination": airport])

            let randomSpeed = Double(arc4random_uniform(30000)) + 60000.0

            let animateAlongPathHelper = AnimateAlongPathHelper(polyline: flightPath, animatingGraphic: planeGraphic, speed: randomSpeed)
            animateAlongPathHelper.headingAttribute = kHeadingField
            let lineTraceAnimationHelper = AnimateLineTraceHelper(polyline: flightPath, animatingGraphic: routeGraphic, speed: randomSpeed, generalize: true)
            lineTraceAnimationHelper.name = "Flightpath to \(airport)"

            lineTraceAnimationHelper.startAnimation()
            self.routeGraphicsOverlay.graphics.add(routeGraphic)

            animateAlongPathHelper.startAnimation()
            self.planeGraphicsOverlay.graphics.add(planeGraphic)

            self.lineTraceAnimationHelpers.append(lineTraceAnimationHelper)
            self.animateAlongPathHelpers.append(animateAlongPathHelper)
        }
    }


    func geoView(_ geoView: AGSGeoView, didDoubleTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint, completion: @escaping (Bool) -> Void) {
        if AnimationManager.isPaused {
            AnimationManager.resumeAnimations()
        } else {
            AnimationManager.pauseAnimations()
        }
    }


    func spinCameraAround(plane graphic:AGSGraphic) {
        cameraController = AGSOrbitGeoElementCameraController(targetGeoElement: graphic, distance: 1000)
        self.sceneView.cameraController = cameraController
    }

    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        guard let focusPlane = getRandomPlaneGraphic() else {
            print("Could not find plane!")
            return
        }

        let controller = AGSOrbitGeoElementCameraController(targetGeoElement: focusPlane, distance: 80000)
        controller.cameraHeadingOffset = Double(arc4random_uniform(360))
        controller.cameraPitchOffset = 80
        sceneView.cameraController = controller
    }

    @IBAction func spinAround() {
        guard let controller = sceneView.cameraController as? AGSOrbitGeoElementCameraController else {
            print("No orbit controller to spin")
            return
        }

        controller.moveCamera(withDistanceDelta: 500000, headingDelta: 200, pitchDelta: 0, duration: 4) { (finished) in
            controller.moveCamera(withDistanceDelta: -500000, headingDelta: 460, pitchDelta: 0, duration: 4.5, completion: { (finishedPitch) in
                print("Done spinning")
            })
        }
    }



    func getFirstPlaneGraphic() -> AGSGraphic? {
        let plane = planeGraphicsOverlay.graphics.first(where: { (graphic) -> Bool in
            if let plane = graphic as? AGSGraphic, let _ = plane.attributes["Destination"] as? String {
                return true
            }
            return false
        }) as? AGSGraphic
        return plane
    }

    func getRandomPlaneGraphic() -> AGSGraphic? {
        guard let planes = planeGraphicsOverlay.graphics.flatMap ({ (graphic) -> AGSGraphic? in
            if let plane = graphic as? AGSGraphic, let _ = plane.attributes["Destination"] as? String {
                return plane
            }
            return nil
        }) as? [AGSGraphic], planes.count > 0 else {
            print("Couldn't find a plane")
            return nil
        }

        let index = Int(arc4random_uniform(UInt32(planes.count)))
        let plane = planes[index]

        return plane
    }

    func getPlaneGraphic(airport:Airport) -> AGSGraphic? {
        for plane in planeGraphicsOverlay.graphics where plane is AGSGraphic {
            let plane = plane as! AGSGraphic
            if plane.attributes["Destination"] as? String == "\(airport)" {
                return plane
            }
        }
        return nil
    }
    
    @IBAction func switchValueChanged(sender: UISwitch) {
        if sender.isOn {
            self.sceneView.graphicsOverlays.insert(self.hiddenRouteGraphicsOverlay, at: 1)
        }
        else {
            self.sceneView.graphicsOverlays.remove(self.hiddenRouteGraphicsOverlay)
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
