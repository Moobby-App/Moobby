//
//  Cone.swift
//  moobby
//
//  Created by Maula Izza Azizi on 17/10/26.
//

import SwiftUI

/// A 60° wedge pointing up from the centre.
struct Cone: Shape {
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        var path = Path()
        path.move(to: center)
        path.addArc(center: center, radius: rect.width / 2,
                    startAngle: .degrees(-120), endAngle: .degrees(-60), clockwise: false)
        path.closeSubpath()
        return path
    }
}
