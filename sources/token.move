module token::token { 

    use std::ascii;
    use std::option;
    use sui::coin::{Self, Coin, TreasuryCap, CoinMetadata};
    use sui::url;
    use sui::object::{Self, UID};
    use sui::tx_context::{Self, TxContext};
    use sui::transfer;
    use sui::vec_set::{Self, VecSet};

    const TOKEN_SUPPLY: u64 = 1000000000000000000; 
    const E_NOT_OWNER_ADMIN: u64 = 1;
    const E_WRONG_VERSION: u64 = 2;
    const E_ALREADY_MIGRATED: u64 = 3;
    
    const CURRENT_VERSION: u64 = 1; //2  1 -> 2 
    const MAX_ADMINS_V1: u32 = 2; 
    const MAX_ADMINS_V2: u32 = 4;

    public struct TOKEN has drop {}

    public struct Witness has drop {}

    public struct AdminRegistry has key {
        id: UID,
        version: u64,                    
        owner_address: address,
        admin_address: VecSet<address>,
        max_admins: u32,                 
    }

    public struct Treasury has key {
        id: UID,
        version: u64,                    
        treasury_wal_address: address 
    }

    public struct OwnerCap has key, store {
        id: UID,
        version: u64,
    }

    fun init(witness: TOKEN, ctx: &mut TxContext) {
        let icon_url = ascii::string(b"https://unsplash.com/s/photos/random-objects");

        let (mut treasury_cap, metadata) = coin::create_currency<TOKEN>(
            witness, 
            9, 
            b"TOKEN", 
            b"TOKEN", 
            b"something a random legit token", 
            option::some(url::new_unsafe(icon_url)), 
            ctx
        );

        let sender = tx_context::sender(ctx);
        let treas_address = @0xee571f26d4a51d32601e318dbaacd7f1250ed20915582ae0037d8b02e562fe78;
        
        let treasury = Treasury {
            id: object::new(ctx),
            version: CURRENT_VERSION,
            treasury_wal_address: treas_address
        };

        let owner_cap = OwnerCap {
            id: object::new(ctx),
            version: CURRENT_VERSION,
        };

        let admin_registry = AdminRegistry { 
            id: object::new(ctx),
            version: CURRENT_VERSION,
            owner_address: sender,
            admin_address: vec_set::empty<address>(),
            max_admins: MAX_ADMINS_V1,
        };

        coin::mint_and_transfer(&mut treasury_cap, TOKEN_SUPPLY, treas_address, ctx);
        transfer::public_transfer(treasury_cap, sender);
        transfer::public_freeze_object(metadata);
        transfer::share_object(treasury);
        transfer::public_transfer(owner_cap, sender);
        transfer::share_object(admin_registry);
    }

    

    entry fun migrate(
        admin_registry: &mut AdminRegistry,
        treasury: &mut Treasury, 
        ctx: &TxContext //
    ) {
        let sender = tx_context::sender(ctx);
        
        assert!(admin_registry.owner_address == sender, E_NOT_OWNER_ADMIN);
        
        assert!(admin_registry.version == 1, E_ALREADY_MIGRATED);
        
        admin_registry.version = 2;
        admin_registry.max_admins = MAX_ADMINS_V2; 
        
        treasury.version = 2;
    }

    fun gen_witness(): Witness {
        Witness {}
    }

    fun add_admin(
        admin_registry: &mut AdminRegistry,
        _witness: Witness,
        admin_to_add: address,
    ) {
        assert!(
            vec_set::size(&admin_registry.admin_address) < (admin_registry.max_admins as u64), 
            E_NOT_OWNER_ADMIN
        );
        
        vec_set::insert(&mut admin_registry.admin_address, admin_to_add);
    }

    entry fun called_by_two_entity(
        admin_registry: &mut AdminRegistry, 
        admin_address_to_add: address,
        ctx: &TxContext
    ) {
        let sender = tx_context::sender(ctx);
        
        assert!(
            vec_set::contains(&admin_registry.admin_address, &sender) || 
            admin_registry.owner_address == sender, 
            E_NOT_OWNER_ADMIN
        );
        
        let witness = gen_witness();
        add_admin(admin_registry, witness, admin_address_to_add);
    }
}