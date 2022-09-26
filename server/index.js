const express = require("express");
const mongoose = require("mongoose");
const authRouter = require("./routes/auth");
const cors = require("cors");
const documentRouter = require("./routes/document");

const PORT = process.env.PORT | 3003;

const app = express();
app.use(cors())
app.use(express.json());
app.use(authRouter);
app.use(documentRouter);
const DB = 'mongodb+srv://koderkt:Chethan0707@cluster0.owidrye.mongodb.net/?retryWrites=true&w=majority';
// const DB = "mongodb://localhost:27017"
mongoose.connect(DB).then(()=>{
  
  console.log("Connection successful");
}).catch((err)=>{
  console.log(err);
});



app.listen(PORT,"0.0.0.0",()=>{
  console.log(`Connected on ${PORT}`);
});
