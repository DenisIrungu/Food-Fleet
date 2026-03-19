const { onRequest } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const axios = require("axios");

admin.initializeApp();

const db = admin.firestore();

// ─────────────────────────────────────────────
// HELPER: Get M-Pesa Access Token
// ─────────────────────────────────────────────
async function getMpesaAccessToken(consumerKey, consumerSecret) {
    const auth = Buffer.from(`${consumerKey}:${consumerSecret}`).toString("base64");
    console.log(`Getting token for key: ${consumerKey.substring(0, 10)}...`);
    try {
        const response = await axios.get(
            "https://sandbox.safaricom.co.ke/oauth/v1/generate?grant_type=client_credentials",
            {
                headers: {
                    Authorization: `Basic ${auth}`,
                },
            }
        );
        console.log(`Token response: ${JSON.stringify(response.data)}`);
        return response.data.access_token;
    } catch (e) {
        console.error(`Token error: ${JSON.stringify(e.response?.data)} - ${e.message}`);
        throw e;
    }
}

// ─────────────────────────────────────────────
// HELPER: Generate M-Pesa Password
// ─────────────────────────────────────────────
function getMpesaPassword(shortcode, passkey) {
    const timestamp = new Date()
        .toISOString()
        .replace(/[^0-9]/g, "")
        .slice(0, 14);
    const password = Buffer.from(`${shortcode}${passkey}${timestamp}`).toString("base64");
    return { password, timestamp };
}

