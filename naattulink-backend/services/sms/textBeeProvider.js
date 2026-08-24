const axios = require('axios');

class TextBeeProvider {
  /**
   * Sends an SMS via TextBee API
   * @param {Object} params
   * @param {string} params.phone - E.164 formatted phone number
   * @param {string} params.message - The SMS body
   * @param {string} params.apiKey - TextBee API Key
   * @param {string} params.deviceId - TextBee Device ID
   */
  async sendSms({ phone, message, apiKey, deviceId }) {
    if (!deviceId || !apiKey) {
      throw new Error('Device ID and API Key are required for TextBee provider.');
    }

    try {
      const response = await axios.post(
        `https://api.textbee.dev/api/v1/gateway/devices/${deviceId}/sendSMS`,
        {
          receivers: [phone],
          smsBody: message
        },
        {
          headers: {
            'x-api-key': apiKey
          }
        }
      );

      return { success: true, data: response.data };
    } catch (error) {
      // Re-throw so account manager can catch and failover
      throw error;
    }
  }
}

module.exports = new TextBeeProvider();
