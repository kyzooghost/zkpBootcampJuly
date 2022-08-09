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
    @state(Bool) roundFinished = State<Bool>();
    @state(Field) oddsLimit = State<Field>();
    @state(Field) player1Commit = State<Field>();
    @state(UInt64) pot = State<UInt64>();
    @state(PublicKey as any) player1 = State<PublicKey>();
    @state(PublicKey as any) player2 = State<PublicKey>();
  
    @method init(player1_: PublicKey, player2_: PublicKey, oddsLimit_: Field, depositAmount_: UInt64) {
        // Make sure state variables not set yet
        let player1_initial = this.player1.get();
        let player2_initial = this.player1.get();
        let oddsLimit_initial = this.oddsLimit.get();
        let pot_initial = this.pot.get();
        player1_initial.assertEquals(PublicKey.empty());
        player2_initial.assertEquals(PublicKey.empty());
        oddsLimit_initial.assertEquals(Field.zero);
        pot_initial.assertEquals(UInt64.zero);

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
  