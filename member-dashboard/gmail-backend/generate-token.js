require("dotenv").config();
const { google } = require("googleapis");
const http = require("http");
const url = require("url");
const fs = require("fs");
const path = require("path");
const readline = require("readline");

const clientId = process.env.GMAIL_CLIENT_ID;
const clientSecret = process.env.GMAIL_CLIENT_SECRET;
const PORT = process.env.PORT || 5002;
const REDIRECT_URI = process.env.GMAIL_REDIRECT_URI || `http://localhost:${PORT}/oauth2callback`;

if (!clientId || !clientSecret) {
  console.error("❌ GMAIL_CLIENT_ID or GMAIL_CLIENT_SECRET missing in .env file.");
  process.exit(1);
}

const oauth2Client = new google.auth.OAuth2(
  clientId,
  clientSecret,
  REDIRECT_URI
);

const scopes = [
  "https://www.googleapis.com/auth/gmail.send",
  "https://www.googleapis.com/auth/calendar",
];

const authUrl = oauth2Client.generateAuthUrl({
  access_type: "offline",
  prompt: "consent",
  scope: scopes,
});

console.log("\n==================================================");
console.log("🔑 GOOGLE OAUTH REFRESH TOKEN GENERATOR");
console.log("==================================================");
console.log("\n1. Open this URL in your browser:\n");
console.log(authUrl);
console.log("\n2. Log in and grant permissions.");
console.log(`3. The browser will automatically redirect to ${REDIRECT_URI}.`);
console.log("   (If redirect fails or redirect URI is different, paste the code from browser below.)\n");

async function saveRefreshToken(tokens) {
  if (!tokens.refresh_token) {
    console.log("\n⚠️  No refresh token returned.");
    console.log("Tip: Remove access for this app in your Google Account (https://myaccount.google.com/permissions) and try again.");
    return;
  }

  // Verify token works for this Client ID / Secret
  try {
    oauth2Client.setCredentials({ refresh_token: tokens.refresh_token });
    const accessRes = await oauth2Client.getAccessToken();
    if (!accessRes.token) {
      throw new Error("Could not retrieve access token using new refresh token");
    }
    console.log("✅ Verified: Refresh token is valid and active!");
  } catch (verifyErr) {
    console.error("\n❌ Token verification failed:", verifyErr.message);
    if (verifyErr.response && verifyErr.response.data) {
      console.error("Google Error Details:", verifyErr.response.data);
    }
    console.error("\nPlease ensure your GMAIL_CLIENT_ID and GMAIL_CLIENT_SECRET in .env match the Google Cloud Console credentials.");
    return;
  }

  console.log("\n==================================================");
  console.log("✅ NEW REFRESH TOKEN OBTAINED & VERIFIED:");
  console.log("==================================================");
  console.log(tokens.refresh_token);

  const envPath = path.join(__dirname, ".env");
  if (fs.existsSync(envPath)) {
    let envContent = fs.readFileSync(envPath, "utf8");
    if (envContent.includes("GMAIL_REFRESH_TOKEN=")) {
      envContent = envContent.replace(
        /GMAIL_REFRESH_TOKEN=.*/,
        `GMAIL_REFRESH_TOKEN=${tokens.refresh_token}`
      );
    } else {
      envContent += `\nGMAIL_REFRESH_TOKEN=${tokens.refresh_token}`;
    }
    fs.writeFileSync(envPath, envContent, "utf8");
    console.log("\n🎉 Successfully updated GMAIL_REFRESH_TOKEN in .env file!");
  }
}

let serverClosed = false;

const server = http.createServer(async (req, res) => {
  try {
    const reqUrl = url.parse(req.url, true);
    if (reqUrl.pathname === "/oauth2callback") {
      const code = reqUrl.query.code;
      if (code && !serverClosed) {
        serverClosed = true;
        res.writeHead(200, { "Content-Type": "text/html" });
        res.end("<h2>Authorization successful!</h2><p>You can close this tab and return to the terminal.</p>");
        server.close();

        const { tokens } = await oauth2Client.getToken(code);
        await saveRefreshToken(tokens);
        process.exit(0);
      }
    }
  } catch (err) {
    console.error("❌ Error exchanging code for tokens:", err.message);
    res.writeHead(500, { "Content-Type": "text/plain" });
    res.end("Error obtaining token");
    server.close();
    process.exit(1);
  }
});

server.listen(PORT, () => {
  // Readline fallback if redirect URI mismatch or manual entry needed
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout,
  });

  rl.question("Enter the authorization code (or URL param 'code'): ", async (code) => {
    if (serverClosed) return;
    serverClosed = true;
    server.close();
    rl.close();

    let cleanCode = code.trim();
    if (cleanCode.includes("code=")) {
      try {
        const parsedUrl = new URL(cleanCode.startsWith("http") ? cleanCode : `http://localhost?${cleanCode}`);
        cleanCode = parsedUrl.searchParams.get("code") || cleanCode;
      } catch (e) {
        // fallback
      }
    }
    if (!cleanCode) {
      console.log("No code entered.");
      process.exit(1);
    }

    try {
      const { tokens } = await oauth2Client.getToken(cleanCode);
      await saveRefreshToken(tokens);
      process.exit(0);
    } catch (err) {
      console.error("❌ Error exchanging code:", err.message);
      process.exit(1);
    }
  });
});
