//OTW
// otw ->  token module contract


module token ::  token { 


    //rules to be followed 
    // 1. the struct should have the drop 
    // 2. you use the witness in init() -/> so that you generate one treasury cap 



    //coin::create_currency()-> treasuryCap<TOKEN> , metadata
    //eg : deploy -> i get the treasury_cap ->sender()->initiates the tx
    //initialised the coin type 
    use std::ascii;
    use sui::coin;
    use sui::url;
    use sui::vec_set::VecSet;
    use sui::vec_set;
    

    const TOKEN_SUPPLY:u64 = 1000000000000000000; 


     //error codes :
     const E_NOT_OWNER_ADMIN: u64 = 1;
    public struct TOKEN has drop {}


     // witness object 
     public struct Witness has drop {}

     // adminRegistry object 
     public struct AdminRegistry has key {
        id : UID,
        owner_address : address,
        admin_address  : VecSet<address>        
        
   }




     // ownercap object 
     public struct OwnerCap has key, store {
         id: UID
     }    

   // init the treasury 
   public struct Treasury has key {
        id : UID,
        treasury__wal_address:address 
   }

    // visibility criteria's -> public, private , entry -> can be called via only the tx's 

   // init () -> evm's constructor ()
    // private fun()
   fun init(witness: TOKEN ,ctx : &mut TxContext ) {

        let icon_url = ascii::string(b"https://unsplash.com/s/photos/random-objects");

            // 'std::option::Option<sui::url::Url>
        let (mut treasury_cap , metadata) = coin::create_currency(witness, 9, b"TOKEN", b"TOKEN", b"something a random legit token", option::some(url::new_unsafe(icon_url)), ctx);



          let sender = tx_context::sender(ctx);
          let treas_address = @0xee571f26d4a51d32601e318dbaacd7f1250ed20915582ae0037d8b02e562fe78;
          // initialis the TReasury obj
          let treasury = Treasury {
               id : object::new(ctx),
               treasury__wal_address : treas_address
          };

          let owner_cap = OwnerCap {
               id : object::new(ctx),
          };


          let admin_registry = AdminRegistry { 
               id : object::new(ctx),
               owner_address : sender ,
               admin_address : vec_set::empty<address>()
          };


          // vec![] -> [1,1,2,3] -> uniques items 

          // vec_set -> [1,2,3,4, 1 ] ; 

          //mint() // mint () in the init ratther it having a separate fun
          // OTW here and this OTW can't be replicated after the module is deployed as well
          coin::mint_and_transfer(&mut treasury_cap, TOKEN_SUPPLY, treas_address, ctx);


          transfer::public_transfer(treasury_cap, sender); // tranfserring the treasury_Cap to the sender

          // freeze the metadata 
          transfer::public_freeze_object(metadata);
          transfer::share_object(treasury);
          
          transfer::public_transfer(owner_cap, sender); // tranfserring the treasury_Cap to the sender
          transfer::share_object(admin_registry);
    
   }



     fun gen_witness(): Witness {
          Witness{}
     }

     fun add_admin (
          admin_registry : &mut AdminRegistry,
          _witness : Witness ,
          admin_to_add : address,

     ) { 
          vec_set::insert(&mut admin_registry.admin_address , admin_to_add); //admin is added 
          // event emitters
          //dropped here 
     }

     entry fun called_by_two_entity(
          admin_registry : &mut AdminRegistry, 
          admin_address_to_add : address,
          ctx : &TxContext

     ) { 

          let sender =  tx_context::sender(ctx); // the one who is calling this fucntion
          //assert statement -> 
          assert!(vec_set::contains(&admin_registry.admin_address, &sender)||admin_registry.owner_address == sender,E_NOT_OWNER_ADMIN);  //checking is good
          //assert whether the admin is already added 
          let witness = gen_witness();
          add_admin( admin_registry ,witness,admin_address_to_add);
     }


//upgradability 


entry fun migrate () {
     
}


}

