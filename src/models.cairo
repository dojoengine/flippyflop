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
