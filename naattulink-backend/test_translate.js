const axios = require('axios');
async function translate(text, tl) {
  const url = \https://translate.googleapis.com/translate_a/single?client=gtx&sl=en&tl=\&dt=t&q=\\;
  const res = await axios.get(url);
  return res.data[0][0][0];
}
async function run() {
  console.log('Malayalam:', await translate('Kallai Railway Gate', 'ml'));
  console.log('Hindi:', await translate('Mankavu Junction', 'hi'));
}
run();
