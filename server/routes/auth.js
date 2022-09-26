const User = require("../models/user");
const express = require('express');
const jwt = require('jsonwebtoken');
const auth = require("../middleware/auth");
const authRouter = express.Router();


authRouter.post("/api/signup", async (req, res)=> {
  try {
    const { name, email, profilePic} = req.body;
    //Email already exists?
    let user = await User.findOne({ email});
    if(!user){
      user = new User({
         email,
        profilePic,
         name,
      });
      
      user = await user.save();
    }else{
      console.log("User already exists");
    }


    const token = jwt.sign({id: user._id}, "passwordKey");

    res.status(200).json({ user, token});

  } catch (error) 
  {
    res.status(500).json({error:error});
  }
});





authRouter.get("/", auth, async (req, res) => {
  const user = await User.findById(req.user);
  res.json({ user, token: req.token });
});

module.exports = authRouter;
