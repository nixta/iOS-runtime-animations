//
//  FlightRouteTools.swift
//  MapAnimations
//
//  Created by Nicholas Furness on 2/28/18.
//  Copyright © 2018 Nicholas Furness. All rights reserved.
//

import ArcGIS

extension Airport {
    func flightPath(to airport:Airport) -> AGSPolyline {
        return AGSPolyline(points: [self.mapPoint, airport.mapPoint])
    }
    func flightPath(from airport:Airport) -> AGSPolyline {
        return AGSPolyline(points: [airport.mapPoint, self.mapPoint])
    }
}

class FlightRouteTools {
    static let airports:[Airport] = [.atl, .bkk, .bom, .ccu, .cdg, .cun, .den, .dfw, .dxb, .eze, .gru, .hkg, .igt, .ist, .jfk, .kix, .lax, .lhr, .los, .mex, .mji, .nbo, .opo, .ord, .phl, .sea, .sfo, .sin, .thr, .yeg, .ymx, .yqb, .yvr, .ywg, .yyz]

    static func flightPathFrom(airport departureAirport:Airport, to destinationAirport:Airport, geodesic:Bool = true, targetSpatialReference targetSR:AGSSpatialReference = AGSSpatialReference.webMercator(), maxAltitudeInMeters:Double = 0) -> AGSPolyline {
        var polyline = departureAirport.flightPath(to: destinationAirport)

        if geodesic {
            polyline = AGSGeometryEngine.geodeticDensifyGeometry(polyline, maxSegmentLength: 100, lengthUnit: AGSLinearUnit.kilometers(), curveType: AGSGeodeticCurveType.normalSection) as! AGSPolyline
        }

        if maxAltitudeInMeters > 0 {
            var currentLength:Double = 0
            let totalLength = AGSGeometryEngine.geodeticLength(of: polyline, lengthUnit: AGSLinearUnit.meters(), curveType: .normalSection)
            let builder = AGSPolylineBuilder(spatialReference: polyline.spatialReference)
            var firstPoint:AGSPoint?
            for part in polyline.parts.array() {
                for point in part.points.array() {
                    if let firstPoint = firstPoint {
                        let result = AGSGeometryEngine.geodeticDistanceBetweenPoint1(firstPoint, point2: point, distanceUnit: AGSLinearUnit.meters(), azimuthUnit: AGSAngularUnit.degrees(), curveType: .normalSection)
                        currentLength = result?.distance ?? 0
                    } else {
                        firstPoint = point
                    }
                    let z = maxAltitudeInMeters * sin(Double.pi * currentLength / totalLength)
                    builder.addPointWith(x: point.x, y: point.y, z: z)
                }
            }
            polyline = builder.toGeometry()
        }
        if let sourceSR = polyline.spatialReference, !sourceSR.isEqual(to: targetSR) {
            polyline = AGSGeometryEngine.projectGeometry(polyline, to: AGSSpatialReference.webMercator()) as! AGSPolyline
        }

        return polyline
    }

    static func flightPathsFrom(airport departureAirport:Airport, maxDestinations:Int = airports.count, geodesic:Bool = true, targetSpatialReference targetSR:AGSSpatialReference = AGSSpatialReference.webMercator(), maxAltitudeInMeters:Double = 0) -> [Airport:AGSPolyline] {
        var flightPaths:[Airport:AGSPolyline] = [:]

        var count = 0
        
        for destinationAirport in airports {
            guard destinationAirport != departureAirport else {
                continue
            }

            guard count < maxDestinations else {
                break;
            }

            flightPaths[destinationAirport] = FlightRouteTools.flightPathFrom(airport: departureAirport, to: destinationAirport, geodesic: geodesic, targetSpatialReference: targetSR, maxAltitudeInMeters: maxAltitudeInMeters)

            count += 1
        }

        return flightPaths
    }
}
