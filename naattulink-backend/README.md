Every time app push into git hub then clone add this
1. Open your Firebase Console
Go to Firebase Console and select your NaattuLink Firebase project.
Then:
Project Settings ⚙️ → Service accounts → Firebase Admin SDK → Generate new private key
Download the JSON file.
Rename it exactly:
firebase-admin-key.json
Put it directly inside:
naattulink-backend/
├── firebase-admin-key.json
├── package.json
├── ...
⚠️ Do not upload firebase-admin-key.json to GitHub. It contains credentials that can give access to your Firebase project.
2. Open the backend folder
In VS Code, open the:
naattulink-backend
folder.
Then open Terminal → New Terminal.
Run:
npm install
Wait until it finishes.
3. Start the backend
The exact command depends on your package.json. Usually it will be one of:
npm start
or:
npm run dev
If you're not sure, open package.json and look for:
"scripts": {
  ...
}
Important for your EmailJS question
The setup instructions you pasted are for Firebase + your Node/Express backend. They do not contain the EmailJS Public Key.

