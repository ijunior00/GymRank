import { initializeApp } from 'firebase-admin/app';
import { getFirestore, FieldValue, Timestamp } from 'firebase-admin/firestore';
import { getMessaging } from 'firebase-admin/messaging';
import { getStorage } from 'firebase-admin/storage';

initializeApp();

export const db = getFirestore();
export const messaging = getMessaging();
export const storage = getStorage();
export { FieldValue, Timestamp };
