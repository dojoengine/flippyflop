// define the interface
#[dojo::interface]
trait IActions {
    fn flip(ref world: IWorldDispatcher, x: u32, y: u32);
    fn flop(ref world: IWorldDispatcher);
    fn claim(ref world: IWorldDispatcher);
}

// dojo decorator
#[dojo::contract]
mod actions {
    use super::{IActions};
    use starknet::{ContractAddress, get_caller_address, info::get_tx_info};
    use flippyflop::models::{PowerUp, PowerUpTrait, Game};
    use core::poseidon::poseidon_hash_span;
    use dojo::model::{FieldLayout, Layout};
    use flippyflop::tokens::flip::{IFlip, IFlipDispatcher, IFlipDispatcherTrait};
    use flippyflop::constants::{GAME_ID, ADDRESS_MASK, POWERUP_MASK, POWERUP_DATA_MASK, X_BOUND, Y_BOUND, TILE_MODEL_SELECTOR};
    use flippyflop::packing::{pack_flipped_data, unpack_flipped_data};

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

    fn flip_token(world: IWorldDispatcher) -> IFlipDispatcher {
        let (class_hash, contract_address) =
            match world.resource(selector_from_tag!("flippyflop-FLIP")) {
            dojo::world::Resource::Contract((
                class_hash, contract_address
            )) => (class_hash, contract_address),
            _ => (0.try_into().unwrap(), 0.try_into().unwrap())
        };

        if class_hash.is_zero() || contract_address.is_zero() {
            panic!("Invalid FLIP token resource!");
        }

        IFlipDispatcher { contract_address }
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

        fn claim(ref world: IWorldDispatcher) {
            // Game must be locked
            let game = get!(world, GAME_ID, Game);
            assert!(game.is_locked, "Game is not locked");

            let player = get_caller_address();
            let flip_token = flip_token(world);
            let mut total_tokens: u256 = 0;

            // Iterate through all tiles
            let mut x: u32 = 0;
            loop {
                if x >= X_BOUND {
                    break;
                }
                
                let mut y: u32 = 0;
                loop {
                    if y >= Y_BOUND {
                        break;
                    }

                    let entity_hash = poseidon_hash_span(array![x.into(), y.into()].span());
                    let tile = world.entity_lobotomized(TILE_MODEL_SELECTOR, entity_hash);

                    // Check if the tile is flipped and belongs to the player
                    let (tile_owner, powerup) = unpack_flipped_data(tile);
                    if tile_owner == player {
                        // Calculate base token amount (1 ETH in wei)
                        let mut tokens: u256 = 1000000000000000000;

                        // Apply powerup multiplier if any
                        if let PowerUp::Multiplier(multiplier) = powerup {
                            tokens *= multiplier.into();
                        }

                        total_tokens += tokens;
                    }

                    y += 1;
                };

                x += 1;
            };

            // Mint FLIP tokens to the player
            if total_tokens > 0 {
                flip_token.mint_from(player, total_tokens);
            }
        }
    }
}
