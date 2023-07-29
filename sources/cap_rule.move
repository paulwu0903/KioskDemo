module kiosk_demo::cap_rule{

    use sui::transfer_policy::{
        Self,
        TransferPolicy,
        TransferPolicyCap,
        TransferRequest,
    };

    const ERuleNotSet: u64 = 0;

    struct Rule<phantom Cap> has drop{}

    struct Config has store, drop {}

    public fun set<T, Cap>(
        policy: &mut TransferPolicy<T>,
        cap: &TransferPolicyCap<T>,
    ){
        transfer_policy::add_rule(Rule<Cap>{}, policy, cap, Config{});
    }


    public fun confim <T, Cap>(
        policy: &mut TransferPolicy<T>,
        request: &mut TransferRequest<T>,
        _cap: &Cap,
    ){
        assert!(transfer_policy::has_rule<T, Rule<Cap>>(policy), ERuleNotSet);
        transfer_policy::add_receipt(Rule<Cap>{}, request);
    }
}