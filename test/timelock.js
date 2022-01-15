const { expect } = require('chai')
const { ethers } = require('hardhat')

describe('TokenTimeLock Contract Tests', () => {
    let deployer;
    let account1;
    let account2;
    let account3;
    let account4;
    let testPaymentToken;
    let timelock;

    beforeEach(async () => {
        [deployer, account1, account2, account3, account4] = await ethers.getSigners()

        const TestPaymentToken = await ethers.getContractFactory('ERC20PresetMinterPauser')
        testPaymentToken = await TestPaymentToken.deploy('TestPaymentToken', 'TPT')
        await testPaymentToken.deployed()

    })

    describe('Testing variations of timelocks', async () => {

        it('calling release prematurely', async () => {

            const sevenDays = 7 * 24 * 60 * 60;

            const timeNow = (await ethers.provider.getBlock(await ethers.provider.getBlockNumber())).timestamp;

            const timestampAfter = timeNow + sevenDays;

            const TimeLock = await ethers.getContractFactory('TokenTimelock');
            timelock = await TimeLock.deploy();

            await timelock.initialize(testPaymentToken.address, account1.address, timestampAfter);

            await testPaymentToken.mint(timelock.address, 100000);

            await expect(timelock.release()).to.be.revertedWith("TokenTimelock: current time is before release time");
            
            const account1TokenBalance = await testPaymentToken.balanceOf(account1.address);

            expect(account1TokenBalance).to.equal(0);
        });

        it('calling release after time expires', async () => {

            const sevenDays = 7 * 24 * 60 * 60;

            const timeNow = (await ethers.provider.getBlock(await ethers.provider.getBlockNumber())).timestamp;

            const timestampAfter = timeNow + sevenDays;

            const TimeLock = await ethers.getContractFactory('TokenTimelock');
            timelock = await TimeLock.deploy();

            await timelock.initialize(testPaymentToken.address, account1.address, timestampAfter);

            await testPaymentToken.mint(timelock.address, 100000);

            await ethers.provider.send('evm_increaseTime', [sevenDays + 2]);
            await ethers.provider.send('evm_mine');
     
            await timelock.release();
            
            const account1TokenBalance = await testPaymentToken.balanceOf(account1.address);

            expect(account1TokenBalance).to.equal(100000);
        });

        it('calling release after some time', async () => {

            const sevenDays = 7 * 24 * 60 * 60;
            const twoDays = 2 * 24 * 60 * 60;

            const timeNow = (await ethers.provider.getBlock(await ethers.provider.getBlockNumber())).timestamp;

            const timestampAfter = timeNow + sevenDays;

            const TimeLock = await ethers.getContractFactory('TokenTimelock');
            timelock = await TimeLock.deploy();

            await timelock.initialize(testPaymentToken.address, account1.address, timestampAfter);

            await testPaymentToken.mint(timelock.address, 100000);

            await ethers.provider.send('evm_increaseTime', [twoDays]);
            await ethers.provider.send('evm_mine');

            await expect(timelock.release()).to.be.revertedWith("TokenTimelock: current time is before release time");

            await ethers.provider.send('evm_increaseTime', [twoDays]);
            await ethers.provider.send('evm_mine');

            await expect(timelock.release()).to.be.revertedWith("TokenTimelock: current time is before release time");

            await ethers.provider.send('evm_increaseTime', [twoDays*2]);
            await ethers.provider.send('evm_mine');

            await timelock.release();
            
            const account1TokenBalance = await testPaymentToken.balanceOf(account1.address);

            expect(account1TokenBalance).to.equal(100000);
        });

        it('calling release after time expires with more tokens added', async () => {

            const sevenDays = 7 * 24 * 60 * 60;

            const timeNow = (await ethers.provider.getBlock(await ethers.provider.getBlockNumber())).timestamp;

            const timestampAfter = timeNow + sevenDays;

            const TimeLock = await ethers.getContractFactory('TokenTimelock');
            timelock = await TimeLock.deploy();

            await timelock.initialize(testPaymentToken.address, account1.address, timestampAfter);

            await testPaymentToken.mint(timelock.address, 100000);

            await ethers.provider.send('evm_increaseTime', [sevenDays + 2]);
            await ethers.provider.send('evm_mine');

            await testPaymentToken.mint(timelock.address, 100000);
     
            await timelock.release();
            
            const account1TokenBalance = await testPaymentToken.balanceOf(account1.address);

            expect(account1TokenBalance).to.equal(200000);
        });




    });
});