use starknet::{ContractAddress, ClassHash};
use dojo::world::IWorldDispatcher;

#[dojo::model]
#[derive(Copy, Drop, Serde)]
struct ERC20AllowanceModel {
    #[key]
    token: ContractAddress,
    #[key]
    owner: ContractAddress,
    #[key]
    spender: ContractAddress,
    amount: u256,
}

#[dojo::model]
#[derive(Copy, Drop, Serde)]
struct ERC20BalanceModel {
    #[key]
    token: ContractAddress,
    #[key]
    account: ContractAddress,
    amount: u256,
}

#[dojo::model]
#[derive(Copy, Drop, Serde)]
struct ERC20BridgeableModel {
    #[key]
    token: ContractAddress,
    l2_bridge_address: ContractAddress
}

#[dojo::model]
#[derive(Drop, Serde)]
struct ERC20MetadataModel {
    #[key]
    token: ContractAddress,
    name: ByteArray,
    symbol: ByteArray,
    decimals: u8,
    total_supply: u256,
}


#[starknet::interface]
trait IERC20BridgeablePreset<TState> {
    // IWorldProvider
    fn world(self: @TState,) -> IWorldDispatcher;

    // IUpgradeable
    fn upgrade(ref self: TState, new_class_hash: ClassHash);

    // IERC20Metadata
    fn decimals(self: @TState,) -> u8;
    fn name(self: @TState,) -> ByteArray;
    fn symbol(self: @TState,) -> ByteArray;

    // IERC20MetadataTotalSupply
    fn total_supply(self: @TState,) -> u256;

    // IERC20MetadataTotalSupplyCamel
    fn totalSupply(self: @TState,) -> u256;

    // IERC20Balance
    fn balance_of(self: @TState, account: ContractAddress) -> u256;
    fn transfer(ref self: TState, recipient: ContractAddress, amount: u256) -> bool;
    fn transfer_from(
        ref self: TState, sender: ContractAddress, recipient: ContractAddress, amount: u256
    ) -> bool;

    // IERC20BalanceCamel
    fn balanceOf(self: @TState, account: ContractAddress) -> u256;
    fn transferFrom(
        ref self: TState, sender: ContractAddress, recipient: ContractAddress, amount: u256
    ) -> bool;

    // IERC20Allowance
    fn allowance(self: @TState, owner: ContractAddress, spender: ContractAddress) -> u256;
    fn approve(ref self: TState, spender: ContractAddress, amount: u256) -> bool;

    // IERC20Bridgeable
    fn burn(ref self: TState, account: ContractAddress, amount: u256);
    fn l2_bridge_address(self: @TState,) -> ContractAddress;
    fn mint(ref self: TState, recipient: ContractAddress, amount: u256);

    // WITHOUT INTERFACE !!!
    fn initializer(
        ref self: TState,
        name: ByteArray,
        symbol: ByteArray,
        initial_supply: u256,
        recipient: ContractAddress,
        l2_bridge_address: ContractAddress
    );
    fn dojo_resource(self: @TState,) -> felt252;
}


///
/// Interface required to remove compiler warnings and future
/// deprecation.
///
#[starknet::interface]
trait IERC20BridgeableInitializer<TState> {
    fn initializer(ref self: TState, name: ByteArray, symbol: ByteArray);
}

#[starknet::interface]
trait IFlip<TState> {
    fn balance(self: @TState, account: ContractAddress) -> u256;
    fn mint_from(ref self: TState, recipient: ContractAddress, amount: u256);
    fn burn_from(ref self: TState, account: ContractAddress, amount: u256);
}

#[dojo::contract]
mod Flip {
    use core::num::traits::Bounded;
    use starknet::ContractAddress;
    use starknet::{get_caller_address, get_contract_address};
    use zeroable::Zeroable;

    use origami_token::components::security::initializable::initializable_component;

    use origami_token::components::token::erc20::erc20_metadata::erc20_metadata_component;
    use origami_token::components::token::erc20::erc20_balance::erc20_balance_component;
    use origami_token::components::token::erc20::erc20_allowance::erc20_allowance_component;
    use origami_token::components::token::erc20::erc20_mintable::erc20_mintable_component;
    use origami_token::components::token::erc20::erc20_burnable::erc20_burnable_component;
    use origami_token::components::token::erc20::erc20_bridgeable::erc20_bridgeable_component;

    component!(path: initializable_component, storage: initializable, event: InitializableEvent);

    component!(path: erc20_metadata_component, storage: erc20_metadata, event: ERC20MetadataEvent);
    component!(path: erc20_balance_component, storage: erc20_balance, event: ERC20BalanceEvent);
    component!(
        path: erc20_allowance_component, storage: erc20_allowance, event: ERC20AllowanceEvent
    );
    component!(path: erc20_mintable_component, storage: erc20_mintable, event: ERC20MintableEvent);
    component!(path: erc20_burnable_component, storage: erc20_burnable, event: ERC20BurnableEvent);
    component!(
        path: erc20_bridgeable_component, storage: erc20_bridgeable, event: ERC20BridgeableEvent
    );

