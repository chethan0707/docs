const express = require('express');
const Document = require('../models/document');
const documentRouter = express.Router();
const auth = require('../middleware/auth');
const e = require('express');

documentRouter.post('/doc/create', auth, async(req, res) =>{
try {
  const { createdAt } = req.body;
  let document = new Document({
    uid: req.user,
    title: 'Untitled Document',
    createdAt,
  });
  document = await document.save();
  res.json(document);
} catch (error) {
  res.status(500).json({error: error.message});
}
});

documentRouter.get('/docs/me',auth, async(req, res)=>{
  try {
    let documents = await Document.find({udi:req.user});
    res.json(documents);
  } catch (error) {
    res.status(500)/json({error: e.message});
  }
});
module.exports = documentRouter;