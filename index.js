// index.js
const PORT = process.env.PORT || 43661;

const { Server } = require("socket.io");
const io = new Server(PORT, {
  cors: { origin: "*" } // Tillåt alla klienter att ansluta
});

console.log(`✅ Sanctuary BotServer är igång på port ${PORT}`);

// När en klient ansluter
io.on("connection", (socket) => {
  console.log("🟢 Ny klient ansluten:", socket.id);

  // Ta emot meddelanden från klienter
  socket.on("message", (msg) => {
    // Skicka vidare till alla andra anslutna klienter
    socket.broadcast.emit("message", msg);
  });

  // När klienten disconnectar
  socket.on("disconnect", (reason) => {
    console.log("🔴 Klient frånkopplad:", socket.id, "-", reason);
  });
});