    #[storage]
    struct Storage {
        #[substorage(v0)]
        initializable: initializable_component::Storage,
        #[substorage(v0)]
        erc20_metadata: erc20_metadata_component::Storage,
        #[substorage(v0)]
        erc20_balance: erc20_balance_component::Storage,
        #[substorage(v0)]
        erc20_allowance: erc20_allowance_component::Storage,
        #[substorage(v0)]
        erc20_mintable: erc20_mintable_component::Storage,
        #[substorage(v0)]
        erc20_burnable: erc20_burnable_component::Storage,
        #[substorage(v0)]
        erc20_bridgeable: erc20_bridgeable_component::Storage,
    }

    #[event]
    #[derive(Copy, Drop, starknet::Event)]
    enum Event {
        #[flat]
        InitializableEvent: initializable_component::Event,
        #[flat]
        ERC20MetadataEvent: erc20_metadata_component::Event,
        #[flat]
        ERC20BalanceEvent: erc20_balance_component::Event,
        #[flat]
        ERC20AllowanceEvent: erc20_allowance_component::Event,
        #[flat]
        ERC20MintableEvent: erc20_mintable_component::Event,
        #[flat]
        ERC20BurnableEvent: erc20_burnable_component::Event,
        #[flat]
        ERC20BridgeableEvent: erc20_bridgeable_component::Event,
    }

    mod Errors {
        const CALLER_IS_NOT_OWNER: felt252 = 'ERC20: caller is not owner';
    }


    impl InitializableImpl = initializable_component::InitializableImpl<ContractState>;

    #[abi(embed_v0)]
    impl ERC20MetadataImpl =
        erc20_metadata_component::ERC20MetadataImpl<ContractState>;

    #[abi(embed_v0)]
    impl ERC20MetadataTotalSupplyImpl =
        erc20_metadata_component::ERC20MetadataTotalSupplyImpl<ContractState>;

    #[abi(embed_v0)]
    impl ERC20MetadataTotalSupplyCamelImpl =
        erc20_metadata_component::ERC20MetadataTotalSupplyCamelImpl<ContractState>;

    #[abi(embed_v0)]
    impl ERC20BalanceImpl =
        erc20_balance_component::ERC20BalanceImpl<ContractState>;

    #[abi(embed_v0)]
    impl ERC20BalanceCamelImpl =
        erc20_balance_component::ERC20BalanceCamelImpl<ContractState>;

    #[abi(embed_v0)]
    impl ERC20AllowanceImpl =
        erc20_allowance_component::ERC20AllowanceImpl<ContractState>;

    #[abi(embed_v0)]
    impl ERC20BridgeableImpl =
        erc20_bridgeable_component::ERC20BridgeableImpl<ContractState>;


    //
    // Internal Impls
    //

    impl InitializableInternalImpl = initializable_component::InternalImpl<ContractState>;
    impl ERC20MetadataInternalImpl = erc20_metadata_component::InternalImpl<ContractState>;
    impl ERC20BalanceInternalImpl = erc20_balance_component::InternalImpl<ContractState>;
    impl ERC20AllowanceInternalImpl = erc20_allowance_component::InternalImpl<ContractState>;
    impl ERC20MintableInternalImpl = erc20_mintable_component::InternalImpl<ContractState>;
    impl ERC20BurnableInternalImpl = erc20_burnable_component::InternalImpl<ContractState>;
    impl ERC20BridgeableInternalImpl = erc20_bridgeable_component::InternalImpl<ContractState>;

    //
    // Initializer
    //

    fn dojo_init(ref self: ContractState) {
        self.erc20_metadata.initialize("FLIP", "FLIP", 18);

        self.initializable.initialize();
    }

    #[abi(embed_v0)]
    impl ERC20InitializerImpl of super::IERC20BridgeableInitializer<ContractState> {
        fn initializer(ref self: ContractState, name: ByteArray, symbol: ByteArray) {
            // assert(
            //     self.world().is_owner(self.selector(), get_caller_address()),
            //     Errors::CALLER_IS_NOT_OWNER
            // );

            self.erc20_metadata.initialize(name, symbol, 18);

            self.initializable.initialize();
        }
    }

    #[abi(embed_v0)]
    impl Flip of super::IFlip<ContractState> {
        fn balance(self: @ContractState, account: ContractAddress) -> u256 {
            self.erc20_balance.balance_of(account)
        }

        fn mint_from(ref self: ContractState, recipient: ContractAddress, amount: u256) {
            self.erc20_mintable.mint(recipient, amount);
        }

        fn burn_from(ref self: ContractState, account: ContractAddress, amount: u256) {
            self.erc20_burnable.burn(account, amount);
        }
    }
}