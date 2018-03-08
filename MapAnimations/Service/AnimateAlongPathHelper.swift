//
//  AnimateAlongPath.swift
//  MapAnimations
//
//  Created by Gagandeep Singh on 2/28/17.
//  Copyright © 2017 Gagandeep Singh. All rights reserved.
//

import UIKit
import ArcGIS

@objc protocol AnimateAlongPathHelperDelegate:class {
    
    @objc optional func animateAlongPathHelperDidFinish(_ animateAlongPathHelper:AnimateAlongPathHelper)
}

class AnimateAlongPathHelper: NSObject {

    private var polyline:AGSPolyline
    private var speed:Double
    private var animatingGraphic:AGSGraphic

    weak var delegate:AnimateAlongPathHelperDelegate?

    var headingAttribute:String?
    
    init(polyline: AGSPolyline, animatingGraphic: AGSGraphic, speed: Double) {
        self.polyline = polyline
        self.animatingGraphic = animatingGraphic
        self.animatingGraphic.isVisible = false
        self.speed = speed
        
        super.init()
    }
    
    func startAnimation() {
        let length = AGSGeometryEngine.length(of: polyline)
        let duration = length/speed
        let startTime = Date()

        AnimationManager.animate(animationBlock: { [weak self] () -> Bool in
            guard let fullPolyline = self?.polyline else { return true }

            let doneFactor = Date().timeIntervalSince(startTime) / duration
            let newLocation = AGSGeometryEngine.point(along: fullPolyline,
                                                      distance: length * doneFactor)

            let oldLocation = self?.animatingGraphic.geometry
            self?.animatingGraphic.geometry = newLocation

            if let oldLocation = oldLocation as? AGSPoint, let newLocation = newLocation {
                self?.setMarkerSymbolRotation(point1: oldLocation, point2: newLocation)

                if self?.animatingGraphic.isVisible != true {
                    self?.animatingGraphic.isVisible = true
                }
            }

            return doneFactor >= 1
            }, completion: { [weak self] in
                if let me = self {
                    self?.delegate?.animateAlongPathHelperDidFinish?(me)
                }
        })
    }
    
    func setMarkerSymbolRotation(point1:AGSPoint, point2:AGSPoint) {
        //update rotation of the animating graphic to face in the right direction
        if let symbol = self.animatingGraphic.symbol as? AGSMarkerSymbol {
            symbol.angle = Float(self.getAngle(point1, p2: point2))
        } else if let headingAttribute = headingAttribute {
            self.animatingGraphic.attributes["\(headingAttribute)"] = Float(self.getAngle(point1, p2: point2))
        }
    }
    
    //get angle between line joining the points and north
    private func getAngle(_ p1: AGSPoint, p2: AGSPoint) -> Double {
        return AGSGeometryEngine.geodeticDistanceBetweenPoint1(p1, point2: p2, distanceUnit: AGSLinearUnit.meters(), azimuthUnit: AGSAngularUnit.degrees(), curveType: AGSGeodeticCurveType.geodesic)?.azimuth1 ?? 0
    }
}
