const { expect } = require('chai')
const { ethers } = require('hardhat')

describe('TokenTimeLock Contract Tests', () => {
    let deployer;
    let account1;
    let account2;
    let account3;
    let account4;
    let testPaymentToken;
    let tokenvesting;

    beforeEach(async () => {
        [deployer, account1, account2, account3, account4] = await ethers.getSigners()

        const TestPaymentToken = await ethers.getContractFactory('ERC20PresetMinterPauser')
        testPaymentToken = await TestPaymentToken.deploy('TestPaymentToken', 'TPT')
        await testPaymentToken.deployed()

    })

    describe('Testing variations of Token Vesting', async () => {

        it('calling release prematurely', async () => {

            const sevenDays = 7 * 24 * 60 * 60;

            const TokenVesting = await ethers.getContractFactory('TokenVesting');
            tokenvesting = await TokenVesting.deploy();

            const timeNow = (await ethers.provider.getBlock(await ethers.provider.getBlockNumber())).timestamp;

            await tokenvesting.initialize(account1.address, timeNow, sevenDays, false);

            await testPaymentToken.mint(tokenvesting.address, 100000);

            await expect(tokenvesting.release(testPaymentToken.address)).to.be.revertedWith("TokenVesting: no tokens are due");
        });

        it('calling release after expires', async () => {

            const sevenDays = 7 * 24 * 60 * 60;

            const TokenVesting = await ethers.getContractFactory('TokenVesting');
            tokenvesting = await TokenVesting.deploy();

            const timeNow = (await ethers.provider.getBlock(await ethers.provider.getBlockNumber())).timestamp;

            await testPaymentToken.mint(tokenvesting.address, 100000);

            await tokenvesting.initialize(account1.address, timeNow, sevenDays/2, false);

            await ethers.provider.send('evm_increaseTime', [sevenDays]);
            await ethers.provider.send('evm_mine');

            await tokenvesting.release(testPaymentToken.address);

            const account1TokenBalance = await testPaymentToken.balanceOf(account1.address);

            expect(account1TokenBalance).to.equal(100000);

        });

        it('calling release after some time', async () => {

            const sevenDays = 7 * 24 * 60 * 60;

            const TokenVesting = await ethers.getContractFactory('TokenVesting');
            tokenvesting = await TokenVesting.deploy();

            const timeNow = (await ethers.provider.getBlock(await ethers.provider.getBlockNumber())).timestamp;

            await testPaymentToken.mint(tokenvesting.address, 100000);

            await tokenvesting.initialize(account1.address, timeNow, sevenDays, false);

            await ethers.provider.send('evm_increaseTime', [sevenDays/2]);
            await ethers.provider.send('evm_mine');

            const vestedamount = await tokenvesting.vested(testPaymentToken.address);
            expect(vestedamount).to.equal(50000);

            await tokenvesting.release(testPaymentToken.address);

            const account1TokenBalance = await testPaymentToken.balanceOf(account1.address);

            expect(account1TokenBalance).to.equal(50000);

        });

        it('calling release after some time more tokens added', async () => {

            const sevenDays = 7 * 24 * 60 * 60;

            const TokenVesting = await ethers.getContractFactory('TokenVesting');
            tokenvesting = await TokenVesting.deploy();

            const timeNow = (await ethers.provider.getBlock(await ethers.provider.getBlockNumber())).timestamp;

            await testPaymentToken.mint(tokenvesting.address, 100000);

            await tokenvesting.initialize(account1.address, timeNow, sevenDays, false);

            await ethers.provider.send('evm_increaseTime', [sevenDays/2]);
            await ethers.provider.send('evm_mine');

            const vestedamount = await tokenvesting.vested(testPaymentToken.address);
            expect(vestedamount).to.equal(50000);

            await testPaymentToken.mint(tokenvesting.address, 100000);

            await tokenvesting.release(testPaymentToken.address);

            const account1TokenBalance = await testPaymentToken.balanceOf(account1.address);

            expect(account1TokenBalance).to.equal(100001);

        });


    });
});