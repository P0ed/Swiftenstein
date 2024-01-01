import Cocoa

// framebuffer resolution
#if DEBUG
let resolution: Double = 512
#else
let resolution: Double = 512
#endif

// player walking speed
let walkSpeed = 2.0

// player turn speed
let turnSpeed = 3.0

// MARK: Set up images
// Sprites for wolfensstein 3d clone. 64x64 each frame. Monster sprite set consists of 13 frames: [idle, walk0, walk1, walk2, walk3, shoot0, shoot1, shoot2, die0, die1, die2, die3, die4]

let images = [
    // walls
    "eagle",
    "redbrick",
    "purplestone",
    "greystone",
    "bluestone",
    "mossy",
    "wood",
    "colorstone",
    // sprites
    "barrel", // 8
    "pillar",
    "greenlight",
    // guard
    "guard-idle", // 11
    "guard-walk0",
    "guard-walk1",
    "guard-walk2",
    "guard-walk3",
    "guard-shoot0", // 16
    "guard-shoot1",
    "guard-shoot2",
    "guard-die0", // 19
    "guard-die1",
    "guard-die2",
    "guard-die3",
    "guard-die4",
    // pistol
    "pistol0", // 24
    "pistol1",
    "pistol2",
    "pistol3",
    "pistol4",
    // door
    "door", // 29
    "doorframe",
    // smg
    "smg0", // 31
    "smg1",
    "smg2",
    "smg3",
    // pickups
    "smg", // 35
    "smg-ammo",
    "pistol-ammo",
    "medkit",
    // bullet impact
    "bullet-impact0", // 39
    "bullet-impact1",
    "bullet-impact2",
    // elevator
    "elevator-door", // 42
    "elevator-wall",
    "elevator-switch-off",
    "elevator-switch-on",
	"bng0", // 46
	"bng1",
	"bng2", // 48
	"smok0", // 49
	"smok1",
	"smok2",
	"smok3",
	"smok4",
	"smok5",
	"smok6",
	"smok7", // 56
].map(NSImage.init(named:))

let textures = images.map { Bitmap(image: $0!)! }

// MARK: Set up monsters

extension Animation {
    static let guardIdle = Animation(duration: 0, mode: .clamp, frames: [11])
    static let guardWalk = Animation(duration: 1, mode: .loop, frames: [12, 13, 14, 15])
    static let guardAim = Animation(duration: 0.5, mode: .reset, frames: [16, 17])
    static let guardShoot = Animation(duration: 0.5, mode: .clamp, frames: [18, 17])
    static let guardStagger = Animation(duration: 0.5, mode: .clamp, frames: [19, 11])
    static let guardDie = Animation(duration: 0.75, mode: .clamp, frames: [19, 20, 21, 22, 23])
}

extension MonsterType {
    static let `guard` = MonsterType(
        idle: .guardIdle,
        walking: .guardWalk,
        aiming: .guardAim,
        shooting: .guardShoot,
        staggering: .guardStagger,
        death: .guardDie
    )
}

extension Animation {
    static let impact = Animation(duration: 0.3, mode: .clamp, frames: [39, 40, 41])
	static let puff = Animation(duration: 0.4, mode: .clamp, frames: (49...56).map { $0 })
}

// MARK: Set up weapons

extension AmmoType {
    static let pistol = AmmoType()
    static let weed = AmmoType()
}

extension WeaponType {
    static let pistol = WeaponType(
        ammoType: .pistol,
        idle: Animation(duration: 0, mode: .clamp, frames: [28]),
        firing: Animation(duration: 0.5, mode: .clamp, frames: [24, 25, 26, 27, 28]),
        impact: .impact,
        cooldown: 0.5,
        damage: 20,
        spread: 0.03
    )
    static let smg = WeaponType(
        ammoType: .pistol,
        idle: Animation(duration: 0, mode: .clamp, frames: [31]),
        firing: Animation(duration: 0.4, mode: .clamp, frames: [34, 33, 32, 31]),
        impact: .impact,
        cooldown: 0.12,
        damage: 20,
        spread: 0.06
    )
	static let bng = WeaponType(
		ammoType: .weed,
		idle: Animation(duration: 0, mode: .clamp, frames: [46]),
		firing: Animation(duration: 0.5, mode: .clamp, frames: [47, 48]),
		impact: .puff,
		cooldown: 0.8,
		damage: 50,
		spread: 0.09
	)
}

// MARK: Set up pickups

extension PickupType {
	static let bng = PickupType(texture: 46, weapon: .bng, ammo: [.weed: 420])
	static let smg = PickupType(texture: 35, weapon: .smg, ammo: [.pistol: 90])
    static let smgAmmo = PickupType(texture: 36, ammo: [.weed: 30])
    static let pistolAmmo = PickupType(texture: 37, ammo: [.pistol: 50])
    static let medikit = PickupType(texture: 38, health: 50)
}

// MARK: Set up world

