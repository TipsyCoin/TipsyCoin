// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


// OpenZeppelin Contracts v4.3.2 (token/ERC20/ERC20.sol)

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "./IPancake.sol";
import "./ITokenTimelock.sol";
import "./TimeLock.sol";

abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
	//transfer to non 0 addy during constructor when deploying 4real to prevent our base contracts being taken over. Ensures only our proxy is usable
        //_transferOwnership(address(~uint160(0)));
        _transferOwnership(address(uint160(0)));
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0x000000000000000000000000000000000000dEaD));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function initOwnership(address newOwner) public virtual {
        require(_owner == address(0), "Ownable: owner already set");
        _owner = newOwner;
        emit OwnershipTransferred(address(0), newOwner);
    }

}

interface WethLike {
function deposit() external payable;
function withdraw(uint256) external;
}

contract TipsyCoin is IERC20, IERC20Metadata, Ownable, Initializable {
    using Address for address;

    address public constant DEAD_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    mapping(address => uint256) private _balances;

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    //uint256 private constant MAX = ~uint256(0);

    uint256 internal _maxTxAmount = 5e8 * 10 ** decimals();
    //uint256 private _tTotal = 100e9 * 10 ** decimals();
    uint256 public _rTotal = 1e18;
    //uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    uint256 internal _buybackFundAmount = 400;
    uint256 internal _marketingCommunityAmount = 200;
    uint256 internal _reflexiveAmount = 400;

    //address public constant WETH = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

    event SellFeeCollected(
        uint256 indexed tokensSwapped,
        uint256 indexed ethReceived
    );


    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) public whiteList;

    mapping(address => bool) public excludedFromFee;

    address public pancakeSwapRouter02;
    IPancakeRouter02 public pancakeV2Router;
    address public pancakePair;

    uint  public releaseTime;
    uint256 public _totalSupply;
    uint256 private _maxSupply;

    string private _name;
    string private _symbol;

    //address private constant WETHTest = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
    //address private constant BUSDTest = 0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7;

    address public cexFund;
    address public charityFund;
    address public teamVestingFund;
    address public futureFund;
    address public communityEngagementFund;
    address public buyBackFund;
    address public marketingFund;
    address public lpLocker;

    address[] private _tokenWETHPath;

    event FeesChanged(uint indexed buyBack, uint indexed marketing, uint indexed reflexive);

    event ExcludedFromFee(address indexed excludedAddress);
    event IncludedInFee(address indexed includedAddress);
    event IncludedInContractWhitelist(address indexed includedWhiteListedContract);
    event Burned(uint indexed oldSupply, uint indexed amount, uint indexed newSupply);
    event Reflex(uint indexed oldRFactor, uint indexed amount, uint indexed newRFactor);
    //event ExcludedFromContractWhitelist(address indexed excludedWhiteListedContract);



    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor() payable {

        //address bigbeef = 0xbeefa0b80F7aC1f1a5B5a81C37289532c5D85e88;
        //Most of this stuff still mainly for testing. To be removed before final release
        address pancakeTest = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;
        buyBackFund = address(this);

        (lpLocker) = deploy(getByteCode1());

        initialize(msg.sender, pancakeTest, 400, 200, 400, 0xeC0e8a3012A5a2F7d7236A8dE36ef0AbDd4fD174, 0xf6ED29517944Eae01B0D4295eCca3CaaD93419bA,
        0x48310176265C2370684bFEEa2a915266E50bE42F, 0x707AF4bD85c76B42eEA3f2A0263724f88F891455, 0x2b379e5e3F269CA5fC6988F0F5a44Eb8BB9E19A1, 0xdDe145BA884EddFfd6849Bb3B72174F4cFd18b30);
        pancakePair = IPancakeFactory(pancakeV2Router.factory()).createPair(address(this), pancakeV2Router.WETH());
        require(_lockLiquidity(), "tipsy: liquidity lock failed");
        //addLiquidity(0);
        /*
        cexFund = 0xeC0e8a3012A5a2F7d7236A8dE36ef0AbDd4fD174; //7%
        charityFund = 0xf6ED29517944Eae01B0D4295eCca3CaaD93419bA; //3%
        marketingFund = 0x48310176265C2370684bFEEa2a915266E50bE42F; //19.7%
        communityEngagementFund = 0x707AF4bD85c76B42eEA3f2A0263724f88F891455; //4.8%
        futureFund = 0x2b379e5e3F269CA5fC6988F0F5a44Eb8BB9E19A1; //5.5%
        teamVestingFund = 0xdDe145BA884EddFfd6849Bb3B72174F4cFd18b30; //10%
        */
    }

    function getByteCode1() public pure returns (bytes memory) {
        bytes memory bytecode = type(TokenTimelock).creationCode;
        return bytecode;
    }

