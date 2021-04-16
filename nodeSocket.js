// // // // const net = require('net');
// // // var io = require('socket.io-client')
// // // // const socket = io('https://api.atomic.eosdetroit.io/atomicassets/v1/transfers');

// // // // socket.on('new_transfer', (data) => {console.log(data) });


// // // // npm i npm i socket.io-client

// // // const socket = io('https://api.atomic.eosdetroit.io/atomicassets/v1/transfers');
// // // console.log('socket',socket)
// // // socket.on("connect", () => {
// // //     console.log(socket.id); // "G5p5..."
// // //   });
// // // socket.on("new_transfer", data => {
// // //     console.log(data);
// // //   });

// // //   const net = require('net-socket')
// // //   const client = net.connect(443, 'api.atomic.eosdetroit.io')
// // // console.log('client', client)
// // //   client.on('connect', (data)=>{
// // //     client.on('new_transfer', function (data) {
// // //         console.log('Received: ' + data);
// // //         client.destroy(); // kill client after server's response
// // //     });
// // //       console.log('data---', data)
// // //   })




// // var net = require('net-socket');
 
// // var socket = net.connect(443, 'api.atomic.eosdetroit.io','/atomicassets/v1/transfers');
 
// // socket.setEncoding('utf8');
// // socket.on('connect', function () {
 
// //     // console.log('ccccccccc')    
// //     // socket.end('hey');
// //     // socket.destroy();
// // });
// // console.log('connect', socket)
// // socket.on('new_transfer', function (data) {
// //     console.log('Received: ' + data);
// //     // client.destroy(); // kill client after server's response
// // });

// const io = require('socket.io-client')
// socket = io.connect('https://api.atomic.eosdetroit.io/atomicassets/v1/transfers')
// console.log('socket', socket)
// socket.on('new_transfer', function (socket) {
//     console.log(socket);
//   });

  
// // Importing dgram module
// var dgram = require('dgram');
  
// // Creating and initializing clinet
// // and server socket
// var client = dgram.createSocket("udp4");
// var server = dgram.createSocket("udp4");
  
// // Catching the message event
// server.on("message", function (msg) {
  
//     // Displaying the client message
//     process.stdout.write("UDP String: " + msg + "\n");
  
//     // Exiting process
//     process.exit();
// })
//     // Binding server with port
//     .bind(1234, () => {
  
//         // Getting the address information 
//         // for the server by using 
//         // address method
//         const address = server.address()
  
//         // Display the result
//         console.log(address);
  
//     });
  
// // Connecting the server with particular local host 
// // and address by using connect() method
// server.connect(80, "https://agile-taiga-80620.herokuapp.com/", (abc) => {
//     console.log("connected", abc)
// })
  

// server.on("new_transfer", function (msg) {
//      console.log('ddd',msg)
//     // Displaying the client message
//     process.stdout.write("UDP String: " + msg + "\n");
  
//     // Exiting process
//     process.exit();
// })


var io = require('socket.io-client')

const socket = io('https://agile-taiga-80620.herokuapp.com/')

console.log('socket', socket)
// socket.on('color change')