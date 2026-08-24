const smsAccountManager = require('./smsAccountManager');

class SmsService {
  /**
   * Facade for sending SMS.
   * OTP service calls this, and this routes to the appropriate Account Manager.
   *
   * @param {Object} params
   * @param {string} params.phone - E.164 formatted phone number
   * @param {string} params.message - SMS body
   * @returns {Promise<{success: boolean, providerId: string|null}>}
   */
  async sendSms({ phone, message }) {
    // Delegates to the SMS Account Manager for multi-provider failover
    return await smsAccountManager.sendSmsWithFailover({ phone, message });
  }
}

module.exports = new SmsService();
