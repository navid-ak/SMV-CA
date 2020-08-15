mtype = {COCA, SPRITE, CANCEL}
#define COCA_COST 50
#define SPRITE_COST 100
#define CANCEL_PAYMENT 3
#define POS_ERROR 1
#define PAY 1
#define NOT_PAY 0
#define SUCCESSFUL_PAYMENT 1

byte ltl_getProduct;
byte ltl_order;
byte ltl_payment;
byte ltl_gainedProduct;
byte ltl_price;

chan C_V = [0] of {mtype};
chan V_C = [0] of {mtype};
chan V_P = [1] of {byte};
chan P_V = [1] of {byte};
chan C_P = [0] of {byte};
chan P_C = [0] of {byte};

proctype Human(){
    mtype boughtProduct;
    byte msg;
    do
    :: C_V!COCA;
    :: C_V!SPRITE; 
    :: C_V!CANCEL; printf("human want to cancel from Vending \n");
    :: C_P!CANCEL_PAYMENT; printf("human want to cancel from POS \n");
    :: V_C?boughtProduct;
        if
        ::boughtProduct == COCA -> ltl_getProduct = COCA; ltl_gainedProduct = 1; printf("COCA has been bought \n");
        ::boughtProduct == SPRITE -> ltl_getProduct = SPRITE; ltl_gainedProduct = 1; printf("SPRITE has been bought \n");
        fi
    :: P_C?msg;
        if
        :: true -> C_P!PAY;
        :: true -> C_P!NOT_PAY;
        fi
    ::else -> skip;
    od

}

proctype ECE_VM(){
    byte state = 1;
    mtype value;
    byte msg;
    mtype requestedProduct;
    do
    :: C_V?value;
        if
        :: value == CANCEL -> state = 1;
        :: (value == COCA && state == 1)  -> 
            printf("human want COCA \n");
            V_P!COCA_COST; 
            ltl_price = COCA_COST;
            requestedProduct = COCA;
            ltl_order = COCA;
            printf("Vending send coca request to POS \n");
            state = 2;
        :: (value == SPRITE && state == 1) -> 
            printf("human want SPRITE \n");
            V_P!SPRITE_COST; 
            ltl_price = SPRITE_COST;
            ltl_order = SPRITE;
            requestedProduct = SPRITE;
            printf("Vending send sprite request to POS \n");
            state = 2;
        :: else ->
                skip;
        fi
    :: P_V?msg;
        if
        :: (msg == SUCCESSFUL_PAYMENT && state == 2) -> 
                printf("Human can peak the product \n"); 
                state = 3;
        :: else ->
                skip;
        fi    
    :: state == 3 ->
        V_C!requestedProduct;
        printf("Vending send product for human \n");
        state = 1;
    od
}

proctype POS(){
    byte state = 1;
    byte cost;
    byte msg;
    do
    :: V_P?cost;
        if
        :: state == 1 ->
            printf("human should pay %d RIALS \n", cost);
            P_C!cost;
            state = 2;
        :: state != 1 ->
            skip;
        fi
    :: C_P?msg;
        if
        :: msg == CANCEL_PAYMENT -> 
            state = 1;
        :: (msg == PAY && state == 2)->
            printf("Customer has just pay the bill \n");
            state = 3;
        :: (msg == NOT_PAY && state == 2) ->
            state = 2;
        fi
    :: state == 3 ->
        if
        :: true -> 
                state = 2; 
                P_C!POS_ERROR;
                ltl_gainedProduct = 0;
        :: true -> 
                state = 1; 
                ltl_gainedProduct = 1;
                printf("Payment was successful \n"); 
                P_V!SUCCESSFUL_PAYMENT;
        fi
    :: else -> skip;
    od
}

init
{
    atomic{
        run Human();
        run ECE_VM();
        run POS();
    }
}

// ltl Q1 {[]((ltl_getProduct == COCA ->(ltl_order == COCA)) | (ltl_getProduct == SPRITE -> (ltl_order == SPRITE)))}
// ltl Q2 {[]((ltl_payment == 1 -> ltl_gainedProduct == 1 ) )}
ltl Q3 {[]((ltl_getProduct == COCA -> ltl_price == COCA_COST) |(ltl_getProduct == SPRITE -> ltl_price == SPRITE_COST) )}