/*    function depositWETH() internal returns (uint){
    uint _balance = address(this).balance;
    WethLike(WETHTest).deposit{value:address(this).balance}();
    return _balance;
    } */

    function deploy(bytes memory _code) public returns (address addr)
    {
        assembly {
            addr:= create(0,add(_code,0x20), mload(_code))
        }
        require(addr != address(0), "tipsy: deploy failed");
        return addr;
    }

    function addLiquidity(uint256 _releaseTime) payable public
    {
        require(address(this).balance >= 1.5e10, "No eth to test, idiot");
        //depositWETH();
        _approve(address(this), pancakeSwapRouter02, 10e9 * 10 ** decimals());
        whiteList[pancakePair] = true;
        pancakeV2Router.addLiquidityETH{value:address(this).balance}(
            address(this), 10e9 * 10 ** decimals(), 1, 1, lpLocker, block.timestamp);
        releaseTime = _releaseTime;
    }

    function _lockLiquidity() public returns (bool)
    {
        //uint _balance = IERC20(pancakePair).balanceOf(address(this));
        //IERC20(pancakePair).transfer(lpLocker, _balance);
        //5 years
        ITokenTimelock(lpLocker).initialize(pancakePair, address(this), block.timestamp + 1825 days);
        return true;
    }

    function addyChk(address _test) internal pure returns (bool)
    {
        return uint160(_test) != 0;
    }

    function initialize(address owner_, address _pancakeSwapRouter02, uint256 buybackFundAmount_, uint256 marketingCommunityAmount_, uint256 reflexiveAmount_, address _cexFund, address _charityFund, address _marketingFund, address _communityEnagementFund, address _futureFund, address _teamVestingFund) public initializer
    {

        initOwnership(owner_);

        require(addyChk(_cexFund) && addyChk(_charityFund) && addyChk(_marketingFund) && addyChk(_communityEnagementFund) && addyChk(_futureFund) && addyChk(_teamVestingFund), "tipsy: initialize address must be set");
        cexFund = _cexFund; //7%
        charityFund = _charityFund; //3%
        marketingFund = _marketingFund; //19.7%
        communityEngagementFund = _communityEnagementFund; //4.8%
        futureFund = _futureFund; //5.5%
        teamVestingFund = _teamVestingFund; //10%


        _buybackFundAmount = buybackFundAmount_;
        _marketingCommunityAmount = marketingCommunityAmount_;
        _reflexiveAmount = reflexiveAmount_;

        _tFeeTotal = _buybackFundAmount + _marketingCommunityAmount + _reflexiveAmount;

        _name = "TipsyCoin";
        _symbol = "tipsy";
        _mint(marketingFund, 19.7 * 1e9 * 10 ** decimals());
        _mint(teamVestingFund, 10 * 1e9 * 10 ** decimals());
        _mint(cexFund, 7 * 1e9 * 10 ** decimals());
        _mint(charityFund, 3 * 1e9 * 10 ** decimals());
        _mint(address(this), 10 * 1e9 * 10 ** decimals()); //Tokens to be added to LP. Should be 50
        _mint(msg.sender, 40 * 1e9 * 10 ** decimals()); //Remove this before release
        _mint(communityEngagementFund, 4.8 * 1e9 * 10 ** decimals());
        _mint(futureFund, 5.5 * 1e9 * 10 ** decimals());
        _maxSupply = 100e9 * 10 ** decimals(); //100 billion
        require(_maxSupply == _totalSupply, "tipsy: not all supply minted");
        _maxTxAmount = _totalSupply / 200; //0.5% of max supply
        _rTotal = 1e18; // reflection ratio starts at 1.0
        require(_realToReflex(1e18) == 1e18, "tipsy: reflex adjustment didn't work");
        pancakeSwapRouter02 = _pancakeSwapRouter02;
        pancakeV2Router = IPancakeRouter02(pancakeSwapRouter02);
        //pancakePair = IPancakeFactory(pancakeV2Router.factory()).createPair(address(this), pancakeV2Router.WETH());

        whiteList[pancakeSwapRouter02] = true;
        excludedFromFee[pancakeSwapRouter02] = false;

        whiteList[address(this)] = excludedFromFee[address(this)] = true;
        whiteList[owner()] = excludedFromFee[owner()] = true;
        whiteList[cexFund] = excludedFromFee[cexFund] = true;
        whiteList[charityFund] = excludedFromFee[charityFund] = true;
        whiteList[teamVestingFund] = excludedFromFee[teamVestingFund] = true;
        whiteList[futureFund] = excludedFromFee[futureFund] = true;
        whiteList[communityEngagementFund] = excludedFromFee[communityEngagementFund] = true;
        whiteList[buyBackFund] = true;
        whiteList[marketingFund] = excludedFromFee[marketingFund]  = true;

        _tokenWETHPath = new address[](2);
        _tokenWETHPath[0] = address(this);
        _tokenWETHPath[1] = pancakeV2Router.WETH();

    }

    function adjustFees(uint buybackFundAmount_, uint marketingCommunityAmount_, uint reflexiveAmount_) public onlyOwner
    {
        require(buybackFundAmount_ + marketingCommunityAmount_ + reflexiveAmount_ <= _tFeeTotal, "New feeTotal > initial feeTotal");
        _buybackFundAmount = buybackFundAmount_;
        _marketingCommunityAmount = marketingCommunityAmount_;
        _reflexiveAmount = reflexiveAmount_;
        emit FeesChanged(_buybackFundAmount, _marketingCommunityAmount, _reflexiveAmount);
    }

    function excludeFromFee(address _excluded) public onlyOwner
    {
        excludedFromFee[_excluded] = true;
        emit ExcludedFromFee(_excluded);
    }

    function includeInFee(address _included) public onlyOwner
    {
        excludedFromFee[_included] = false;
        emit IncludedInFee(_included);
    }

    function includeInWhitelist(address _included) public onlyOwner
    {
        whiteList[_included] = true;
        emit IncludedInContractWhitelist(_included);
    }

    function BuyBackAndBurn(uint _amount) public returns (bool)
    {
        require(IERC20(pancakeV2Router.WETH()).balanceOf(address(this)) > _amount, "tipsy: not enough balance");
        address[] memory _WETHTokenPath = new address[](2);
        _WETHTokenPath[0] = pancakeV2Router.WETH();
        _WETHTokenPath[1] = address(this);
        IERC20(_WETHTokenPath[0]).approve(pancakeSwapRouter02, _amount);
        uint _soldtipsy = pancakeV2Router.swapExactTokensForTokens(_amount, 1, _WETHTokenPath, address(this), block.timestamp)[1];
        _burn(address(this), _soldtipsy);
        return true;
    }

