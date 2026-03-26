/* eslint-disable no-undef */
importScripts('https://www.gstatic.com/firebasejs/10.14.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.14.1/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyAmxlXfzT1vQDYYvw_XE0XV406ju3vbEzs',
  authDomain: 'smart-life-17183.firebaseapp.com',
  projectId: 'smart-life-17183',
  storageBucket: 'smart-life-17183.firebasestorage.app',
  messagingSenderId: '179357566644',
  appId: '1:179357566644:web:85abd07ce4437450a339e1',
  measurementId: 'G-NKLMBZQ6K1',
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  const title = payload.notification?.title || 'SmartLife';
  const options = {
    body: payload.notification?.body || 'Ban co thong bao moi.',
    data: payload.data || {},
  };
  self.registration.showNotification(title, options);
});
