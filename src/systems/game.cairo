use starknet::ContractAddress;
use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};

#[dojo::interface]
trait IGameManager {
    fn lock_game(ref self: IWorldDispatcher);
    fn unlock_game(ref self: IWorldDispatcher);
}

#[dojo::contract]
mod game_manager {
    use flippyflop::constants::{GAME_MODEL_SELECTOR, GAME_ID};
    use flippyflop::models::Game;
    use super::{IGameManager};
    use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};

    #[abi(embed_v0)]
    impl GameManagerImpl of IGameManager<ContractState> {
        fn lock_game(ref self: IWorldDispatcher) {
            assert(world.is_caller_world_owner(), 'Caller is not world owner');
            
            set!(world, Game { id: GAME_ID, is_locked: true });
        }

        fn unlock_game(ref self: IWorldDispatcher) {
            assert(world.is_caller_world_owner(), 'Caller is not world owner');
            
            set!(world, Game { id: GAME_ID, is_locked: false });
        }
    }
}