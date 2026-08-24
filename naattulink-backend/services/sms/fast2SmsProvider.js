const axios = require('axios');

class Fast2SmsProvider {
  /**
   * Sends an SMS via Fast2SMS
   * @param {Object} account - The Fast2SMS account configuration
   * @param {string} phone - E.164 formatted phone number (e.g., +919207564536)
   * @param {string} message - The SMS body
   * @returns {Promise<{success: boolean, error?: string}>}
   */
  async sendSms(account, phone, message) {
    if (!account.apiKey) {
      return { success: false, error: 'Missing Fast2SMS API Key' };
    }

    // Fast2SMS requires 10 digit numbers for India (removes +91 if present)
    let formattedPhone = phone;
    if (formattedPhone.startsWith('+91')) {
      formattedPhone = formattedPhone.replace('+91', '');
    } else if (formattedPhone.startsWith('91') && formattedPhone.length === 12) {
      formattedPhone = formattedPhone.substring(2);
    }

    try {
      const response = await axios.post(
        'https://www.fast2sms.com/dev/bulkV2',
        {
          route: 'q',
          message: message,
          language: 'english',
          flash: 0,
          numbers: formattedPhone,
        },
        {
          headers: {
            'authorization': account.apiKey,
            'Content-Type': 'application/json',
          },
        }
      );

      if (response.data && response.data.return === true) {
        return { success: true };
      } else {
        return { 
          success: false, 
          error: response.data.message || 'Fast2SMS returned failure' 
        };
      }
    } catch (error) {
      const errorMsg = error.response?.data?.message || error.message || 'Unknown Fast2SMS Error';
      console.error(`Fast2SMS Error for account ${account.id}:`, errorMsg);
      return { success: false, error: errorMsg };
    }
  }
}

module.exports = new Fast2SmsProvider();
