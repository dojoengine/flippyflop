use starknet::ContractAddress;

#[derive(Serde, Copy, Drop, PartialEq)]
enum PowerUp {
    None: (),
    Empty: (),
    Multiplier: u8,
}

impl PowerUpImpl of PowerUp {
    fn probability(self: PowerUp) -> u32 {
        match self {
            PowerUp::None => 9900,    // 99.00%
            PowerUp::Empty => 50,     // 0.50%
            PowerUp::Multiplier(2) => 30,  // 0.30%
            PowerUp::Multiplier(4) => 20,   // 0.20%
            PowerUp::Multiplier(8) => 10,   // 0.10%
            PowerUp::Multiplier(16) => 3,  // 0.05%
            PowerUp::Multiplier(32) => 1,  // 0.01%
            PowerUp::Multiplier(_) => 0,   // Invalid multiplier
        }
    }
}

#[derive(Serde, Copy, Drop)]
#[dojo::model]
#[dojo::event]
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
