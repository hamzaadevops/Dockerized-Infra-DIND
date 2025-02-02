const express = require('express');
const session = require('express-session');
const bcrypt = require('bcrypt');
const sqlite3 = require('sqlite3').verbose();
const path = require('path');
const {exec} = require('child_process');
const initializeDatabase = require('./config/db-init');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3001;

// Initialize the database
initializeDatabase();

// Middleware
app.use(express.json());
app.use(express.urlencoded({extended: true}));
app.use(
  session({
    secret: 'your-secret-key',
    resave: false,
    saveUninitialized: true,
  })
);
app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));

// SQLite database
const db = new sqlite3.Database('auth.db');

// Middleware to check if user is logged in
function isAuthenticated(req, res, next) {
  if (req.session.user) {
    return next();
  }
  res.redirect('/login');
}

// Login route
app.get('/login', (req, res) => {
  res.render('login', {error: null});
});

app.post('/login', (req, res) => {
  const {username, password} = req.body;

  db.get(`SELECT * FROM users WHERE username = ?`, [username], (err, user) => {
    if (err) {
      return res.render('login', {error: 'An error occurred. Try again.'});
    }
    if (!user || !bcrypt.compareSync(password, user.password)) {
      return res.render('login', {error: 'Invalid username or password.'});
    }

    // Set session and redirect
    req.session.user = {id: user.id, username: user.username};
    res.redirect('/');
  });
});

// Logout route
app.get('/logout', (req, res) => {
  req.session.destroy();
  res.redirect('/login');
});

// Home route (protected)
app.get('/', isAuthenticated, (req, res) => {
  res.render('index', {
    output: null,
    error: null,
    portainerUrl: process.env.PORTAINER_URL,
    traefikUrl: process.env.TRAEFIK_URL,
  });
});

// Change username/password
app.get('/change-credentials', isAuthenticated, (req, res) => {
  // Passing success and error messages to the view
  res.render('change-credentials', {
    successMessage: req.session.successMessage,
    errorMessage: req.session.errorMessage,
  });

  // Clear the messages after rendering
  delete req.session.successMessage;
  delete req.session.errorMessage;
});

app.post('/change-credentials', isAuthenticated, (req, res) => {
  const {newUsername, newPassword} = req.body;

  const hashedPassword = bcrypt.hashSync(newPassword, 10);
  db.run(
    `UPDATE users SET username = ?, password = ? WHERE id = ?`,
    [newUsername, hashedPassword, req.session.user.id],
    (err) => {
      if (err) {
        req.session.errorMessage = 'Failed to update credentials.';
        return res.redirect('/change-credentials');
      }
      req.session.user.username = newUsername;
      req.session.successMessage = 'Credentials updated successfully!';
      res.redirect('/change-credentials');
    }
  );
});

app.post('/change-credentials', isAuthenticated, (req, res) => {
  const {newUsername, newPassword} = req.body;

  const hashedPassword = bcrypt.hashSync(newPassword, 10);
  db.run(
    `UPDATE users SET username = ?, password = ? WHERE id = ?`,
    [newUsername, hashedPassword, req.session.user.id],
    (err) => {
      if (err) {
        return res.render('change-credentials', {
          error: 'Failed to update credentials.',
        });
      }
      req.session.user.username = newUsername;
      res.redirect('/');
    }
  );
});

// Deploy application route (protected)
app.post('/deploy-app',  (req, res) => {
  const {appName, subDomain, appPort, imageName} = req.body;
  let isAddChatApp = req.body.isAddChatApp;

  if (!isAddChatApp) {
    isAddChatApp = 'false';
  }

  console.log('Request body:', req.body); // Log the incoming request body
  console.log('Parsed parameters:', {
    appName,
    subDomain,
    appPort,
    imageName,
    isAddChatApp,
  }); // Log parsed params

  if (!appName || !subDomain || !appPort || !imageName) {
    console.log('Validation failed: Missing required fields.'); // Log validation failure
    return res.render('index', {
      output: null,
      error: 'All fields are required.',
      portainerUrl: process.env.PORTAINER_URL,
      traefikUrl: process.env.TRAEFIK_URL,
    });
  }

  // Escape values to prevent injection
  const escapedAppName = appName.replace(/[^a-zA-Z0-9-_]/g, '');
  const escapedSubDomain = subDomain.replace(/[^a-zA-Z0-9-.]/g, '');
  const escapedAppPort = parseInt(appPort, 10);
  const escapedImageName = imageName.replace(/[^a-zA-Z0-9-_:/.]/g, '');
  const addChatAppFlag = isAddChatApp === 'true' ? 'true' : 'false';

  console.log('Escaped parameters:', {
    escapedAppName,
    escapedSubDomain,
    escapedAppPort,
    escapedImageName,
    addChatAppFlag,
  }); // Log escaped params

  // Construct the script command
  const command = `./scripts/deploy-app.sh --appName=${escapedAppName} --subDomain=${escapedSubDomain} --appPort=${escapedAppPort} --imageName=${escapedImageName} ${
    addChatAppFlag === 'true' ? '--addChatApp' : ''
  }`;

  console.log('Constructed command:', command); // Log the command to be executed

  // Execute the script
  exec(command, (error, stdout, stderr) => {
    if (error) {
      console.error('Command execution error:', error); // Log the error
      console.error('Command stderr:', stderr); // Log standard error
      return res.render('index', {
        output: null,
        error: 'Failed to deploy.',
        portainerUrl: process.env.PORTAINER_URL,
        traefikUrl: process.env.TRAEFIK_URL,
      });
    }
    console.log('Command stdout:', stdout); // Log the standard output
    res.render('index', {
      output: stdout,
      error: null,
      portainerUrl: process.env.PORTAINER_URL,
      traefikUrl: process.env.TRAEFIK_URL,
    });
  });
});

// Start the server
app.listen(PORT, () => {
  console.log(`Server running at http://localhost:${PORT}`);
});