// ─────────────────────────────────────────────
// CLOUD FUNCTION: Initiate STK Push
// ─────────────────────────────────────────────
exports.initiateStkPush = onRequest(
    { region: "us-central1", cors: true },
    async (req, res) => {
        if (req.method !== "POST") {
            return res.status(405).json({ error: "Method not allowed" });
        }

        const { restaurantId, phone, amount, orderId } = req.body;

        console.log(`STK Push request: restaurantId=${restaurantId}, phone=${phone}, amount=${amount}, orderId=${orderId}`);

        // ── VALIDATE INPUT ──
        if (!restaurantId || !phone || !amount || !orderId) {
            return res.status(400).json({
                error: "Missing required fields: restaurantId, phone, amount, orderId."
            });
        }

        // ── FETCH RESTAURANT PAYMENT SETTINGS ──
        const settingsDoc = await db
            .collection("restaurants")
            .doc(restaurantId)
            .collection("paymentSettings")
            .doc("mpesa")
            .get();

        if (!settingsDoc.exists) {
            console.error(`No payment settings found for restaurant: ${restaurantId}`);
            return res.status(404).json({
                error: "M-Pesa settings not configured for this restaurant."
            });
        }

        const settings = settingsDoc.data();
        console.log(`Settings found: shortcode=${settings.shortcode}, type=${settings.type}`);
        const { shortcode, passkey, consumerKey, consumerSecret } = settings;

        // ── FORMAT PHONE NUMBER ──
        let formattedPhone = phone.toString().replace(/\s/g, "");
        if (formattedPhone.startsWith("0")) {
            formattedPhone = "254" + formattedPhone.substring(1);
        } else if (formattedPhone.startsWith("+")) {
            formattedPhone = formattedPhone.substring(1);
        }
        console.log(`Formatted phone: ${formattedPhone}`);

        // ── GET ACCESS TOKEN ──
        let accessToken;
        try {
            accessToken = await getMpesaAccessToken(consumerKey, consumerSecret);
            console.log(`Access token obtained: ${accessToken.substring(0, 10)}...`);
        } catch (e) {
            console.error(`Failed to get access token: ${e.message}`);
            return res.status(500).json({
                error: "Failed to get M-Pesa access token. Check your credentials."
            });
        }

        // ── GENERATE PASSWORD & TIMESTAMP ──
        const { password, timestamp } = getMpesaPassword(shortcode, passkey);
        console.log(`Timestamp: ${timestamp}`);

        // ── CALLBACK URL ──
        const callbackUrl = `https://mpesacallback-i66m6taedq-uc.a.run.app`;

        // ── STK PUSH REQUEST ──
        let stkResponse;
        try {
            console.log(`Sending STK push to Safaricom...`);
            stkResponse = await axios.post(
                "https://sandbox.safaricom.co.ke/mpesa/stkpush/v1/processrequest",
                {
                    BusinessShortCode: shortcode,
                    Password: password,
                    Timestamp: timestamp,
                    TransactionType: "CustomerPayBillOnline",
                    Amount: Math.ceil(amount),
                    PartyA: formattedPhone,
                    PartyB: shortcode,
                    PhoneNumber: formattedPhone,
                    CallBackURL: callbackUrl,
                    AccountReference: `FoodFleet-${orderId}`,
                    TransactionDesc: "Food Order Payment",
                },
                {
                    headers: {
                        Authorization: `Bearer ${accessToken}`,
                    },
                }
            );
            console.log(`STK response: ${JSON.stringify(stkResponse.data)}`);
        } catch (e) {
            console.error(`STK Push error: ${JSON.stringify(e.response?.data)} - ${e.message}`);
            return res.status(500).json({
                error: `STK Push failed: ${e.response?.data?.errorMessage || e.message}`
            });
        }

        const { CheckoutRequestID, ResponseCode, ResponseDescription } = stkResponse.data;

        // ── SAVE PAYMENT RECORD TO FIRESTORE ──
        await db.collection("payments").doc(CheckoutRequestID).set({
            checkoutRequestId: CheckoutRequestID,
            orderId,
            restaurantId,
            phone: formattedPhone,
            amount,
            status: "pending",
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        return res.status(200).json({
            success: ResponseCode === "0",
            checkoutRequestId: CheckoutRequestID,
            responseDescription: ResponseDescription,
        });
    }
);

// ─────────────────────────────────────────────
// CLOUD FUNCTION: M-Pesa Callback
// ─────────────────────────────────────────────
exports.mpesaCallback = onRequest(
    { region: "us-central1", cors: true },
    async (req, res) => {
        const body = req.body;

        try {
            const callbackData = body.Body.stkCallback;
            const checkoutRequestId = callbackData.CheckoutRequestID;
            const resultCode = callbackData.ResultCode;
            const resultDesc = callbackData.ResultDesc;

            console.log(`Callback received: checkoutRequestId=${checkoutRequestId}, resultCode=${resultCode}`);

            if (resultCode === 0) {
                const metadata = callbackData.CallbackMetadata.Item;
                const amount = metadata.find((i) => i.Name === "Amount")?.Value;
                const mpesaCode = metadata.find((i) => i.Name === "MpesaReceiptNumber")?.Value;
                const phone = metadata.find((i) => i.Name === "PhoneNumber")?.Value;

                await db.collection("payments").doc(checkoutRequestId).update({
                    status: "success",
                    mpesaCode,
                    phone,
                    amount,
                    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                });

                const paymentDoc = await db.collection("payments").doc(checkoutRequestId).get();
                if (paymentDoc.exists) {
                    const { orderId } = paymentDoc.data();
                    await db.collection("orders").doc(orderId).update({
                        status: "confirmed",
                        paymentStatus: "paid",
                        mpesaCode,
                        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                    });
                }
            } else {
                await db.collection("payments").doc(checkoutRequestId).update({
                    status: "failed",
                    resultDesc,
                    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                });
            }

            res.status(200).json({ ResultCode: 0, ResultDesc: "Success" });
        } catch (e) {
            console.error("Callback error:", e);
            res.status(200).json({ ResultCode: 0, ResultDesc: "Success" });
        }
    }
);

// ─────────────────────────────────────────────
// CLOUD FUNCTION: Query STK Push Status
// ─────────────────────────────────────────────
exports.queryStkStatus = onRequest(
    { region: "us-central1", cors: true },
    async (req, res) => {
        if (req.method !== "POST") {
            return res.status(405).json({ error: "Method not allowed" });
        }

        const { checkoutRequestId } = req.body;

        if (!checkoutRequestId) {
            return res.status(400).json({ error: "checkoutRequestId is required" });
        }

        const paymentDoc = await db.collection("payments").doc(checkoutRequestId).get();

        if (!paymentDoc.exists) {
            return res.status(200).json({ status: "pending" });
        }

        return res.status(200).json({ status: paymentDoc.data().status });
    }
);