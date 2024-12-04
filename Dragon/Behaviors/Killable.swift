//
//  Killable.swift
//
//  Created by Nick Lockwood on 28/04/2019.
//  Copyright © 2019 Nick Lockwood. All rights reserved.
//

protocol Killable: Entity {
    var health: Float { get set }

    func stagger()
    func die()
}

extension Killable {
    var isDead: Bool {
        return health <= 0
    }

    func hurt(_ damage: Float) {
        guard !isDead else {
            return
        }
        health -= damage
        if health <= 0 {
            die()
        } else {
            stagger()
        }
    }
}
