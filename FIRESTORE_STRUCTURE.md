# Firestore Tuzilmasi (Qadam App)

## 1. `users` (foydalanuvchilar)
```
users (collection)
  └── userId (document)
        ├── name: string
        ├── email: string
        ├── phone: string
        ├── created_at: timestamp
        ├── coins: number
        ├── steps: number
        ├── isAdmin: boolean (adminlar uchun)
        ├── fcmToken: string
        ├── lastTokenUpdate: timestamp
        └── stats (subcollection)
              └── 2024-07-09 (document)
                    ├── steps: number
                    ├── coins: number
                    ├── date: timestamp   
```

---

## 2. `user_challenges` (foydalanuvchi challenge progressi)
```
user_challenges (collection)
  └── userId_challengeId (document)
        ├── userId: string
        ├── challengeId: string
        ├── progress: number (0.0 - 1.0)
        ├── isCompleted: boolean
        ├── rewardClaimed: boolean
```

---

## 3. `challenges` (umumiy challenge’lar)
```
challenges (collection)
  └── challengeId (document)
        ├── title: string
        ├── description: string
        ├── type: string ("daily", "weekly", ...)
        ├── duration: number (kun)
        ├── startDate: timestamp
        ├── endDate: timestamp
        ├── targetSteps: number
        ├── reward: number
        ├── isCompleted: boolean
        ├── progress: number
```

---

## 4. `completed_challenges` (tugallangan challenge’lar)
```
completed_challenges (collection)
  └── documentId (document)
        ├── challenge_id: string
        ├── user_id: string
        ├── user_name: string
        ├── completedAt: timestamp
        ├── value: number (bonus yoki mukofot)
```

---

## 5. `challenge_invites` (do‘stlarni challenge’ga taklif qilish)
```
challenge_invites (collection)
  └── inviteId (document)
        ├── challengeId: string
        ├── inviterId: string
        ├── inviterEmail: string
        ├── friendEmail: string
        ├── status: string ("pending", "accepted", "declined")
```

---

## 6. `referrals` (referral tizimi)
```
referrals (collection)
  └── referralId (document)
        ├── referrerId: string
        ├── referredId: string
        ├── reward: number
        ├── date: timestamp
```

---

## 7. `shop_items` (do‘kon mahsulotlari)
```
shop_items (collection)
  └── itemId (document)
        ├── name: string
        ├── cost: number
        ├── available: boolean
        ├── imageUrl: string
```

---

## 8. `withdraw_requests` (pul yechish so‘rovlari)
```
withdraw_requests (collection)
  └── requestId (document)
        ├── userId: string
        ├── amount: number
        ├── date: timestamp
        ├── status: string ("pending", "approved", "rejected")
```

---

## 9. `transactions` (coin harakatlari va tranzaksiya tarixi)
```
transactions (collection)
  └── transactionId (document)
        ├── userId: string
        ├── type: string ("bonus", "shop", "withdraw", "referral", ...)
        ├── amount: number
        ├── date: timestamp
        ├── description: string
```

---

## 10. `support_chats` (support chat yoki feedback)
```
support_chats (collection)
  └── chatId (document)
        ├── userId: string
        ├── message: string
        ├── isAdmin: boolean
        ├── timestamp: timestamp
        ├── status: string ("open", "closed")
```

---

## 11. `notifications` (push notification logi)
```
notifications (collection)
  └── notificationId (document)
        ├── userId: string
        ├── title: string
        ├── body: string
        ├── type: string
        ├── date: timestamp
        ├── status: string ("delivered", "read")
```

---

## 12. `payments` (to‘lovlar logi, agar kerak bo‘lsa)
```
payments (collection)
  └── paymentId (document)
        ├── userId: string
        ├── amount: number
        ├── provider: string ("Payme", "Click", ...)
        ├── status: string ("pending", "success", "failed")
        ├── date: timestamp
        ├── transactionId: string
```

---

**Izoh:** Sizga kerakli bo‘lgan kolleksiyalarni tanlab, shu tuzilma asosida Firestore’da yaratishingiz mumkin. Har bir kolleksiya uchun CRUD kodini ham yozib bera olaman. 

---

## 1. **Foydalanuvchilar (users) bilan ishlash**

### Firestore’dan userlarni o‘qish (Read)
```dart
import 'package:cloud_firestore/cloud_firestore.dart';

Stream<List<Map<String, dynamic>>> getUsersStream() {
  return FirebaseFirestore.instance
      .collection('users')
      .snapshots()
      .map((snapshot) =>
          snapshot.docs.map((doc) => doc.data()).toList());
}
```

### User qo‘shish (Create)
```dart
Future<void> addUser(String userId, String name, String email) async {
  await FirebaseFirestore.instance.collection('users').doc(userId).set({
    'name': name,
    'email': email,
    'created_at': FieldValue.serverTimestamp(),
    'coins': 0,
    'steps': 0,
    'isAdmin': false,
  });
}
```

### User yangilash (Update)
```dart
Future<void> updateUserCoins(String userId, int coins) async {
  await FirebaseFirestore.instance.collection('users').doc(userId).update({
    'coins': coins,
  });
}
```

### User o‘chirish (Delete)
```dart
Future<void> deleteUser(String userId) async {
  await FirebaseFirestore.instance.collection('users').doc(userId).delete();
}
```

---

## 2. **UI: Foydalanuvchilar ro‘yxatini ko‘rsatish (real-time)**

```dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UsersListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return CircularProgressIndicator();
        final users = snapshot.data!.docs;
        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index].data() as Map<String, dynamic>;
            return ListTile(
              title: Text(user['name'] ?? ''),
              subtitle: Text(user['email'] ?? ''),
              trailing: Text('Coins: ${user['coins'] ?? 0}'),
            );
          },
        );
      },
    );
  }
}
```

---

## 3. **Challenge qo‘shish va ko‘rsatish**

### Challenge qo‘shish
```dart
Future<void> addChallenge(String title, int targetSteps) async {
  await FirebaseFirestore.instance.collection('challenges').add({
   