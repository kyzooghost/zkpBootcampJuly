import * as readline from 'readline';
import { Odds } from './odds.js';
import {
  Field,
  isReady,
  Mina,
  Party,
  PrivateKey,
  UInt64,
  shutdown,
  Permissions,
} from 'snarkyjs';

let rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout,
});

function askQuestion(theQuestion: string): Promise<string> {
  return new Promise((resolve) =>
    rl.question(theQuestion, (answ) => resolve(answ))
  );
}

const doProofs = false;

export async function run() {
  await isReady;
  // initilize local blockchain
  const Local = Mina.LocalBlockchain();
  Mina.setActiveInstance(Local);

  // the mock blockchain gives you access to 10 accounts
  const deployerAcc = Local.testAccounts[0].privateKey;
  const player1Acc = Local.testAccounts[1].privateKey;
  const player2Acc = Local.testAccounts[2].privateKey;

  // Compile contract
  const zkAppPrivkey = PrivateKey.random();
  const zkAppAddress = zkAppPrivkey.toPublicKey();
  const zkAppInstance = new Odds(zkAppAddress);

  if (doProofs) {
    try {
      await Odds.compile(zkAppAddress);
    } catch (err) {
      console.log(err);
    }
  }

  // Deploy and initialize contract
  const pot = new UInt64(Field(25000));
  const oddsLimit = Field(1000);

  const tx = await Mina.transaction(deployerAcc, () => {
    Party.fundNewAccount(deployerAcc, { initialBalance: pot }); // Take funds from deployerAcc, then give 1 MINA funds to whatever account needs it in the tx.
    zkAppInstance.deploy({ zkappKey: zkAppPrivkey });
    zkAppInstance.setPermissions({
      ...Permissions.default(),
      editState: Permissions.proofOrSignature(),
      receive: Permissions.proofOrSignature(),
      send: Permissions.proofOrSignature(),
    });
    zkAppInstance.init(player1Acc.toPublicKey(), player2Acc.toPublicKey(), oddsLimit, pot);
  });

  await tx.send().wait();

  console.log('Contract balance: ', Mina.getBalance(zkAppAddress).toString());
  console.log('Player 1 balance: ', Mina.getBalance(player1Acc.toPublicKey()).toString());
  console.log('Player 2 balance: ', Mina.getBalance(player2Acc.toPublicKey()).toString());

  // Start round
  console.log('------');
  let guess = await askQuestion('Player 1, what is your number? \n');
  try {
    const tx2 = await Mina.transaction(player1Acc, () => {
      zkAppInstance.startRound(Field(guess), player1Acc);
      if (!doProofs) {zkAppInstance.sign(zkAppPrivkey);}
    });
    if (doProofs) await tx2.prove();
    await tx2.send().wait();
  } catch (err) {
    console.log(err);
  }

  console.log(
    'hash of the player1 commit is:',
    zkAppInstance.player1Commit.get().toString()
  );

  console.log('Switching to user 2');

  let usersGuess = await askQuestion('Player 2, what is your number? \n');
  try {
    const tx3 = await Mina.transaction(player2Acc, () => {
      zkAppInstance.finishRound(Field(usersGuess), player2Acc);
      const player2Party = Party.createSigned(player2Acc);
      player2Party.balance.addInPlace(pot);
      if (!doProofs) {
        zkAppInstance.sign(zkAppPrivkey);
      }
    });
    if (doProofs) await tx3.prove();
    await tx3.send().wait();

    console.log('Correct, you win the pot!');
    console.log('Contract balance: ', Mina.getBalance(zkAppAddress).toString());
    console.log('Player 1 balance: ', Mina.getBalance(player1Acc.toPublicKey()).toString());
    console.log('Player 2 balance: ', Mina.getBalance(player2Acc.toPublicKey()).toString());
  } catch {
    console.log('Wrong, loser!');
    return;
  }
}

(async function () {
  await run();
  await shutdown();
})();
