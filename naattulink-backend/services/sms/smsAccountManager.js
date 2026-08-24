const { SMS_ACCOUNTS } = require('./smsConfigManager');
const textBeeProvider = require('./textBeeProvider');
const fast2SmsProvider = require('./fast2SmsProvider');

class SmsAccountManager {
  /**
   * Dispatches the SMS through the configured providers based on priority.
   * If one provider fails definitively, it falls back to the next one.
   *
   * @param {Object} params
   * @param {string} params.phone - E.164 formatted phone number
   * @param {string} params.message - The OTP message
   * @returns {Promise<{success: boolean, providerId: string|null}>}
   */
  async sendSmsWithFailover({ phone, message }) {
    // 1. Get enabled accounts and sort by priority (1 is highest)
    const activeAccounts = SMS_ACCOUNTS
      .filter(acc => acc.enabled)
      .sort((a, b) => a.priority - b.priority);

    if (activeAccounts.length === 0) {
      console.error("SMS Failover: No active SMS accounts configured.");
      return { success: false, providerId: null };
    }

    // 2. Iterate through accounts for failover
    for (const account of activeAccounts) {
      try {
        console.log(`Attempting SMS dispatch with provider: ${account.id} (Type: ${account.providerType})`);
        
        let result = { success: false };

        // Dispatch based on provider type
        if (account.providerType === 'textbee') {
          result = await textBeeProvider.sendSms(account, phone, message);
        } else if (account.providerType === 'fast2sms') {
          result = await fast2SmsProvider.sendSms(account, phone, message);
        } else if (account.providerType === 'smsupdates') {
          result = await require('./smsupdatesProvider').sendSms(account, phone, message);
        } else if (account.providerType === 'quickcom') {
          result = await require('./quickcomProvider').sendSms(account, phone, message);
        } else if (account.providerType === 'telewise') {
          result = await require('./telewiseProvider').sendSms(account, phone, message);
        } else if (account.providerType === 'contactwise') {
          result = await require('./contactwiseProvider').sendSms(account, phone, message);
        } else {
          console.warn(`Unknown providerType: ${account.providerType}`);
          continue;
        }

        // 3. Success check
        if (result.success) {
          console.log(`SMS successfully sent using ${account.id}`);
          return { success: true, providerId: account.id };
        } else {
          console.error(`Provider ${account.id} failed to send SMS:`, result.error);
          // Loop continues to the next priority account
        }

      } catch (error) {
        console.error(`Unexpected exception with provider ${account.id}:`, error);
        // Loop continues to the next priority account
      }
    }

    // 4. Exhausted all providers
    console.error("SMS Failover: All configured SMS providers failed.");
    return { success: false, providerId: null };
  }
}

module.exports = new SmsAccountManager();
