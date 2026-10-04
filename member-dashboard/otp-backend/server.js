require("dotenv").config();

const cors = require("cors");
const axios = require("axios");
const express = require("express");
const bodyParser = require("body-parser");

const app = express();

/* =========================
   CORS + BODY PARSER
========================= */
app.use(
  cors({
    origin: true,
    credentials: true,
  })
);

app.use(bodyParser.json());

/* =========================
   OTP STORE (IN-MEMORY)
========================= */
// phone -> { emiId, used, verificationId }
// We only use this now to track the EMI context and Message Central verificationId.
const otpStore = {};

/* =========================
   HELPER: NORMALIZE PHONE
========================= */
function normalizePhone(phone) {
  if (!phone.startsWith("+")) {
    return "+91" + phone;
  }
  return phone;
}

/* =========================
   HELPER: GET MESSAGE CENTRAL TOKEN
========================= */
async function getMCToken() {
  const customerId = process.env.MESSAGE_CENTRAL_CUSTOMER_ID;
  const password = process.env.MESSAGE_CENTRAL_PASSWORD;
  
  if (!customerId || !password) {
    throw new Error("Message Central credentials missing in .env");
  }

  const key = Buffer.from(password).toString("base64");

  const response = await axios.get("https://cpaas.messagecentral.com/auth/v1/authentication/token", {
    params: {
      country: "IN",
      customerId: customerId,
      key: key,
      scope: "NEW"
    }
  });

  return response.data.token;
}

/* =========================
   SEND OTP
========================= */
app.post("/send-otp", async (req, res) => {
  try {
    let { phone, emiId } = req.body;

    if (!phone) {
      return res.status(400).json({
        success: false,
        message: "Phone is required",
      });
    }

    phone = normalizePhone(phone);

    // Track the context of the OTP request
    otpStore[phone] = {
      emiId,
      used: false,
      verificationId: null,
    };

    console.log("🔐 REQUESTING OTP FROM MESSAGE CENTRAL FOR:", phone);

    /* =========================
       SEND OTP (MESSAGE CENTRAL)
    ========================== */
    if (process.env.MESSAGE_CENTRAL_CUSTOMER_ID) {
      try {
        const token = await getMCToken();

        // Note: Message Central requires these as QUERY PARAMETERS, not body payload
        const mcRes = await axios.post(
          "https://cpaas.messagecentral.com/verification/v3/send",
          null, // empty body
          {
            params: {
              countryCode: "91",
              customerId: process.env.MESSAGE_CENTRAL_CUSTOMER_ID,
              flowType: "SMS",
              mobileNumber: phone.replace("+91", "")
            },
            headers: {
              "authToken": token
            }
          }
        );
        
        // Save the verificationId returned by Message Central so we can validate it later
        if (mcRes.data && mcRes.data.data && mcRes.data.data.verificationId) {
           otpStore[phone].verificationId = mcRes.data.data.verificationId;
        }

        console.log("📩 OTP sent via Message Central. Verification ID:", otpStore[phone].verificationId);
      } catch (mcErr) {
        const errorData = mcErr.response?.data;
        if (errorData && (errorData.responseCode === 506 || errorData.message === 'REQUEST_ALREADY_EXISTS')) {
          console.log("⚠️ OTP request already exists for this number. Reusing verificationId:", errorData.data?.verificationId);
          if (errorData.data && errorData.data.verificationId) {
            otpStore[phone].verificationId = errorData.data.verificationId;
          }
        } else {
          console.error("Message Central Send Error:", errorData || mcErr.message);
          return res.status(500).json({
            success: false,
            message: "Failed to send OTP via Message Central",
            error: errorData || mcErr.message
          });
        }
      }
    }

    res.json({
      success: true,
      message: "OTP dispatched"
    });
  } catch (err) {
    console.error("SEND OTP ERROR:", err);
    res.status(500).json({
      success: false,
      message: "Failed to send OTP",
    });
  }
});

/* =========================
   VERIFY OTP
========================= */
app.post("/verify-otp", async (req, res) => {
  try {
    let { phone, otp, emiId } = req.body;

    if (!phone || !otp) {
      return res.status(400).json({
        success: false,
        message: "Missing phone or otp fields",
      });
    }

    phone = normalizePhone(phone);

    // Check our local context
    const record = otpStore[phone];
    
    if (record && record.used) {
      return res.status(400).json({
        success: false,
        message: "OTP already used",
      });
    }

    if (record && emiId && record.emiId !== emiId) {
      return res.status(400).json({
        success: false,
        message: "Invalid OTP context (EMI mismatch)",
      });
    }

    /* =========================
       VALIDATE OTP (MESSAGE CENTRAL)
    ========================== */
    if (process.env.MESSAGE_CENTRAL_CUSTOMER_ID) {
      try {
        if (!record || !record.verificationId) {
          return res.status(400).json({
             success: false,
             message: "No verification ID found. Please send OTP first."
          });
        }

        const token = await getMCToken();

        // Note: Validate API expects verificationId and code as query params
        const mcRes = await axios.get("https://cpaas.messagecentral.com/verification/v3/validateOtp", {
          params: {
            verificationId: record.verificationId,
            code: otp
          },
          headers: {
            "authToken": token
          }
        });

        console.log("✅ Message Central Validation:", mcRes.data);
        
      } catch (mcErr) {
        console.error("Message Central Verify Error:", mcErr.response?.data || mcErr.message);
        return res.status(400).json({
          success: false,
          message: "Invalid or expired OTP",
          error: mcErr.response?.data || mcErr.message
        });
      }
    }

    // ✅ Mark OTP as used in our context
    if (record) {
      record.used = true;
    }

    console.log("✅ OTP VERIFIED:", phone);

    return res.json({
      success: true,
      message: "OTP verified successfully",
    });
  } catch (err) {
    console.error("VERIFY OTP ERROR:", err);
    res.status(500).json({
      success: false,
      message: "Verification failed",
    });
  }
});

/* =========================
   SERVER START
========================= */
const PORT = process.env.PORT || 5003;

app.listen(PORT, () => {
  console.log(`🚀 OTP backend running on port ${PORT}`);
});