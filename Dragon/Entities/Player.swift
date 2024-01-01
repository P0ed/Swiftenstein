//
//  Player.swift
//
//  Created by Nick Lockwood on 28/04/2019.
//  Copyright © 2019 Nick Lockwood. All rights reserved.
//

import Foundation

protocol PlayerDelegate: AnyObject {
    func playerWasHurt(_ player: Player)
    func playerWasKilled(_ player: Player)
    func playerPoweredUp(_ player: Player)
    func playerDidEndLevel(_ player: Player)
}

class Player: Actor, Killable, Armed, Switcher {
	let fov: Double = .pi / 2
    var radius = 0.2

    var eyeline = 0.5
    var position: Vector
    var direction: Vector
    var health: Double = 100

    var bobPhase = 0.0
    let bobScale = 0.025
    let weaponSway = 0.05

    var ammo: [AmmoType: Int] = [:]
    var weapons: [WeaponType] = []
	var weaponIndex: Int = 0

    var lastFired: TimeInterval = 0
    let weapon: PlayerWeapon
    var weaponType: WeaponType? { weapon.type }

    unowned let world: World
    weak var delegate: PlayerDelegate?

    init(world: World, delegate: PlayerDelegate, position: Vector, direction: Vector) {
        self.world = world
        self.delegate = delegate
        self.position = position
        self.direction = direction
        ammo = [.pistol: 20]
        weapons = [.pistol]
		weaponIndex = 0
        weapon = PlayerWeapon(world: world, weapon: .pistol)
    }

    func rotate(_ radians: Double) {
        direction = direction.rotated(by: radians)
    }

    func advance(_ distance: Double) {
        bobPhase += distance
        eyeline = 0.5 + (1 + sin(bobPhase * .pi * 2)) * bobScale
        position += direction * distance
    }

    func strafe(_ distance: Double) {
        position += Vector(-direction.y, direction.x) * distance
    }

    func stagger() {
        delegate?.playerWasHurt(self)
    }

    func die() {
        radius = 0.01
        delegate?.playerWasKilled(self)
    }

    func shoot() {
        let ammoType = weapon.type?.ammoType
        if let ammoType = ammoType {
            if let ammoCount = ammo[ammoType], ammoCount > 0 {
                weapon.fire()
                ammo[ammoType] = ammoCount - 1
            } else {
                weapon.type = weapons.first { $0.ammoType.map { ammo[$0] ?? 0 > 0 } ?? true }
            }
        } else {
            weapon.fire()
        }
    }

	func selectWeapon(type: WeaponType) {
		guard let idx = weapons.firstIndex(of: type) else { return }
		weaponIndex = idx
		weapon.type = type
	}

	func prevBong() {
		selectWeapon(type: weapons[(weapons.count + weaponIndex - 1) % weapons.count])
	}

	func nextBong() {
		selectWeapon(type: weapons[(weaponIndex + 1) % weapons.count])
	}

    func powerUp(_ pickup: PickupType) {
        health += pickup.health
        for (ammoType, ammo) in pickup.ammo {
            let ammoCount = self.ammo[ammoType] ?? 0
            self.ammo[ammoType] = ammoCount + ammo
            if ammoCount == 0 {
                weapon.type = weapons.first(where: {
                    $0.ammoType == ammoType
                })
            }
        }
        if let weaponType = pickup.weapon, !weapons.contains(weaponType) {
            weapons.append(weaponType)
			selectWeapon(type: weaponType)
        }
        if weapon.type == nil {
            weapon.type = weapons.first { $0.ammoType.map { ammo[$0] ?? 0 > 0 } ?? true }
        }
        delegate?.playerPoweredUp(self)
    }

    func didActivateSwitch(_: Switch) {
        delegate?.playerDidEndLevel(self)
    }

    func update(dt: TimeInterval) {
        if isDead {
            eyeline = max(0.1, eyeline - dt * 0.2)
            weapon.position = position - direction
        } else {
            let (d, _) = world.hitTest(Ray(origin: position, direction: direction))
            let weaponDistance = min(d - 0.1, 0.2)
            let sway = sin(bobPhase * .pi) * weaponSway
            weapon.position = position + direction.rotated(by: sway) * weaponDistance
        }
    }
}