/*
    Mittens note: this could be added back in. But, removing PCS from the whitelist disables would disable selling of our token and is a dangerous action
    I think it's better then, not to have this function to decrease that privelage/centralisation risk
    function excludeFromWhitelist(address _excluded) public onlyOwner
    {
        whiteList[_excluded] = false;
        emit ExcludedFromContractWhitelist(_excluded);
    } */

        function salvage(IERC20 token) public onlyOwner
    {
        if (address(this).balance > 0) payable(owner()).transfer(address(this).balance);
        uint256 amount = token.balanceOf(address(this));
        if (amount > 0) token.transfer(owner(), amount);
    }


    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }


    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view returns (uint256) {
        //return _balances[account];
        return _rBalanceOf(account);
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public noBots(recipient) returns (bool) {
        //Private function always handles reflex to real space, if available
        if (recipient == address(0))
        {
            //If recipient is 0 address, remove sender's tokens and use them for reflection
            _reflect(_msgSender(), amount);
            return true;
        }
        else if (recipient == DEAD_ADDRESS)
        {
            //If recipient is dead address, burn instead of reflect
            _burn(_msgSender(), amount);
            return true;
        }
        else
        {
        //Otherwise, do a normal transfer and emit a transferlog
        _transfer(_msgSender(), recipient, amount);
        _afterTokenTransfer(_msgSender(), recipient, amount);
        return true;
        }
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _realToReflex(_allowances[owner][spender]);
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public noBots(spender) returns (bool) {
        //Private function always handles reflex to real space, if available
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _taxTransaction(address sender, uint amountIn, uint amountOut) private{
    transferNoEvent(sender, address(this), amountIn);
    _pancakeswapSell(amountIn);
    emit SellFeeCollected(amountIn, amountOut);
    }

    //Mittens: ensure this is private before launch :)
    function _pancakeswapSell(uint amountIn) public
    {
        _approve(address(this), pancakeSwapRouter02, amountIn);
        pancakeV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(amountIn, 1, _tokenWETHPath, buyBackFund, block.timestamp);
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public noBots(recipient) returns (bool) {

        //Mittens note: make sure this is check is included before launch
        //recipient.isContract() &&
        if (!excludedFromFee[sender])
        {
            uint _amountBuyBack = amount * _buybackFundAmount / 1e4;
            uint _amountMarketing = amount * _marketingCommunityAmount / 1e4;
            uint _amountReflexive = amount * _reflexiveAmount / 1e4;

            //if(_amountMarketing > 0) _transfer(sender, marketingCommunityAddress, _amountMarketing);
            if(_amountReflexive > 0)  _reflect(sender, _amountReflexive);
            if(_amountBuyBack + _amountMarketing > 0)
            {
                uint _minToLiquify = pancakeV2Router.getAmountsOut(_amountBuyBack + _amountMarketing, _tokenWETHPath)[1];
                if(_minToLiquify >= 1e9) _taxTransaction(sender, _amountBuyBack + _amountMarketing, _minToLiquify);
                else _burn(sender, _amountBuyBack + _amountMarketing);
            }
        amount = amount - _amountBuyBack - _amountMarketing - _amountReflexive;
        _transfer(sender, recipient, amount);
        }
        else
        {
        _transfer(sender, recipient, amount);
        }

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

        modifier noBots(address recipient) {
        require(!recipient.isContract() || whiteList[recipient], "tipsyCoin: Bots and Contracts b&");
        _;
    }


    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }


    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return _realToReflex(_totalSupply);
    }

    function _getNewRate(uint _reflectAmount) public view returns (uint _adjusted)
    {
        //return _rTotalSupply() * 1e18 / (_rTotalSupply() - _reflectAmount);
        return totalSupply() * _rTotal / (totalSupply() - _reflectAmount);
        //return rTotalSupply() * 1e18 / (rTotalSupply() - _reflectAmount);
    }

    function _setNewRate(uint _reflectAmount) public returns (uint newRate)
    {
        _rTotal = _getNewRate(_reflectAmount);
        return _rTotal;
    }

    function _rBalanceOf(address account) public view returns (uint256)
    {
        return _balances[account] * _rTotal / 1e18;
    }


    function _realToReflex(uint _realSpaceTokens) public view returns (uint256 _reflexSpaceTokens)
    {
        return _realSpaceTokens * _rTotal / 1e18;
    }

    function _reflexToReal(uint _reflexSpaceTokens) public view returns (uint256 _realSpaceTokens)
    {
    return _reflexSpaceTokens * 1e18 / _rTotal;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(block.timestamp > releaseTime, "tipsy: token not tradable yet!");
        //require(amount > 0, "tipsy: transfer amount must be greater than zero");
        if(!whiteList[sender] && !whiteList[recipient]) require(amount <= _maxTxAmount, "tipsy: transfer amount exceeds maxTxAmount.");

        uint256 realAmount = _reflexToReal(amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= realAmount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - realAmount;
        }
        _balances[recipient] += realAmount;

    }
    //Mittens note, this is just to avoid some duplicated transfers that might look weird on BSCScan
    function transferNoEvent(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        _transfer(sender, recipient, amount);

    }

    function _afterTokenTransfer(address sender, address recipient, uint amount) public
    {
    emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Dev note, _mint is only called during genesis, so there's no need
     * to adjust real tokens into reflex space, as they are 1:1 at this time
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) private {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        //emit Transfer(address(0), account, amount);
        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Burn} event with old supply, amount burned and new supply.
     * All in r space
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        //Burn removes 'amount' of the total supply, but doesn't reflect rewards
        require(account != address(0), "ERC20: burn from the zero address");
        require(amount > 0, "tipsy: burn amount must be greater than zero");

        uint256 accountBalance = _balances[account];
        //Before continuing, convert amount into realspace
        uint256 _realAmount = _reflexToReal(amount);
        require(accountBalance >= _realAmount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - _realAmount;
        }
        _totalSupply -= _realAmount;
        emit Transfer(account, DEAD_ADDRESS, amount);
        emit Burned(totalSupply() + amount, amount, totalSupply());

    }

    function Reflect(uint amount) public
    {
        _reflect(msg.sender, amount*1e9*1e18);
    }

    function Burn(uint amount) public{
        _burn(msg.sender, amount*1e9*1e18);
    }

    //Reflect removes 'amount' of the total supply, but reflect rewards by adjusting _rTotal so that _rTotalSupply() remains constant
    //Emits a reflex event that has the old _rTotal, the amount reflected, and the new _rTotal
    function _reflect(address account, uint256 amount) internal {

        require(account != address(0), "tipsy: reflect from the zero address");
        require(amount > 0, "tipsy: reflect amount must be greater than zero");

        uint256 accountBalance = _balances[account];
        //Before continuing, convert amount into realspace
        uint256 _realAmount = _reflexToReal(amount);
        require(accountBalance >= _realAmount, "tipsy: reflect amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - _realAmount;
        }
        uint oldRFactor = _rTotal;
        _setNewRate(amount);
        _totalSupply -= _realAmount;

        emit Reflex(oldRFactor, amount, _rTotal);
    }


    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = _reflexToReal(amount);
        emit Approval(owner, spender, amount);
    }

    receive() external payable {}
}
