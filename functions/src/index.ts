import * as admin from "firebase-admin";
import {VertexAI} from "@google-cloud/vertexai";
import {onCall, HttpsError} from "firebase-functions/v2/https";
import {setGlobalOptions} from "firebase-functions/v2";

// Initialize Firebase Admin SDK
admin.initializeApp();

// Set the region for all functions in this file
setGlobalOptions({region: "us-central1"});

// Initialize Vertex AI client
const vertexAI = new VertexAI({project: process.env.GCLOUD_PROJECT!, location: "us-central1"});
const model = "gemini-1.0-pro";

const generativeModel = vertexAI.getGenerativeModel({
    model: model,
});

export const analyzeReport = onCall(async (request) => {
  // In v2 functions, auth and data are on the request object
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "The function must be called while authenticated.",
    );
  }

  const reportText = request.data.text;
  if (!reportText) {
    throw new HttpsError(
      "invalid-argument",
      "The function must be called with the 'text' argument.",
    );
  }

  const prompt = `
    Analyze the following medical lab report text.
    1.  Provide a simple, one-sentence summary for each test result mentioned.
    2.  For any values that are outside the normal range, provide actionable and culturally relevant dietary and lifestyle suggestions suitable for a person living in Kochi, Kerala, India. Use local food names where appropriate (e.g., "thoran", "avial", "pazham pori").
    3.  Generate a list of 3-4 relevant questions the user could ask their doctor based on these results.
    4.  Format the entire output as a single, clean JSON object with three keys: "summary", "recommendations", and "doctorQuestions". The value for "doctorQuestions" should be an array of strings.

    Report Text:
    ---
    ${reportText}
    ---
  `;

  try {
    const resp = await generativeModel.generateContent(prompt);
    const responseText = resp.response?.candidates?.[0]?.content?.parts?.[0]?.text;
    
    if (responseText) {
        return JSON.parse(responseText);
    } else {
        throw new HttpsError("internal", "Received empty or invalid response from AI.");
    }

  } catch (error) {
    console.error("Error calling Gemini API:", error);
    throw new HttpsError(
      "internal",
      "An error occurred while trying to analyze the report.",
    );
  }
});
