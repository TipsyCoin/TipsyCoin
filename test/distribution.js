const { expect } = require('chai')
const { ethers } = require('hardhat')

describe('Distribution Contract Tests', () => {
    let deployer;
    let account1;
    let account2;
    let account3;
    let account4;
    let testPaymentToken;
    let distribution;

    beforeEach(async () => {
        [deployer, account1, account2, account3, account4] = await ethers.getSigners()

        const TestPaymentToken = await ethers.getContractFactory('ERC20PresetMinterPauser')
        testPaymentToken = await TestPaymentToken.deploy('TestPaymentToken', 'TPT')
        await testPaymentToken.deployed()

    })

    describe('Testing variations of distributions', async () => {

        it('payment token is distributed evenly to multiple payees', async () => {

            payeeAddressArray = [account1.address, account2.address, account3.address, account4.address]
            payeeShareArray = [10, 10, 10, 10];

            const Distribution = await ethers.getContractFactory('Distribution');
            distribution = await Distribution.deploy();
            await distribution.deployed();

            await distribution.initialize(payeeAddressArray, payeeShareArray,testPaymentToken.address);

            await testPaymentToken.mint(distribution.address, 100000);

            await distribution
                .release_all();

            const account1TokenBalance = await testPaymentToken.balanceOf(account1.address);
            const account2TokenBalance = await testPaymentToken.balanceOf(account2.address);
            const account3TokenBalance = await testPaymentToken.balanceOf(account3.address);
            const account4TokenBalance = await testPaymentToken.balanceOf(account4.address);

            expect(account1TokenBalance).to.equal(25000);
            expect(account2TokenBalance).to.equal(25000);
            expect(account3TokenBalance).to.equal(25000);
            expect(account4TokenBalance).to.equal(25000);
        });

        it('payment token is distributed unevenly to multiple payees', async () => {

            payeeAddressArray = [account1.address, account2.address, account3.address, account4.address]
            payeeShareArray = [10, 5, 11, 7];

            const Distribution = await ethers.getContractFactory('Distribution');
            distribution = await Distribution.deploy();
            await distribution.deployed();

            await distribution.initialize(payeeAddressArray, payeeShareArray,testPaymentToken.address);

            await testPaymentToken.mint(distribution.address, 100000);

            await distribution
                .release_all();

            const account1TokenBalance = await testPaymentToken.balanceOf(account1.address);
            const account2TokenBalance = await testPaymentToken.balanceOf(account2.address);
            const account3TokenBalance = await testPaymentToken.balanceOf(account3.address);
            const account4TokenBalance = await testPaymentToken.balanceOf(account4.address);


            expect(account1TokenBalance).to.equal(30303);
            expect(account2TokenBalance).to.equal(15151);
            expect(account3TokenBalance).to.equal(33333);
            expect(account4TokenBalance).to.equal(21212);

        });

        it('adjust weight to equal', async () => {

            payeeAddressArray = [account1.address, account2.address, account3.address, account4.address]
            payeeShareArray = [10, 5, 11, 7];

            const Distribution = await ethers.getContractFactory('Distribution');
            distribution = await Distribution.deploy();
            await distribution.deployed();

            const fakeArray = await distribution.initialize(payeeAddressArray, payeeShareArray,testPaymentToken.address);

            await testPaymentToken.mint(distribution.address, 100000);

            await distribution
                .adjustWeight(account2.address, 10);

            await distribution
                .adjustWeight(account3.address, 10);

            await distribution
                .adjustWeight(account4.address, 10);

            await distribution
                .release_all();

            const account1TokenBalance = await testPaymentToken.balanceOf(account1.address);
            const account2TokenBalance = await testPaymentToken.balanceOf(account2.address);
            const account3TokenBalance = await testPaymentToken.balanceOf(account3.address);
            const account4TokenBalance = await testPaymentToken.balanceOf(account4.address);


            expect(account1TokenBalance).to.equal(25000);
            expect(account2TokenBalance).to.equal(25000);
            expect(account3TokenBalance).to.equal(25000);
            expect(account4TokenBalance).to.equal(25000);

        });

        it('unequal weights with 0', async () => {

            payeeAddressArray = [account1.address, account2.address, account3.address, account4.address]
            payeeShareArray = [10, 0, 0, 0];

            const Distribution = await ethers.getContractFactory('Distribution');
            distribution = await Distribution.deploy();
            await distribution.deployed();

            await expect(distribution.initialize(payeeAddressArray, payeeShareArray,testPaymentToken.address)).to.be.revertedWith("TokenPaymentSplitter: shares are 0");

        });

        it('non-owner adjusting weight', async () => {

            payeeAddressArray = [account1.address, account2.address, account3.address, account4.address]
            payeeShareArray = [10, 5, 11, 7];

            const Distribution = await ethers.getContractFactory('Distribution');
            distribution = await Distribution.deploy();
            await distribution.deployed();

            const fakeArray = await distribution.initialize(payeeAddressArray, payeeShareArray,testPaymentToken.address);

            await testPaymentToken.mint(distribution.address, 100000);

            await expect(distribution.connect(account1).adjustWeight(account1.address, 500)).to.be.revertedWith("Ownable: caller is not the owner");

        });

        it('adding tokens later', async () => {

            payeeAddressArray = [account1.address, account2.address, account3.address, account4.address]
            payeeShareArray = [10, 10, 10, 10];

            const Distribution = await ethers.getContractFactory('Distribution');
            distribution = await Distribution.deploy();
            await distribution.deployed();

            await distribution.initialize(payeeAddressArray, payeeShareArray,testPaymentToken.address);

            await testPaymentToken.mint(distribution.address, 100000);

            await distribution
                .release_all();

            let account1TokenBalance = await testPaymentToken.balanceOf(account1.address);
            let account2TokenBalance = await testPaymentToken.balanceOf(account2.address);
            let account3TokenBalance = await testPaymentToken.balanceOf(account3.address);
            let account4TokenBalance = await testPaymentToken.balanceOf(account4.address);

            expect(account1TokenBalance).to.equal(25000);
            expect(account2TokenBalance).to.equal(25000);
            expect(account3TokenBalance).to.equal(25000);
            expect(account4TokenBalance).to.equal(25000);

            await testPaymentToken.mint(distribution.address, 100000);

            await distribution
                .release_all();

            account1TokenBalance = await testPaymentToken.balanceOf(account1.address);
            account2TokenBalance = await testPaymentToken.balanceOf(account2.address);
            account3TokenBalance = await testPaymentToken.balanceOf(account3.address);
            account4TokenBalance = await testPaymentToken.balanceOf(account4.address);

            const totalShares = await distribution.totalShares();
            
            expect(account1TokenBalance).to.equal(50000);
            expect(account2TokenBalance).to.equal(50000);
            expect(account3TokenBalance).to.equal(50000);
            expect(account4TokenBalance).to.equal(50000);

            expect(totalShares).to.equal(40);


        });

        it('add new payee later along with tokens later', async () => {

            payeeAddressArray = [account1.address, account2.address]
            payeeShareArray = [10, 10];

            const Distribution = await ethers.getContractFactory('Distribution');
            distribution = await Distribution.deploy();
            await distribution.deployed();

            await distribution.initialize(payeeAddressArray, payeeShareArray,testPaymentToken.address);

            await testPaymentToken.mint(distribution.address, 100000);

            await distribution
                .release_all();

            let account1TokenBalance = await testPaymentToken.balanceOf(account1.address);
            let account2TokenBalance = await testPaymentToken.balanceOf(account2.address);
            let account3TokenBalance = await testPaymentToken.balanceOf(account3.address);
            let account4TokenBalance = await testPaymentToken.balanceOf(account4.address);

            expect(account1TokenBalance).to.equal(50000);
            expect(account2TokenBalance).to.equal(50000);
            expect(account3TokenBalance).to.equal(0);
            expect(account4TokenBalance).to.equal(0);

            await distribution.addNewPayee(account3.address, 10);
            await distribution.addNewPayee(account4.address, 10);

            await testPaymentToken.mint(distribution.address, 100000);
            const totalShares = await distribution.totalShares();

            expect(totalShares).to.equal(40);

            await distribution
                .release_all();

            account1TokenBalance = await testPaymentToken.balanceOf(account1.address);
            account2TokenBalance = await testPaymentToken.balanceOf(account2.address);
            account3TokenBalance = await testPaymentToken.balanceOf(account3.address);
            account4TokenBalance = await testPaymentToken.balanceOf(account4.address);

            
            expect(account1TokenBalance).to.equal(75000);
            expect(account2TokenBalance).to.equal(75000);
            expect(account3TokenBalance).to.equal(25000);
            expect(account4TokenBalance).to.equal(25000);

            expect(totalShares).to.equal(40);
        });

    });
});