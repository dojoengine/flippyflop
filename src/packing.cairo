use starknet::ContractAddress;
use flippyflop::models::PowerUp;
use flippyflop::constants::{ADDRESS_MASK, POWERUP_MASK, POWERUP_DATA_MASK};

fn pack_flipped_data(address: felt252, powerup: PowerUp) -> felt252 {
    let address_bits: u256 = address.into();
    let (powerup_type, powerup_data) = match powerup {
        PowerUp::None => (0_u256, 0_u256),
        PowerUp::Empty => (1_u256, 0_u256),
        PowerUp::Multiplier(multiplier) => (2_u256, multiplier.into()),
    };
    
    let mut packed: u256 = 0_u256;
    packed = packed | (address_bits & ADDRESS_MASK);
    packed = packed | ((powerup_type * 256_u256) & POWERUP_MASK);
    packed = packed | (powerup_data & POWERUP_DATA_MASK);
    
    packed.try_into().unwrap()
}

fn unpack_flipped_data(flipped: felt252) -> (felt252, PowerUp) {
    let flipped_u256: u256 = flipped.into();
    let address: felt252 = (flipped_u256 & ADDRESS_MASK).try_into().unwrap();
    let powerup_type: felt252 = ((flipped_u256 & POWERUP_MASK) / 256_u256).try_into().unwrap();
    let powerup_data = flipped_u256 & POWERUP_DATA_MASK;
    
    let powerup = match powerup_type {
        0 => PowerUp::None,
        1 => PowerUp::Empty,
        2 => PowerUp::Multiplier(powerup_data.try_into().unwrap()),
        _ => PowerUp::None,
    };
    
    (address, powerup)
}