import CoreGraphics
import Foundation

enum AngleCalculator {
    static func angle(pointA: CGPoint, vertex: CGPoint, pointC: CGPoint) -> Double {
        let vectorAV = CGVector(dx: pointA.x - vertex.x, dy: pointA.y - vertex.y)
        let vectorCV = CGVector(dx: pointC.x - vertex.x, dy: pointC.y - vertex.y)

        let dotProduct = vectorAV.dx * vectorCV.dx + vectorAV.dy * vectorCV.dy
        let magnitudeAV = sqrt(vectorAV.dx * vectorAV.dx + vectorAV.dy * vectorAV.dy)
        let magnitudeCV = sqrt(vectorCV.dx * vectorCV.dx + vectorCV.dy * vectorCV.dy)

        guard magnitudeAV > 0, magnitudeCV > 0 else { return 0 }

        let cosAngle = max(-1, min(1, dotProduct / (magnitudeAV * magnitudeCV)))
        return acos(cosAngle) * 180.0 / .pi
    }
}
