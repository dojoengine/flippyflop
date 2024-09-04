use starknet::ContractAddress;

#[derive(Serde, Copy, Drop)]
#[dojo::model]
pub struct Game {
    #[key]
    pub id: u32,
    pub is_locked: bool,
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
            PowerUp::None => 996858,    // 99.6858%
            PowerUp::Empty => 1500,     // 0.1500%
            PowerUp::Multiplier(val) => {
                if val == 2 {
                    1000  // 0.1000%
                } else if val == 4 {
                    500   // 0.0500%
                } else if val == 8 {
                    125   // 0.0125%
                } else if val == 16 {
                    12    // 0.0012%
                } else if val == 32 {
                    5     // 0.0005%
                } else {
                    0     // Invalid multiplier
                }
            },
        }
    }
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
