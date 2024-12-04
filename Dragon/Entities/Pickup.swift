//
//  Pickups.swift
//
//  Created by Nick Lockwood on 26/04/2019.
//  Copyright © 2019 Nick Lockwood. All rights reserved.
//

import Foundation

struct PickupType {
    let texture: Int
	let health: Float
    let weapon: WeaponType?
    let ammo: [AmmoType: Int]

    init(texture: Int,
         health: Float = 0,
         weapon: WeaponType? = nil,
         ammo: [AmmoType: Int] = [:]) {
        self.texture = texture
        self.health = health
        self.weapon = weapon
        self.ammo = ammo
    }
}

class Pickup: Trigger, Sprite {
    let position: Vector
    let radius = 0.2
    let isSolid = false
    let type: PickupType

    unowned let world: World

    var texture: Int? {
        return type.texture
    }

    init(type: PickupType, world: World, position: Vector) {
        self.type = type
        self.world = world
        self.position = position
    }

    func activate(with entity: Entity) {
        guard let player = entity as? Player else {
            return
        }
        player.powerUp(type)
        world.remove(self)
    }
}
