// Firebase Configuration
const firebaseConfig = {
    apiKey: "AIzaSyA3cIrJ-ai68g6B9VdBeWbviHE19VJnth0",
    authDomain: "herenciapos.firebaseapp.com",
    projectId: "herenciapos",
    storageBucket: "herenciapos.appspot.com",
    messagingSenderId: "889871397832",
    appId: "1:889871397832:web:a6c026123f6912813186fd",
    measurementId: "G-053C3LDW20"
};

// Initialize Firebase
firebase.initializeApp(firebaseConfig);
const auth = firebase.auth();
const db = firebase.firestore();

document.addEventListener('DOMContentLoaded', () => {
    const loginForm = document.getElementById('loginForm');
    const errorMessageElement = document.getElementById('errorMessage');

    if (loginForm) {
        loginForm.addEventListener('submit', async (e) => {
            e.preventDefault();
            errorMessageElement.textContent = '';

            const email = document.getElementById('email').value;
            const password = document.getElementById('password').value;

            try {
                await auth.signInWithEmailAndPassword(email, password);
                window.location.href = 'index.html'; 
            } catch (error) {
                console.error("Login error:", error);
                errorMessageElement.textContent = error.message; 
            }
        });
    }

    // Check Auth State
    auth.onAuthStateChanged(user => {
        if (user) {
            console.log("User is signed in:", user);
            if (window.location.pathname.endsWith('login.html') || window.location.pathname.endsWith('/')) {
            }
        } else {
            console.log("User is signed out");
            if (!window.location.pathname.endsWith('login.html') && !window.location.pathname.endsWith('/')) {
            }
        }
    });
});
