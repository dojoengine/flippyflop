use starknet::ContractAddress;

#[derive(Serde, Copy, Drop)]
#[dojo::model]
#[dojo::event]
pub struct Tile {
    #[key]
    pub x: u32,
    #[key]
    pub y: u32,
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
