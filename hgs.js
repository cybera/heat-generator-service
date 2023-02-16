/*
 hgs.js  
 Usage: node hgs
*/
const express = require("express");  
const http = require('http');
// const https = require('https');

const app = express();  

const router = express.Router();
const viewPath = __dirname + '/views/';
const staticPath = __dirname + '/static/';

//Enable static assets in the './static' folder
app.use(express.static('static'));

// all templates are located in './views' folder
app.set('views', __dirname + '/views');
app.set('view engine', 'ejs');

router.get("/",function(req,res){
    var sess = req.session;
    res.render("index", {});
});




app.use("/",router);

app.use("*",function(req,res){
    res.status(404).end("404")
    console.log('404 '+ req.baseUrl)
});

// var secureServer = https.createServer({
//     key: fs.readFileSync('./ssl/server.key'),
//     cert: fs.readFileSync('./ssl/server.crt'),
//     rejectUnauthorized: false
// }, app).listen('8443', function() {
//     console.log("Secure Express server listening on port 8443");
// });
http.createServer(app).listen('8043');
console.log("Express server listening on port 8043");

console.log(new Date().toISOString());

