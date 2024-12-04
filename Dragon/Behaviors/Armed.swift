//
//  Armed.swift
//
//  Created by Nick Lockwood on 28/04/2019.
//  Copyright © 2019 Nick Lockwood. All rights reserved.
//

import Foundation

protocol Armed: Actor {
    var lastFired: TimeInterval { get set }
    var weaponType: WeaponType? { get }

    func shoot() -> Bool
}

extension Armed {
    var canFire: Bool {
        guard let weaponType = weaponType else {
            return false
        }
        return world.time - lastFired >= weaponType.cooldown
    }

    func fire() {
        guard canFire, let weaponType, shoot() else { return }
        lastFired = world.time
        let spread = Double.random(in: -weaponType.spread ... weaponType.spread)
        let direction = direction.rotated(by: spread)
        let (distance, entity) = world.hitTest(Ray(
            origin: position,
            direction: direction
        ))

		let efDistance = min(distance, weaponType.distance ?? distance)

		if let impact = weaponType.impact {
			var explosion: Explosion!
			explosion = Explosion(
				world: world,
				position: position + direction * (efDistance - 0.02),
				animation: impact.then { explosion.world.remove(explosion) }
			)
			world.entities.append(explosion)
		}

		if distance == efDistance {
			if let killable = entity as? Killable {
				killable.hurt(weaponType.damage)
				return
			}
			if let movable = entity as? Movable {
				movable.position += direction * 0.02 / movable.mass
			}
		}
    }
}
