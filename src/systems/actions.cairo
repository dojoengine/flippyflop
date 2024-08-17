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

// dojo decorator
#[dojo::contract]
mod actions {
    use super::{IActions, TILE_MODEL_SELECTOR, TILE_FLIPPED_SELECTOR};
    use starknet::{ContractAddress, get_caller_address, info::get_tx_info};
    use flippyflop::models::Tile;
    use core::poseidon::poseidon_hash_span;
    use dojo::model::{FieldLayout, Layout};

    #[abi(embed_v0)]
    impl ActionsImpl of IActions<ContractState> {
        // Humans can only flip unflipped tiles, but they can chose their tile to unflip.
        fn flip(ref world: IWorldDispatcher, x: u32, y: u32) {
            let player = get_caller_address();
            let hash = poseidon_hash_span(array![x.into(), y.into()].span());
            let tile = world.entity_lobotomized(TILE_MODEL_SELECTOR, hash);

            assert!(tile == 0, "Tile already flipped");

            world
                .set_entity_lobotomized(
                    TILE_MODEL_SELECTOR, array![x.into(), y.into()].span(), hash, player.into()
                );
        }

        // Bots can unflip any tiles, but we randomly chose the tile to flip.
        fn flop(ref world: IWorldDispatcher) {
            let evil_address = get_caller_address();
            let nonce = get_tx_info().nonce;

            let hash: u256 = poseidon_hash_span(array![evil_address.into(), nonce.into()].into())
                .into();

            let x: u32 = (hash % 100).try_into().unwrap();
            let y: u32 = ((hash / 100) % 100).try_into().unwrap();

            let entity_hash = poseidon_hash_span(array![x.into(), y.into()].span());
            world.delete_entity_lobotomized(TILE_MODEL_SELECTOR, entity_hash);
        }
    }
}
