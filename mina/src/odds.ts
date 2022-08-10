import {
    Field,
    Bool,
    PublicKey,
    SmartContract,
    state,
    State,
    PrivateKey,
    method,
    UInt64,
    Poseidon,
  } from 'snarkyjs';
  
  export class Odds extends SmartContract {
    @state(PublicKey as any) player1 = State<PublicKey>();
    @state(PublicKey as any) player2 = State<PublicKey>();
    @state(Field) oddsLimit = State<Field>();
    @state(UInt64) pot = State<UInt64>();
    @state(Bool) roundFinished = State<Bool>();
    @state(Field) player1Commit = State<Field>();

    // Can't get any state variables before this tx? How to make sure it can only be called once?
    @method init(player1_: PublicKey, player2_: PublicKey, oddsLimit_: Field, depositAmount_: UInt64) {        
        // Set state variables
        this.player1.set(player1_);
        this.player2.set(player2_);
        this.oddsLimit.set(oddsLimit_);
        this.pot.set(depositAmount_);

        // Deposit funds
        this.balance.addInPlace(depositAmount_);
    }
  
    @method startRound(numberToCommit: Field, callerPrivKey: PrivateKey) {
        // Ensure only player 1 can call this function
        let callerAddr = callerPrivKey.toPublicKey();
        let player1 = this.player1.get();
        callerAddr.assertEquals(player1);

        // Assert numberToCommit < oddsLimit
        let oddsLimit = this.oddsLimit.get();
        numberToCommit.assertLte(oddsLimit);

        // Commit
        this.player1Commit.set(Poseidon.hash([numberToCommit]));
    }
  
    @method finishRound(numberToGuess_: Field, callerPrivKey: PrivateKey) {
        // Ensure can only be called once        
        const roundFinished = this.roundFinished.get()
        roundFinished.assertEquals(Bool(false));

        // Ensure only player 1 can call this function
        let callerAddr = callerPrivKey.toPublicKey();
        let player2 = this.player2.get();
        callerAddr.assertEquals(player2);

        // Check guess
        const player1Commit = this.player1Commit.get()
        player1Commit.assertEquals(Poseidon.hash([numberToGuess_]))

        // Turn on mutex
        this.roundFinished.set(Bool(true));

        // Transfer pot
        const pot = this.pot.get()
        this.balance.subInPlace(pot);
    }
  }
  