/* eslint-disable prefer-const */
/* global artifacts */

const { Console } = require("console")
 
const USDT = artifacts.require('USDT')
const config = require("./../config.js");

module.exports = function (deployer, network, accounts) {
  console.log(accounts[0],"accounts");
  deployer.deploy(USDT).then(() => {
    console.log(USDT.address)
  })
}
