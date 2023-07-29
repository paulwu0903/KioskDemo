module kiosk_demo::witness_rule{
    use sui::transfer_policy::{Self, TransferPolicy, TransferPolicyCap, TransferRequest};

    const ERuleNotSet: u64 = 0;
    
    struct Rule<phantom W> has drop {}
    struct Config has store, drop{}
    
    public fun set<T, W>(
        policy: &mut TransferPolicy<T>,
        cap: &TransferPolicyCap<T>,
    ){
        transfer_policy::add_rule(Rule<W>{}, policy, cap, Config{});
    }

    public fun confirm<T, W:drop>(
        _: W,
        policy: &mut TransferPolicy<T>,
        request: &mut TransferRequest<T>,
    ){
        assert!(transfer_policy::has_rule<T, Rule<W>>(policy), ERuleNotSet);
        transfer_policy::add_receipt(Rule<W>{}, request);
    }

}