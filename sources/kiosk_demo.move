module kiosk_demo::kiosk_demo{
    use sui::kiosk::{Self, Kiosk, KioskOwnerCap, PurchaseCap};
   
    use sui::object::{Self, UID, ID};
    use sui::tx_context::{Self, TxContext};
    use sui::transfer::{Self};
    use sui::sui::{SUI};
    use sui::balance::{Self, Balance};
    use sui::coin::{Self, Coin};
    use sui::package;
    use sui::transfer_policy::{Self, TransferPolicy};
    use std::string::{utf8};
    use sui::display::{Self};
    use sui::clock::{Clock};
    use sui::table::{Self,Table};
    use kiosk_demo::royalty_rule::{Self};
    use kiosk_demo::time_rule::{Self};

    const PRICE: u64 = 10000;

    const EBalanceNtEnough: u64 = 0;

    struct Nft_fund has key{
        id: UID,
        balance: Balance<SUI>,
    }

    struct SaleList has key{
        id: UID,
        item_price_table: Table<ID, u64>,
    }
                                               
    struct Counter has store, key{
        id: UID,
        counter: u64,
    }

    struct KIOSK_DEMO has drop{}


    struct PaulNft has key, store {
        id: UID,
        name: vector<u8>,
        image_url: vector<u8>,
        tag: u64,
    }

    #[allow(unused_function)]
    fun init (witness: KIOSK_DEMO, ctx: &mut TxContext){

        let publisher = package::claim(witness, ctx);

        let (policy, cap) = transfer_policy::new<PaulNft>(&publisher, ctx);
        transfer::public_share_object(policy);
        transfer::public_transfer(cap, tx_context::sender(ctx));

        let keys = vector[
            utf8(b"name"),
            utf8(b"link"),
            utf8(b"image_url"),
            utf8(b"description"),
            utf8(b"project_url"),
            utf8(b"creator"),
        ];

        let values = vector[
            utf8(b"Paul"),
            utf8(b"https://drive.google.com/file/d/1iDc_JcnAkMbDdhMhJpg3GUIOOk8bigG4/view?usp=sharing"),
            utf8(b"https://drive.google.com/file/d/1iDc_JcnAkMbDdhMhJpg3GUIOOk8bigG4/view?usp=sharing"),
            utf8(b"A true Hero of the Sui ecosystem!"),
            utf8(b"https://drive.google.com/file/d/1iDc_JcnAkMbDdhMhJpg3GUIOOk8bigG4/view?usp=sharing"),
            utf8(b"Paul")
        ];

        let display = display::new_with_fields<PaulNft>(
            &publisher,
            keys,
            values,
            ctx,
        );
        display::update_version(&mut display);
        transfer::public_share_object(display);


        let counter = Counter{
            id: object::new(ctx),
            counter: 0
        };

        let sale_list = SaleList{
            id: object::new(ctx),
            item_price_table: table::new(ctx),
        };
        
        let nft_fund = Nft_fund{
            id: object::new(ctx),
            balance: balance::zero<SUI>(),
        };

        transfer::share_object(sale_list);
        transfer::public_transfer(publisher, tx_context::sender(ctx));
        transfer::share_object(nft_fund);
        transfer::public_share_object(counter);

    }

    public entry fun mint_nft(nft_fund: &mut Nft_fund, counter: &mut Counter, payment: Coin<SUI>, ctx: &mut TxContext){
        assert!(coin::value(&payment) == PRICE, EBalanceNtEnough);
        
        let payment_balance = coin::into_balance<SUI>(payment);
        balance::join<SUI>(&mut nft_fund.balance, payment_balance);

        let nft = PaulNft{
            id: object::new(ctx),
            name: b"Paul",
            image_url: b"",
            tag: counter.counter,
        };

        counter.counter = counter.counter +1 ;
        transfer::public_transfer(nft, tx_context::sender(ctx));
    }

    public entry fun create_market(ctx: &mut TxContext){
        let (kiosk, kiosk_cap) = kiosk::new(ctx);

        transfer::public_transfer(kiosk_cap, tx_context::sender(ctx));
        transfer::public_share_object(kiosk);
    }

    public entry fun place_nft(
        kiosk_obj: &mut Kiosk,
        kiosk_cap: &KioskOwnerCap,
        nft: PaulNft, 
       _ctx: &mut TxContext){
        
        kiosk::place(kiosk_obj, kiosk_cap, nft);
    }

    public entry fun list_nft(
        kiosk_obj: &mut Kiosk,
        kiosk_cap: &KioskOwnerCap,
        sale_list: &mut SaleList,
        id: ID,
        price: u64, 
       _ctx: &mut TxContext){
        
        kiosk::list<PaulNft>(kiosk_obj, kiosk_cap, id, price, );
        table::add<ID, u64>(&mut sale_list.item_price_table, id, price);
    }

    public entry fun close_and_withdraw_kiosk(
        kiosk_obj: Kiosk,
        kiosk_cap: KioskOwnerCap,
        ctx: &mut TxContext,
    ){
        let rewards = kiosk::close_and_withdraw(kiosk_obj, kiosk_cap, ctx);
        transfer::public_transfer(rewards, tx_context::sender(ctx));
    }

    public entry fun list_nft_with_purchase_cap(
        kiosk_obj: &mut Kiosk,
        kiosk_cap: &KioskOwnerCap,
        id: ID,
        min_price: u64, 
        ctx: &mut TxContext
    ){
        let purchase_cap = kiosk::list_with_purchase_cap<PaulNft>(
            kiosk_obj,
            kiosk_cap,
            id,
            min_price,
            ctx,
        );

        transfer::public_transfer(purchase_cap, tx_context::sender(ctx));
    }

    public entry fun take_nft(
        kiosk_obj: &mut Kiosk,
        kiosk_cap: &KioskOwnerCap,
        id: ID,
        ctx: &mut TxContext
    ){
        let nft = kiosk::take<PaulNft>(
            kiosk_obj,
            kiosk_cap,
            id,
        );

        transfer::public_transfer(nft, tx_context::sender(ctx));
    }

    public entry fun delist_nft(
        kiosk_obj: &mut Kiosk,
        kiosk_cap: &KioskOwnerCap,
        id: ID,
    ){
        kiosk::delist<PaulNft>(
            kiosk_obj,
            kiosk_cap,
            id,
        );
    }

    public entry fun purchase_nft(
        kiosk_obj: &mut Kiosk,
        sale_list: &mut SaleList,
        policy: &mut TransferPolicy<PaulNft>,
        id: ID,
        payments: Coin<SUI>,
        clock: &Clock,
        ctx: &mut TxContext,
    ){
        let paid = table::remove<ID, u64>(&mut sale_list.item_price_table, id);
        let royalty_req = royalty_rule::calculate_royalty(policy, paid);
        let royalty_value = royalty_rule::get_royalty_value(&royalty_req);
        assert!( coin::value(&payments) >=  (royalty_value + paid), EBalanceNtEnough);
        
        let royalty_fee = coin::split(&mut payments, royalty_value, ctx); 
        let pay_item = coin::split(&mut payments, paid, ctx); 

        let (nft, transfer_req) = kiosk::purchase<PaulNft>(
            kiosk_obj,
            id,
            pay_item,
        );

        royalty_rule::handle_royalty<PaulNft>(policy, &mut transfer_req, royalty_req, royalty_fee);
        time_rule::confirm_time<PaulNft>(policy, &mut transfer_req, clock);
        transfer::public_transfer(payments, tx_context::sender(ctx));

        transfer_policy::confirm_request(policy, transfer_req);

        transfer::public_transfer(nft, tx_context::sender(ctx));

    }

    public entry fun purchase_nft_with_cap(
        kiosk_obj: &mut Kiosk,
        purchase_cap: PurchaseCap<PaulNft>,
        policy: &mut TransferPolicy<PaulNft>,
        payments: Coin<SUI>,
        clock: &Clock,
        ctx: &mut TxContext,
    ){
        
        let paid = coin::value(&payments);
        let min_price = kiosk::purchase_cap_min_price(&purchase_cap);
        assert!( paid >= min_price, EBalanceNtEnough);

        let royalty_req = royalty_rule::calculate_royalty(policy, min_price);
        let royalty_value = royalty_rule::get_royalty_value(&royalty_req);
        assert!( paid >= min_price + royalty_value, EBalanceNtEnough);
        
        let royalty_fee = coin::split(&mut payments, royalty_value, ctx); 

        let (nft, transfer_req) = kiosk::purchase_with_cap(
            kiosk_obj,
            purchase_cap,
            payments,
        );

        royalty_rule::handle_royalty<PaulNft>(policy, &mut transfer_req, royalty_req, royalty_fee);

        time_rule::confirm_time<PaulNft>(policy, &mut transfer_req, clock);

        transfer_policy::confirm_request(policy, transfer_req);

        transfer::public_transfer(nft, tx_context::sender(ctx));

    }

    
}