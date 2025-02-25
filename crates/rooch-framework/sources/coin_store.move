// Copyright (c) RoochNetwork
// SPDX-License-Identifier: Apache-2.0

module rooch_framework::coin_store {

    use std::string;
    use moveos_std::object::{ObjectID};
    use moveos_std::context::{Self, Context};
    use moveos_std::type_info;
    use moveos_std::object::{Self, Object};
    use moveos_std::event;
    use rooch_framework::coin::{Self, Coin};

    friend rooch_framework::account_coin_store;

    // Error codes

    /// The CoinStore is not found in the global object store
    const ErrorCoinStoreNotFound: u64 = 1;

    /// CoinStore is frozen. Coins cannot be deposited or withdrawn
    const ErrorCoinStoreIsFrozen: u64 = 2;

    /// The CoinType parameter and CoinType in CoinStore do not match
    const ErrorCoinTypeAndStoreMismatch: u64 = 3;

    /// Not enough balance to withdraw from CoinStore
    const ErrorInSufficientBalance: u64 = 4;

    /// Transfer is not supported for CoinStore
    const ErrorCoinStoreTransferNotSupported: u64 = 5;

    
    /// The Balance resource that stores the balance of a specific coin type.
    struct Balance has store {
        value: u256,
    }

    /// A holder of a specific coin types.
    /// These are kept in a single resource to ensure locality of data.
    struct CoinStore<phantom CoinType: key> has key {
        coin_type: string::String,
        balance: Balance,
        frozen: bool,
    }

    /// Event emitted when a coin store is created.
    struct CreateEvent has drop, store {
        /// The id of the coin store that was created
        coin_store_id: ObjectID,
        /// The type of the coin that was created
        coin_type: string::String,
    }

    /// Event emitted when some amount of a coin is deposited into a coin store.
    struct DepositEvent has drop, store {
        /// The id of the coin store that was deposited to
        coin_store_id: ObjectID,
        /// The type of the coin that was sent
        coin_type: string::String,
        amount: u256,
    }

    /// Event emitted when some amount of a coin is withdrawn from a coin store.
    struct WithdrawEvent has drop, store {
        /// The id of the coin store that was withdrawn from
        coin_store_id: ObjectID,
        /// The type of the coin that was sent
        coin_type: string::String,
        amount: u256,
    }

    /// Event emitted when a coin store is frozen or unfrozen.
    struct FreezeEvent has drop, store {
        /// The id of the coin store that was frozen or unfrozen
        coin_store_id: ObjectID,
        /// The type of the coin that was frozen or unfrozen
        coin_type: string::String,
        frozen: bool,
    }

    /// Event emitted when a coin store is removed.
    struct RemoveEvent has drop, store {
        /// The id of the coin store that was removed
        coin_store_id: ObjectID,
        /// The type of the coin that was removed
        coin_type: string::String,
    }

    //
    // Public functions
    //

    /// Create a new CoinStore Object for `CoinType` and return the Object
    /// Anyone can create a CoinStore Object for public Coin<CoinType>, the `CoinType` must has `key` and `store` ability
    public fun create_coin_store<CoinType: key + store>(ctx: &mut Context): Object<CoinStore<CoinType>>{
        create_coin_store_internal<CoinType>(ctx) 
    }

    #[private_generics(CoinType)]
    /// This function is for the `CoinType` module to extend
    public fun create_coin_store_extend<CoinType: key>(ctx: &mut Context): Object<CoinStore<CoinType>> {
        create_coin_store_internal<CoinType>(ctx)
    }
    
    /// Remove the CoinStore Object, return the Coin<T> in balance 
    public fun remove_coin_store<CoinType: key>(coin_store_object: Object<CoinStore<CoinType>>) : Coin<CoinType> {
        let coin_store_id = object::id(&coin_store_object);
        let coin_store = object::remove(coin_store_object);
        
        let CoinStore{coin_type, balance, frozen} = coin_store;
        // Cannot remove a frozen CoinStore, because if we allow this, the frozen is meaningless
        assert!(!frozen, ErrorCoinStoreIsFrozen);
        let Balance{value} = balance;
        let coin = coin::pack<CoinType>(value);

        event::emit(RemoveEvent{
            coin_store_id,
            coin_type,
        });

        coin
    }

