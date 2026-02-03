const express = require('express');
const cors = require('cors');

const app = express();
app.use(cors());
app.use(express.json());

const users = new Map();

setInterval(() => {
  const now = Date.now();
  const timeout = 60000;
  
  for (const [sessionId, userData] of users.entries()) {
    if (now - userData.lastHeartbeat > timeout) {
      console.log(`User timed out: ${userData.username}`);
      users.delete(sessionId);
    }
  }
}, 30000);

app.get('/', (req, res) => {
  res.send(`
    <html>
      <head>
        <title>Roblox Script Presence Server</title>
        <style>
          body {
            font-family: Arial, sans-serif;
            max-width: 800px;
            margin: 50px auto;
            padding: 20px;
            background: #1a1a1a;
            color: #fff;
          }
          .status { color: #00ff00; }
          .user-list {
            background: #2a2a2a;
            padding: 20px;
            border-radius: 10px;
            margin-top: 20px;
          }
          .user {
            padding: 10px;
            background: #3a3a3a;
            margin: 5px 0;
            border-radius: 5px;
          }
        </style>
      </head>
      <body>
        <h1>🟢 Roblox Script Presence Server</h1>
        <p class="status">✅ Server is running!</p>
        <p>Connected users: <strong id="count">0</strong></p>
        <div class="user-list">
          <h3>Active Users:</h3>
          <div id="users">No users connected</div>
        </div>
        <script>
          function updateUsers() {
            fetch('/users')
              .then(r => r.json())
              .then(data => {
                document.getElementById('count').textContent = data.count;
                const usersDiv = document.getElementById('users');
                if (data.users.length === 0) {
                  usersDiv.innerHTML = 'No users connected';
                } else {
                  usersDiv.innerHTML = data.users
                    .map(u => '<div class="user">🟢 ' + u.username + ' (ID: ' + u.userId + ')</div>')
                    .join('');
                }
              });
          }
          updateUsers();
          setInterval(updateUsers, 3000);
        </script>
      </body>
    </html>
  `);
});

app.post('/join', (req, res) => {
  const { username, userId, sessionId } = req.body;
  
  if (!username || !userId || !sessionId) {
    return res.status(400).json({ error: 'Missing required fields' });
  }
  
  users.set(sessionId, {
    username,
    userId,
    lastHeartbeat: Date.now()
  });
  
  console.log(`User joined: ${username} (${userId})`);
  
  res.json({ success: true, message: 'Registered successfully' });
});

app.post('/leave', (req, res) => {
  const { sessionId } = req.body;
  
  if (sessionId && users.has(sessionId)) {
    const user = users.get(sessionId);
    console.log(`User left: ${user.username}`);
    users.delete(sessionId);
  }
  
  res.json({ success: true });
});

app.post('/heartbeat', (req, res) => {
  const { sessionId } = req.body;
  
  if (sessionId && users.has(sessionId)) {
    const user = users.get(sessionId);
    user.lastHeartbeat = Date.now();
    users.set(sessionId, user);
  }
  
  res.json({ success: true });
});

app.get('/poll', (req, res) => {
  const { sessionId } = req.query;
  
  if (sessionId && users.has(sessionId)) {
    const user = users.get(sessionId);
    user.lastHeartbeat = Date.now();
    users.set(sessionId, user);
  }
  
  const userList = Array.from(users.values()).map(u => ({
    username: u.username,
    userId: u.userId
  }));
  
  res.json({ users: userList });
});

app.get('/users', (req, res) => {
  const userList = Array.from(users.values()).map(u => ({
    username: u.username,
    userId: u.userId
  }));
  
  res.json({ 
    count: userList.length,
    users: userList 
  });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`🚀 Server running on port ${PORT}`);
  console.log(`📡 Ready to accept connections from Roblox scripts`);
});
