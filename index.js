import WebSocket, { WebSocketServer } from "ws";

const PORT = process.env.PORT || 43661;
const wss = new WebSocketServer({ port: PORT });

console.log(`✅ Sanctuary BotServer körs på ws://localhost:${PORT}`);

wss.on("connection", ws => {
  console.log("🟢 Ny klient ansluten");

  ws.on("message", data => {
    try {
      const msg = JSON.parse(data.toString());
      if (msg.type === "heartbeat") return; // Ignorera pingar

      // Skicka vidare till alla andra anslutna klienter
      wss.clients.forEach(client => {
        if (client !== ws && client.readyState === WebSocket.OPEN) {
          client.send(JSON.stringify(msg));
        }
      });
    } catch (err) {
      console.error("❌ Fel i inkommande data:", err);
    }
  });

  ws.on("close", () => console.log("🔴 Klient frånkopplad"));
});
