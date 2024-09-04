#[dojo::interface]
trait IGameManager {
    fn lock_game(ref world: IWorldDispatcher);
    fn unlock_game(ref world: IWorldDispatcher);
}

#[dojo::contract]
mod game {
    use flippyflop::constants::{GAME_ID};
    use flippyflop::models::Game;
    use super::{IGameManager};
    use starknet::{get_caller_address};

    #[abi(embed_v0)]
    impl GameManagerImpl of IGameManager<ContractState> {
        fn lock_game(ref world: IWorldDispatcher) {
            assert(world.is_owner(0, get_caller_address()), 'Caller is not world owner');
            
            set!(world, (Game { id: GAME_ID, is_locked: true }));
        }

        fn unlock_game(ref world: IWorldDispatcher) {
            assert(world.is_owner(0, get_caller_address()), 'Caller is not world owner');
            
            set!(world, (Game { id: GAME_ID, is_locked: false }));
        }
    }
}