    public fun coin_type<CoinType: key>(coin_store_obj: &Object<CoinStore<CoinType>>): string::String {
        object::borrow(coin_store_obj).coin_type
    }

    public fun balance<CoinType: key>(coin_store_obj: &Object<CoinStore<CoinType>>): u256 {
        object::borrow(coin_store_obj).balance.value
    }

    public fun is_frozen<CoinType: key>(coin_store_obj: &Object<CoinStore<CoinType>>): bool {
        object::borrow(coin_store_obj).frozen
    }

    /// Withdraw `amount` Coin<CoinType> from the balance of the passed-in `coin_store`
    /// This function requires the `CoinType` must has `key` and `store` ability
    public fun withdraw<CoinType: key + store>(coin_store_obj: &mut Object<CoinStore<CoinType>>, amount: u256) : Coin<CoinType> {
        withdraw_internal(coin_store_obj, amount)
    }

    #[private_generics(CoinType)]
    /// Withdraw `amount` Coin<CoinType> from the balance of the passed-in `coin_store`
    /// This function is for the `CoinType` module to extend
    public fun withdraw_extend<CoinType: key>(coin_store_obj: &mut Object<CoinStore<CoinType>>, amount: u256) : Coin<CoinType> {
        withdraw_internal(coin_store_obj, amount)
    }

    /// Deposit `amount` Coin<CoinType> to the balance of the passed-in `coin_store`
    /// This function requires the `CoinType` must has `key` and `store` ability
    public fun deposit<CoinType: key + store>(coin_store_obj: &mut Object<CoinStore<CoinType>>, coin: Coin<CoinType>) {
        deposit_internal(coin_store_obj, coin)
    }

    #[private_generics(CoinType)]
    /// Deposit `amount` Coin<CoinType> to the balance of the passed-in `coin_store`
    /// This function is for the `CoinType` module to extend
    public fun deposit_extend<CoinType: key>(coin_store_obj: &mut Object<CoinStore<CoinType>>, coin: Coin<CoinType>) {
        deposit_internal(coin_store_obj, coin)
    }

    // We do not allow to transfer a CoinStore to another account, this function will abort directly.
    // Because we need to ensure one Account only has one CoinStore for one CoinType
    // If you want tranfer a CoinStore to another account, you can call `coin_store::remove(Object<CoinStore<CoinType>>)` and deposit the Coin<CoinType> to another account.
    public fun transfer<CoinType: key>(_coin_store_obj: Object<CoinStore<CoinType>>, _owner: address){
        abort ErrorCoinStoreTransferNotSupported
    }

    #[private_generics(CoinType)]
    /// Borrow a mut CoinStore Object by the coin store id
    /// This function is for the `CoinType` module to extend
    public fun borrow_mut_coin_store_extend<CoinType: key>(ctx: &mut Context, object_id: ObjectID): &mut Object<CoinStore<CoinType>>{
        borrow_mut_coin_store_internal(ctx, object_id)
    }

    #[private_generics(CoinType)]
    /// Freeze or Unfreeze a CoinStore to prevent withdraw and desposit
    /// This function is for he `CoinType` module to extend,
    /// Only the `CoinType` module can freeze or unfreeze a CoinStore by the coin store id
    public fun freeze_coin_store_extend<CoinType: key>(
        coin_store_obj: &mut Object<CoinStore<CoinType>>,
        frozen: bool,
    ) {
        let coin_store_id = object::id(coin_store_obj);
        let coin_store = object::borrow_mut(coin_store_obj);
        let coin_type = coin_store.coin_type;
        coin_store.frozen = frozen;
        event::emit(FreezeEvent{
            coin_store_id,
            coin_type,
            frozen,
        });
    }

