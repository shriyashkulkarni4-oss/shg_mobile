// require("dotenv").config();

// const express = require("express");
// const cors = require("cors");
// const bodyParser = require("body-parser");
// const { google } = require("googleapis");

// const app = express();

// app.use(cors({ origin: "http://localhost:3000" }));
// app.use(bodyParser.json());

// // OAuth client
// const oauth2Client = new google.auth.OAuth2(
//   process.env.GMAIL_CLIENT_ID,
//   process.env.GMAIL_CLIENT_SECRET
// );

// // Attach refresh token
// oauth2Client.setCredentials({
//   refresh_token: process.env.GMAIL_REFRESH_TOKEN,
// });

// // Gmail API
// const gmail = google.gmail({ version: "v1", auth: oauth2Client });

// // Helper: create email
// function createMessage(to, subject, text) {
//   const message =
//     `To: ${to}\r\n` +
//     `Subject: ${subject}\r\n\r\n` +
//     text;

//   return Buffer.from(message)
//     .toString("base64")
//     .replace(/\+/g, "-")
//     .replace(/\//g, "_")
//     .replace(/=+$/, "");
// }

// // Send email API
// app.post("/send-email", async (req, res) => {
//   try {
//     const { to, subject, body } = req.body;

//     if (!to || !subject || !body) {
//       return res.status(400).json({ error: "Missing fields" });
//     }

//     const raw = createMessage(to, subject, body);

//     await gmail.users.messages.send({
//       userId: "me",
//       requestBody: { raw },
//     });

//     res.json({ success: true });
//   } catch (err) {
//     console.error("GMAIL ERROR:", err);
//     res.status(500).json({ success: false });
//   }
// });

// const PORT = process.env.PORT || 5001;
// app.listen(PORT, () =>
//   console.log(`📧 Gmail backend running on port ${PORT}`)
// );
require("dotenv").config();

const express = require("express");
const cors = require("cors");
const bodyParser = require("body-parser");
const { google } = require("googleapis");

const app = express();

app.use(
  cors({
    origin: ["http://localhost:3000", "http://localhost:3001"],
    credentials: true,
  })
);
app.use(bodyParser.json());


// ================== GOOGLE OAUTH ==================
const oauth2Client = new google.auth.OAuth2(
  process.env.GMAIL_CLIENT_ID,
  process.env.GMAIL_CLIENT_SECRET
);

oauth2Client.setCredentials({
  refresh_token: process.env.GMAIL_REFRESH_TOKEN,
});

// ================== GOOGLE APIS ==================
const gmail = google.gmail({ version: "v1", auth: oauth2Client });
const calendar = google.calendar({ version: "v3", auth: oauth2Client });

// =================================================
// 📧 HELPER: CREATE RAW EMAIL
// =================================================
function createMessage(to, subject, text) {
  const message =
    `To: ${to}\r\n` +
    `Subject: ${subject}\r\n\r\n` +
    text;

  return Buffer.from(message)
    .toString("base64")
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/, "");
}

// =================================================
// 📧 SEND CUSTOM GMAIL (WELCOME / NOTIFICATION)
// =================================================
app.post("/send-email", async (req, res) => {
  try {
    const { to, subject, body } = req.body;

    if (!to || !subject || !body) {
      return res.status(400).json({ error: "Missing fields" });
    }

    const raw = createMessage(to, subject, body);

    await gmail.users.messages.send({
      userId: "me",
      requestBody: { raw },
    });

    res.json({ success: true });
  } catch (err) {
    if (err.message && (err.message.includes("invalid_grant") || err.message.includes("unauthorized_client"))) {
      console.error("❌ GMAIL OAUTH ERROR: Refresh token is invalid, revoked, or belongs to a different Client ID.");
      console.error("👉 Please run 'npm run get-token' to generate a new verified refresh token.");
      return res.status(401).json({
        success: false,
        error: "Google OAuth refresh token expired or invalid. Run 'npm run get-token' to regenerate.",
      });
    }
    console.error("GMAIL ERROR:", err);
    res.status(500).json({ success: false, error: err.message });
  }
});

// =================================================
// 📅 CREATE GOOGLE MEET + AUTO EMAIL INVITES
// =================================================
app.post("/create-meet", async (req, res) => {
  try {
    const { title, description, startTime, endTime, attendees } = req.body;

    if (!title || !startTime || !endTime || !attendees?.length) {
      return res.status(400).json({ error: "Missing required fields" });
    }

    const event = {
      summary: title,
      description: description || "SHG Scheduled Meeting",
      start: {
        dateTime: startTime,
        timeZone: "Asia/Kolkata",
      },
      end: {
        dateTime: endTime,
        timeZone: "Asia/Kolkata",
      },
      attendees: attendees.map((email) => ({ email })),
      conferenceData: {
        createRequest: {
          requestId: `shg-meet-${Date.now()}`,
          conferenceSolutionKey: {
            type: "hangoutsMeet",
          },
        },
      },
    };

    const response = await calendar.events.insert({
      calendarId: "primary",
      resource: event,
      conferenceDataVersion: 1,
      sendUpdates: "all", // 🔥 auto emails
    });

    res.json({
      success: true,
      meetLink: response.data.hangoutLink,
      eventId: response.data.id,
    });
  } catch (err) {
    if (err.message && (err.message.includes("invalid_grant") || err.message.includes("unauthorized_client"))) {
      console.error("❌ MEET OAUTH ERROR: Refresh token is invalid, revoked, or belongs to a different Client ID.");
      console.error("👉 Please run 'npm run get-token' to generate a new verified refresh token.");
      return res.status(401).json({
        success: false,
        error: "Google OAuth refresh token expired or invalid. Run 'npm run get-token' to regenerate.",
      });
    }
    console.error("MEET ERROR:", err);
    res.status(500).json({ success: false, error: err.message });
  }
});

// =================================================
// 🚀 START SERVER
// =================================================
const PORT = process.env.PORT || 5001;
app.listen(PORT, () =>
  console.log(`🚀 Gmail + Meet backend running on port ${PORT}`)
);
