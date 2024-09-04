// define the interface
#[dojo::interface]
trait IActions {
    fn flip(ref world: IWorldDispatcher, x: u32, y: u32);
    fn flop(ref world: IWorldDispatcher);
}

const TILE_MODEL_SELECTOR: felt252 =
    0x61fb9291a47fbce6a74257be2400d0f807067fd73e6437aa3f7461c38153492;
const TILE_FLIPPED_SELECTOR: felt252 =
    0x1cc1e903b2099cf12a3c9efcefe94e8820db24825120dfb35aa6c519a16b10e;
const X_BOUND: u32 = 100;
const Y_BOUND: u32 = 100;
const ADDRESS_BITMAP: u256 = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0000_u256;

// dojo decorator
#[dojo::contract]
mod actions {
    use super::{IActions, TILE_MODEL_SELECTOR, TILE_FLIPPED_SELECTOR, X_BOUND, Y_BOUND, ADDRESS_BITMAP};
    use starknet::{ContractAddress, get_caller_address, info::get_tx_info};
    use flippyflop::models::{Tile, PowerUp, PowerUpTrait};
    use core::poseidon::poseidon_hash_span;
    use dojo::model::{FieldLayout, Layout};

    fn get_random_powerup(seed: felt252) -> PowerUp {
        let tx_hash = get_tx_info().transaction_hash;
        let hash: u256 = poseidon_hash_span(array![seed, tx_hash].span()).into();
        let random_value: u32 = (hash % 10000).try_into().unwrap();
        
        if random_value < PowerUp::Multiplier(32).probability() {
            PowerUp::Multiplier(32)
        } else if random_value < PowerUp::Multiplier(16).probability() {
            PowerUp::Multiplier(16)
        } else if random_value < PowerUp::Multiplier(8).probability() {
            PowerUp::Multiplier(8)
        } else if random_value < PowerUp::Multiplier(4).probability() {
            PowerUp::Multiplier(4)
        } else if random_value < PowerUp::Multiplier(2).probability() {
            PowerUp::Multiplier(2)
        } else if random_value < PowerUp::Empty.probability() {
            PowerUp::Empty
        } else {
            PowerUp::None
        }
    }

    fn pack_flipped_data(address: felt252, powerup: PowerUp) -> felt252 {
        let address_bits: u256 = address.into();
        let (powerup_type, powerup_data) = match powerup {
            PowerUp::None => (0_u256, 0_u256),
            PowerUp::Empty => (1_u256, 0_u256),
            PowerUp::Multiplier(multiplier) => (2_u256, multiplier.into()),
        };
        
        let mut packed: u256 = 0_u256;
        packed = packed | (address_bits & ADDRESS_BITMAP);
        packed = packed | ((powerup_type * 16_u256) & 0xF0_u256);
        packed = packed | (powerup_data & 0x0F_u256);
        
        packed.try_into().unwrap()
    }

    fn unpack_flipped_data(flipped: felt252) -> (ContractAddress, PowerUp) {
        let flipped_u256: u256 = flipped.into();
        let address: felt252 = (flipped_u256 & ADDRESS_BITMAP).try_into().unwrap();
        let powerup_type: felt252 = ((flipped_u256 & 0xF0_u256) / 16_u256).try_into().unwrap();
        let powerup_data = flipped_u256 & 0x0F_u256;
        
        let powerup = match powerup_type {
            0 => PowerUp::None,
            1 => PowerUp::Empty,
            2 => PowerUp::Multiplier(powerup_data.try_into().unwrap()),
            _ => PowerUp::None,
        };
        
        (address.try_into().unwrap(), powerup)
    }
    
    #[abi(embed_v0)]
    impl ActionsImpl of IActions<ContractState> {
        // Humans can only flip unflipped tiles, but they can chose their tile to unflip.
        fn flip(ref world: IWorldDispatcher, x: u32, y: u32) {
            assert!(x < X_BOUND, "X is out of bounds");
            assert!(y < Y_BOUND, "Y is out of bounds");

            let player = get_caller_address();
            let hash = poseidon_hash_span(array![x.into(), y.into()].span());
            let tile = world.entity_lobotomized(TILE_MODEL_SELECTOR, hash);

            assert!(tile == 0, "Tile already flipped");

            let powerup = get_random_powerup(hash);
            let packed_data = pack_flipped_data(player.into(), powerup);

            world
                .set_entity_lobotomized(
                    TILE_MODEL_SELECTOR, array![x.into(), y.into()].span(), hash, packed_data
                );
        }

        // Bots can unflip any tiles, but we randomly chose the tile to flip.
        fn flop(ref world: IWorldDispatcher) {
            let evil_address = get_caller_address();
            let nonce = get_tx_info().nonce;

            let hash: u256 = poseidon_hash_span(array![evil_address.into(), nonce.into()].into())
                .into();

            let x: u32 = (hash % X_BOUND.into()).try_into().unwrap();
            let y: u32 = ((hash / Y_BOUND.into()) % Y_BOUND.into()).try_into().unwrap();

            let entity_hash = poseidon_hash_span(array![x.into(), y.into()].span());
            let tile = world.entity_lobotomized(TILE_MODEL_SELECTOR, entity_hash);

            // Check if the tile has a powerup
            let (_, powerup) = unpack_flipped_data(tile);
            if powerup == PowerUp::None {
                world
                    .set_entity_lobotomized(
                        TILE_MODEL_SELECTOR, array![x.into(), y.into()].span(), entity_hash, 0
                    );
            }
        }
    }
}
