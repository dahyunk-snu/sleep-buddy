// index.js
//
// [보안] 이 Cloud Function은 비활성화(주석 처리)되었습니다.
// 기존 구현에는 다음 문제가 있어 공개 저장소에서는 동작하지 않도록 막아두었습니다.
//   - App Check / 사용자별 호출 제한이 없어 앱 밖에서 직접 호출해 Gemini 비용을 발생시킬 수 있음
//   - message / persona 의 길이·타입 검증이 없음
//   - 클라이언트가 보낸 persona 가 systemInstruction 에 그대로 들어가 가드레일 우회 가능
//   - API 키를 Secret Manager 가 아닌 일반 환경변수로 주입
// 다시 사용하려면 위 항목을 보완한 뒤 주석을 해제하세요.
// (함수가 비활성화되어 있으므로 앱의 '꿈친구' 채팅 기능은 동작하지 않습니다.)

/*
const { initializeApp } = require("firebase-admin/app");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { GoogleGenAI } = require("@google/genai");

initializeApp();

const API_KEY = process.env.GEMINI_API_KEY;
const ai = new GoogleGenAI({ apiKey: API_KEY });

exports.generateChatResponse = onCall({ region: "asia-northeast3" }, async (request) => {
  if (!API_KEY) {
    throw new HttpsError("internal", "서버 설정에 문제가 발생했습니다.");
  }
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "The function must be called while authenticated.");
  }

  const userMessage = request.data.message;
  const persona = request.data.persona;

  if (!userMessage) {
    throw new HttpsError("invalid-argument", 'The function must be called with one argument "message".');
  }

  try {
    const chat = ai.chats.create({
      model: "gemini-2.5-flash-lite",
      config: {
        systemInstruction: buildSystemInstruction(persona),
        maxOutputTokens: 256
      }
    });
    const result = await chat.sendMessage({ message: userMessage });
    return { text: result.text };
  } catch (error) {
    console.error("Gemini API 호출 중 오류 발생:", error);
    throw new HttpsError("internal", "AI와 대화하는 중 문제가 발생했어요.");
  }
});

function buildSystemInstruction(persona) {
  // persona가 비어있어도 안전한 기본 역할 제공
  // 여기에 제품 레벨 가드레일/스타일 가이드/포맷 강제 등을 넣어두면 매 요청 일관적 적용
  const base = [
    "너는 '꿈친구'야. 사용자에게 항상 다정하고 따뜻한 친구처럼 말해야 해.",
    "사용자의 하루를 위로해주고, 힘든 일이 있었다면 공감해줘.",
    "반드시 반말로, 짧고 친근한 말투를 사용해. 예를 들어, '~했어?', '~구나', '~해봐' 같은 말투야.",
    "너 자신을 '나'라고 칭하고, 사용자를 '너'라고 불러.",
  ].join("\n");

  if (!persona) return base;

  // 클라에서 문자열로 받되, 서버에서 안전히 래핑해 결합
  return `# Persona\n${persona}\n\n# Global Rules\n${base}`;
}
*/