    // Internal functions

    public(friend) fun create_coin_store_internal<CoinType: key>(ctx: &mut Context): Object<CoinStore<CoinType>>{
        coin::check_coin_info_registered<CoinType>(ctx);
        let coin_type = type_info::type_name<CoinType>();
        let coin_store_obj = context::new_object(ctx, CoinStore<CoinType>{
            coin_type,
            balance: Balance { value: 0 },
            frozen: false,
        });
        event::emit(CreateEvent{
            coin_store_id: object::id(&coin_store_obj),
            coin_type,
        });
        coin_store_obj
    }

    public(friend) fun create_account_coin_store<CoinType: key>(ctx: &mut Context, account: address): ObjectID{
        coin::check_coin_info_registered<CoinType>(ctx);
        let coin_type = type_info::type_name<CoinType>();
        let coin_store_obj = context::new_account_named_object(ctx, account, CoinStore<CoinType>{
            coin_type,
            balance: Balance { value: 0 },
            frozen: false,
        });
        let coin_store_id = object::id(&coin_store_obj);
        object::transfer_extend(coin_store_obj, account);
        event::emit(CreateEvent{
            coin_store_id,
            coin_type,
        });
        coin_store_id
    }

    public(friend) fun borrow_mut_coin_store_internal<CoinType: key>(ctx: &mut Context, object_id: ObjectID): &mut Object<CoinStore<CoinType>>{
        assert!(context::exists_object<CoinStore<CoinType>>(ctx, object_id), ErrorCoinStoreNotFound);
        context::borrow_mut_object_extend<CoinStore<CoinType>>(ctx, object_id)
    }

    fun check_coin_store_not_frozen<CoinType: key>(coin_store: &CoinStore<CoinType>) {
        assert!(!coin_store.frozen,ErrorCoinStoreIsFrozen);
    }

    /// Extracts `amount` Coin from the balance of the passed-in `coin_store`
    fun extract_from_balance<CoinType: key>(coin_store: &mut CoinStore<CoinType>, amount: u256): Coin<CoinType> {
        assert!(coin_store.balance.value >= amount, ErrorInSufficientBalance);
        coin_store.balance.value = coin_store.balance.value - amount;
        coin::pack<CoinType>(amount)
    }

    /// "Merges" the given coins to the balance of the passed-in `coin_store`.
    fun merge_to_balance<CoinType: key>(coin_store: &mut CoinStore<CoinType>, source_coin: Coin<CoinType>) {
        let value = coin::unpack(source_coin);
        coin_store.balance.value = coin_store.balance.value + value;
    }

    public(friend) fun withdraw_internal<CoinType: key>(coin_store_obj: &mut Object<CoinStore<CoinType>>, amount: u256) : Coin<CoinType> {
        let object_id = object::id(coin_store_obj);
        let coin_store = object::borrow_mut(coin_store_obj);
        check_coin_store_not_frozen(coin_store);
        let coin = extract_from_balance<CoinType>(coin_store, amount);
        event::emit(WithdrawEvent{
            coin_store_id: object_id,
            coin_type: coin_store.coin_type,
            amount: amount,
        });
        coin
    }

    /// Deposit `amount` Coin<CoinType> to the balance of the passed-in `coin_store`
    public(friend) fun deposit_internal<CoinType: key>(coin_store_obj: &mut Object<CoinStore<CoinType>>, coin: Coin<CoinType>) {
        let object_id = object::id(coin_store_obj);
        let coin_store = object::borrow_mut(coin_store_obj);
        check_coin_store_not_frozen(coin_store);
        let amount = coin::value(&coin);
        merge_to_balance<CoinType>(coin_store, coin);
        event::emit(DepositEvent{
            coin_store_id: object_id,
            coin_type: coin_store.coin_type,
            amount,
        });
    }
}