extension Animation {
    static let elevatorSwitch = Animation(duration: 0.25, mode: .clamp, frames: [43, 44])
}

extension MapTile: ExpressibleByIntegerLiteral {
    init(integerLiteral value: Int) {
        switch value {
        case 0:
            self = .floor
        case _ where value < 0:
            self = .pushWall(1 + value)
        case 30, 43:
            self = .door(value - 1, frame: 30)
        case 44:
            self = .elevator(value - 1)
        case 45:
            self = .switch(value - 1, alt: value)
        default:
            self = .wall(value - 1)
        }
    }
}

func makeWorld(delegate: PlayerDelegate) -> World {
    let world = World(
		map: .lvl0
    )

    func randomEntityPosition() -> Vector? {
        var locations = [Vector]()
        for y in 0 ..< world.map.height {
            for x in 0 ..< world.map.width {
                if case .floor = world.map[x, y] {
                    locations.append(Vector(Double(x) + 0.5, Double(y) + 0.5))
                }
            }
        }
        locations.shuffle()
        return locations.first(where: {
            let circle = Circle(center: $0, radius: 0.5)
            return !world.entities.contains(where: {
                $0.intersection(with: circle) != nil
            })
        })
    }

    func makeEntity(_ args: [Double]) -> Entity {
        switch args[0] {
        case 0:
            let texNum = Int(args[5])
            return Scenery(
                world: world,
                position: Vector(args[1], args[2]),
                radius: args[3],
                mass: args[4],
                texture: texNum
            )
        case 1:
            return Monster(
                type: .guard,
                world: world,
                position: Vector(args[1], args[2])
            )
        default:
            preconditionFailure()
        }
    }

    world.entities = [
        // lights
        [0, 20.5, 11.5, 0, 0, 10],
        [0, 18.5, 4.5, 0, 0, 10],
        [0, 10.0, 4.5, 0, 0, 10],
        [0, 10.0, 12.5, 0, 0, 10],
        [0, 3.5, 20.5, 0, 0, 10],
        [0, 3.5, 14.5, 0, 0, 10],
        [0, 14.5, 20.5, 0, 0, 10],

        // pillars
        [0, 18.5, 10.5, 0.2, .infinity, 9],
        [0, 18.5, 11.5, 0.2, .infinity, 9],
        [0, 18.5, 12.5, 0.2, .infinity, 9],

        // barrels
        [0, 21.5, 1.5, 0.25, 0.5, 8],
        [0, 15.5, 1.5, 0.25, 0.5, 8],
        [0, 16.0, 1.8, 0.25, 0.5, 8],
        [0, 3.5, 2.5, 0.25, 0.5, 8],
        [0, 9.5, 15.5, 0.25, 0.5, 8],
        [0, 10.0, 15.1, 0.25, 0.5, 8],
        [0, 10.5, 15.8, 0.25, 0.5, 8],

        // guards
        [1, 20.5, 11.5],
        [1, 2.5, 15.5],
    ].map(makeEntity)

    // Add door and pushwall partitions

    for y in 0 ..< world.map.height {
        for x in 0 ..< world.map.width {
            switch world.map[x, y] {
            case let .door(texNum, frame: _):
                let door = Door(world: world, texture: texNum, x: x, y: y)
                world.entities.append(door)
            case .switch:
                let `switch` = Switch(world: world, x: x, y: y)
                world.entities.append(`switch`)
            case let .pushWall(texNum):
                let pushWall = PushWall(world: world, texture: texNum, x: x, y: y)
                world.entities.append(pushWall)
            case .floor, .wall, .elevator:
                break
            }
        }
    }

    // Add SMG

	world.entities.append(Pickup(
		type: .smg,
		world: world,
		position: Vector(17.5, 9.5)
	))

	world.entities.append(Pickup(
		type: .bng,
		world: world,
		position: Vector(19.5, 9.5)
	))

    world.player = Player(
        world: world,
        delegate: delegate,
        position: Vector(18.5, 9.5),
        direction: Vector(0, 1)
    )

    world.entities.append(world.player)
    world.entities.append(world.player.weapon)

    // Add some random entities
    for _ in 0 ..< 20 {
        if let pos = randomEntityPosition() {
            world.entities.append(Monster(
                type: .guard,
                world: world,
                position: pos
            ))
        }
    }

    for _ in 0 ..< 10 {
        if let pos = randomEntityPosition() {
            world.entities.append(Pickup(
                type: .medikit,
                world: world,
                position: pos
            ))
        }
    }

    for _ in 0 ..< 5 {
        if let pos = randomEntityPosition() {
            world.entities.append(Pickup(
                type: .smgAmmo,
                world: world,
                position: pos
            ))
        }
    }

    for _ in 0 ..< 10 {
        if let pos = randomEntityPosition() {
            world.entities.append(Pickup(
                type: .pistolAmmo,
                world: world,
                position: pos
            ))
        }
    }

    return world
}
