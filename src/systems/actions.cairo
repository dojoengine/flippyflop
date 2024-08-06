// define the interface
#[dojo::interface]
trait IActions {
    fn flip(ref world: IWorldDispatcher, x: u32, y: u32);
    fn flop(ref world: IWorldDispatcher);
}

// dojo decorator
#[dojo::contract]
mod actions {
    use super::{IActions};
    use starknet::{ContractAddress, get_caller_address, info::get_tx_info};
    use flippyflop::models::Tile;
    use core::poseidon::poseidon_hash_span;

    #[abi(embed_v0)]
    impl ActionsImpl of IActions<ContractState> {
        // Humans can only flip unflipped tiles, but they can chose their tile to unflip.
        fn flip(ref world: IWorldDispatcher, x: u32, y: u32) {
            let player = get_caller_address();
            let tile = get!(world, (x, y), Tile);

            assert!(tile.flipped == 0, "Tile already flipped");

            set!(world, (Tile { x, y, flipped: player.into() }));
        }

        // Bots can unflip any tiles, but we randomly chose the tile to flip.
        fn flop(ref world: IWorldDispatcher) {
            let evil_address = get_caller_address();
            let nonce = get_tx_info().nonce;

            let hash: u256 = poseidon_hash_span(array![evil_address.into(), nonce.into()].into())
                .into();

            let x: u32 = (hash % 100).try_into().unwrap();
            let y: u32 = ((hash / 100) % 100).try_into().unwrap();

            set!(world, (Tile { x, y, flipped: 0 }));
        }
    }
}
