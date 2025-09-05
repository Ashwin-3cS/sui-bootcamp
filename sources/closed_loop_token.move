module token::token { 

    use std::ascii;
    use sui::coin::{Self, TreasuryCap};
    use sui::token::{Self, Token};
    use sui::url;

    // Constants
    const SERVICE_PRICE: u64 = 10; // 10 tokens per service
    const E_INSUFFICIENT_TOKENS: u64 = 1; // gift which is going to be of 10tokens -

    // OTW for closed-loop token
    public struct TOKEN has drop {}

    // Simple rule for spending at our service
    public struct ServiceRule has drop {}

    // Gift that users get when spending tokens
    public struct Gift has key, store {
        id: UID,
        message: vector<u8>,
    }

    fun init(witness: TOKEN, ctx: &mut TxContext) {
        let icon_url = ascii::string(b"https://example.com/token.png");

        let (mut treasury_cap, coin_metadata) = coin::create_currency(
            witness, 
            9, 
            b"TOKEN", 
            b"Tutorial Token", 
            b"A simple closed-loop token for tutorial", 
            option::some(url::new_unsafe(icon_url)), 
            ctx
        );

        let (mut policy, policy_cap) = token::new_policy(&treasury_cap, ctx);

        token::add_rule_for_action<TOKEN, ServiceRule>(
            &mut policy,
            &policy_cap,
            token::spend_action(),
            ctx,
        );


        let sender = tx_context::sender(ctx);

        // Added token minting for deployer
        let initial_tokens = token::mint(&mut treasury_cap, 1000, ctx);
        let transfer_req = token::transfer(initial_tokens, sender, ctx);//its in pending state
        token::confirm_with_treasury_cap(&mut treasury_cap, transfer_req, ctx);//the tokens are transferred to the recipient

        token::share_policy(policy);
        transfer::public_freeze_object(coin_metadata);
        transfer::public_transfer(treasury_cap, sender);
        transfer::public_transfer(policy_cap, sender);
    }

    // Users can spend tokens to buy gifts at our service
    // Returns ActionRequest for owner to process later
    entry fun buy_gift(
        treasury_cap : &mut TreasuryCap<TOKEN>,
        token: Token<TOKEN>, 
        ctx: &mut TxContext
    ){
        // Check user has enough tokens
        assert!(token::value(&token) >= SERVICE_PRICE, E_INSUFFICIENT_TOKENS);

        // Create the gift
        let gift = Gift { 
            id: object::new(ctx),
            message: b"Thank you for using our service!",
        };

        // Lock the tokens in escrow (not spent yet!)
        let mut req = token::spend(token, ctx); // here the actual token is consumed and stored in the spent_balance as a field right -> returns a action req to be performed on the token 


        // Add approval - required by our policy
        token::add_approval(ServiceRule {}, &mut req, ctx);// what this does is the rule is applied as a policy to the token it tells that the approval is done


        token::confirm_with_treasury_cap(treasury_cap, req, ctx); // what this does burning the tokens thats spent by the user 

        // User gets the gift immediately
        transfer::public_transfer(gift, tx_context::sender(ctx));
        
    }

}
    