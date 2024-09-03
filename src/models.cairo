use starknet::ContractAddress;

#[derive(Serde, Copy, Drop, Introspect, PartialEq)]
enum PowerUp {
    None: (),
    Empty: (),
    Multiplier: u8,
}

trait PowerUpTrait {
    fn probability(self: PowerUp) -> u32;
}

impl PowerUpImpl of PowerUpTrait {
    fn probability(self: PowerUp) -> u32 {
        match self {
            PowerUp::None => 990000,    // 99.0000%
            PowerUp::Empty => 5000,     // 0.5000%
            PowerUp::Multiplier(val) => {
                if val == 2 {
                    4000  // 0.4000%
                } else if val == 4 {
                    800   // 0.0800%
                } else if val == 8 {
                    160   // 0.0160%
                } else if val == 16 {
                    32    // 0.0032%
                } else if val == 32 {
                    6     // 0.0006%
                } else {
                    0     // Invalid multiplier
                }
            },
        }
    }
}

#[derive(Serde, Copy, Drop)]
#[dojo::model]
pub struct Tile {
    #[key]
    pub x: u32,
    #[key]
    pub y: u32,
    // 2**244 address | 2**4 powerup | 2**4 powerup data
    pub flipped: felt252,
}

#[derive(Serde, Drop)]
#[dojo::model]
pub struct User {
    #[key]
    pub identity: ContractAddress,
    pub last_message: ByteArray,
    pub hovering_tile_x: u32,
    pub hovering_tile_y: u32,
}
