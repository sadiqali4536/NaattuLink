const axios = require('axios');

class EmailJsProvider {
  /**
   * Sends an OTP email using EmailJS.
   *
   * @param {string} toEmail - The recipient's email address
   * @param {string} otp - The OTP code
   * @returns {Promise<{success: boolean, error?: string}>}
   */
  async sendEmailOtp(toEmail, otp) {
    const serviceId = process.env.EMAILJS_SERVICE_ID;
    const templateId = process.env.EMAILJS_TEMPLATE_ID;
    const privateKey = process.env.EMAILJS_PRIVATE_KEY;

    if (!serviceId || !templateId || !privateKey) {
      console.error("EmailJS environment variables are missing.");
      return { success: false, error: 'Email configuration error' };
    }

    try {
      const payload = {
        service_id: serviceId,
        template_id: templateId,
        user_id: process.env.EMAILJS_PUBLIC_KEY || privateKey, // Fallback to privateKey if public key is not provided separately.
        accessToken: privateKey,
        template_params: {
          to_email: toEmail,
          verification_code: otp
        }
      };

      const response = await axios.post('https://api.emailjs.com/api/v1.0/email/send', payload, {
        headers: {
          'Content-Type': 'application/json'
        }
      });

      if (response.status === 200) {
        return { success: true };
      } else {
        return { success: false, error: `EmailJS responded with status ${response.status}` };
      }
    } catch (error) {
      console.error('EmailJS send error:', error.response ? error.response.data : error.message);
      return { success: false, error: 'Failed to send email' };
    }
  }
}

module.exports = new EmailJsProvider();
