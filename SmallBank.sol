//
// Created by ZhmYe on 2023/8/4.
//
pragma solidity ^0.4.24;
 
contract SmallBank {
    // 这里暂时先将key值存为string，方便hiera直接产生交易
    // hot account和hot rate设置在hiera中，这样才能使得不同合约调用create后创建管理不同账户
    // 账户string 在 hiera中先默认设置为"account_${index}_${shard_id}"
    mapping(string=>uint256) savings; // 储蓄金map
    mapping(string=>uint256) checkings; // 支票map
    mapping(string=>bool) createFlag; // 这里为了判断账户是否已被创建
    uint256 defaultSavingBalance = 0; // 创建saving时的默认初始值(0)
    uint256 defaultCheckingBalance = 0; // 创建checking时的默认初始值(0)
    uint256 MaxSavingBalance = 10000000000; // saving的最大值
    uint256 MaxCheckingBalance = 10000000000; // checking的最大值
    
    // 事件可以用于具体应用监听
    event on_isCreate(string account); // 账户已被创建事件
    event on_create(string account); // 账户创建事件
    event on_checking_balance_not_enough(string account, uint256 amount); // 支票余额不足，amount为差值
    event on_saving_balance_not_enouph(string account, uint256 amount); // 储蓄余额不足，amount为差值
    event on_over_max_saving(string account, uint256 amount); // 储蓄余额超过限额，amount为差值
    event on_over_max_checking(string account, uint256 amount); // 支票余额超过限额，amount为差值
    event on_notCreate(string account);
    // 判断账户是否已被创建
    function isCreate(string account) public view returns (bool) {
        return createFlag[account];
    }
    // 创建账户
    function createAccount(string account) public {
        if (!isCreate(account)) {
            savings[account] = defaultSavingBalance;
            checkings[account] = defaultCheckingBalance;
            createFlag[account] = true;
            emit on_create(account);
        } else {
            emit on_isCreate(account);
        }
    } 
    // 将支票账户并到储蓄账户,全部转出
    function almagate(string account) public {
        if (!isCreate(account)) {emit on_notCreate(account); return;}
       uint256 savingsBalance = savings[account]; // saving余额
       uint256 checkingsBalance = checkings[account]; // checking余额
       checkings[account] = 0;
       savings[account] = savingsBalance + checkingsBalance;
    }
    // 向储蓄金账户中增加一定金额
    function transactSavings(string account, uint256 amount) public{
        // savings[account] = savings[account] + amount;
        if (!isCreate(account)) {emit on_notCreate(account); return;}
        if (savings[account] + amount <= MaxSavingBalance) {
            savings[account] += amount;
        } else {
            // 超过限额
            emit on_over_max_saving(account, savings[account] + amount - MaxSavingBalance);
            savings[account] = MaxSavingBalance;
        }
    }
    // 向支票账户中增加一定金额
    function depositChecking(string account, uint256 amount) public{
        if (!isCreate(account)) {emit on_notCreate(account); return;}
        if (checkings[account] + amount <= MaxCheckingBalance) {
            checkings[account] += amount;
        } else {
            // 超过限额
            emit on_over_max_checking(account, checkings[account] + amount - MaxCheckingBalance);
            checkings[account] = MaxCheckingBalance;
        }
    }
    // 减少支票账户
    function writeCheck(string account, uint256 amount) public{
        if (!isCreate(account)) {emit on_notCreate(account); return;}
        // 需要考虑是否足够
        if (checkings[account] >= amount) {
            checkings[account] -= amount;
        } else {
            emit on_checking_balance_not_enough(account, amount - checkings[account]);
            if (savings[account] >= amount - checkings[account])
                savings[account] -= (amount - checkings[account]);
            else
            {
                emit on_saving_balance_not_enouph(account, amount - checkings[account] - savings[account]);
                savings[account] = 0; // 如果不够先从saving扣
            }
            checkings[account] = 0; //不够的话直接置为0

        }
    } 
    // fromAccount向toAccount转账amount
    function sendPayment(string fromAccount, string toAccount, uint256 amount) public{
        if (!isCreate(fromAccount)) {emit on_notCreate(fromAccount); return;}
        if (!isCreate(toAccount)) {emit on_notCreate(toAccount); return;}
        // 需要考虑是否足够
        if (savings[fromAccount] >= amount) {
            savings[fromAccount] -= amount;
            savings[toAccount] += amount;
        } else {
            emit on_saving_balance_not_enouph(fromAccount, amount - savings[fromAccount]);
            savings[toAccount] += savings[fromAccount]; // 转入所有能转入的
            savings[fromAccount] = 0; // 不够的话置为0
        }
    }
    // 得到账户余额信息
    function getBalance(string account) public returns (uint256[3] balance) {
        if (!isCreate(account)) {
            emit on_notCreate(account);
            return [MaxSavingBalance + 1, MaxCheckingBalance + 1, MaxSavingBalance + MaxCheckingBalance + 2];
        }
        return [savings[account], checkings[account], savings[account] + checkings[account]];
    }
}