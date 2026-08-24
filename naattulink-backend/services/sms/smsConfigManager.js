const SMS_ACCOUNTS = [
  {
    id: "textbee_1",
    providerType: "textbee",
    priority: 1,
    enabled: true,

    monthlyLimit: 300,
    quotaType: "recurring",

    apiKey: process.env.TEXTBEE_API_KEY_1,
    deviceId: process.env.TEXTBEE_DEVICE_ID_1,
  },
  {
    id: "smsupdates_1",
    providerType: "smsupdates",
    priority: 2,
    enabled: true,

    monthlyLimit: 1000,
    quotaType: "trial",

    apiKey: process.env.SMSUPDATES_API_KEY,
  },
  {
    id: "quickcom_1",
    providerType: "quickcom",
    priority: 3,
    enabled: true,

    monthlyLimit: 1000,
    quotaType: "trial",

    apiKey: process.env.QUICKCOM_API_KEY,
  },
  {
    id: "telewise_1",
    providerType: "telewise",
    priority: 4,
    enabled: true,

    monthlyLimit: 100,
    quotaType: "trial",

    apiKey: process.env.TELEWISE_API_KEY,
  },
  {
    id: "contactwise_1",
    providerType: "contactwise",
    priority: 5,
    enabled: true,

    monthlyLimit: 100,
    quotaType: "free",

    apiKey: process.env.CONTACTWISE_API_KEY,
  }
];

module.exports = {
  SMS_ACCOUNTS,
};
