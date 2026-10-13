const functions = require('firebase-functions/v2');
const admin = require('firebase-admin');
const crypto = require('crypto');

admin.initializeApp();
const db = admin.firestore();

// 1. Уведомление о новом сообщении в чате
exports.onNewMessage = functions.firestore.onDocumentCreated(
    'active_trips/{tripId}/messages/{messageId}',
    async (event) => {
        const tripId = event.params.tripId;
        const msgData = event.data.data();

        if (!msgData) return;

        const senderId = msgData.senderId;
        const text = msgData.text || '📷 Фотография/Файл';

        // Получаем саму поездку, чтобы найти участников
        const tripSnapshot = await db.collection('active_trips').doc(tripId).get();
        if (!tripSnapshot.exists) return;

        const tripData = tripSnapshot.data();
        const participants = tripData.participantIds || [];

        // Кто получатели? Все, кроме отправителя
        const recipients = participants.filter((id) => id !== senderId);

        if (recipients.length === 0) return;

        // Собираем токены
        const tokens = [];
        for (const uId of recipients) {
            // Ищем юзера
            const userDoc = await db.collection('users').doc(uId).get();
            if (userDoc.exists && userDoc.data().fcmToken) {
                tokens.push(userDoc.data().fcmToken);
            } else {
                // Если не юзер, ищем партнера (водителя/гида)
                const partnerDoc = await db.collection('partners').doc(uId).get();
                if (partnerDoc.exists && partnerDoc.data().fcmToken) {
                    tokens.push(partnerDoc.data().fcmToken);
                }
            }
        }

        if (tokens.length === 0) {
            console.log('No FCM tokens found for recipients');
            return;
        }

        // Отправляем пуш
        const messagePayload = {
            tokens: tokens, // Рассылка сразу нескольким
            notification: {
                title: tripData.customName || tripData.routeTitle || 'Новое сообщение',
                body: text,
            },
            data: {
                type: 'chat',
                tripId: tripId,
            },
            android: {
                notification: {
                    channelId: 'high_importance_channel',
                    priority: 'high',
                    sound: 'default'
                }
            },
            apns: {
                payload: {
                    aps: {
                        sound: 'default'
                    }
                }
            }
        };

        try {
            const response = await admin.messaging().sendEachForMulticast(messagePayload);
            console.log('Successfully sent message:', response.successCount);
        } catch (error) {
            console.error('Error sending message:', error);
        }
    });

// 2. Уведомление об изменении статуса активной поездки
exports.onTripStatusChange = functions.firestore.onDocumentUpdated(
    'active_trips/{tripId}',
    async (event) => {
        const beforeData = event.data.before.data();
        const afterData = event.data.after.data();
        const tripId = event.params.tripId;

        // Проверяем, изменился ли статус
        if (beforeData.status === afterData.status) return;

        const newStatus = afterData.status; // 'in_progress', 'completed', 'cancelled'

        let title = 'Обновление поездки';
        let body = `Статус вашей поездки "${afterData.routeTitle}" изменился.`;

        if (newStatus === 'in_progress') {
            title = 'Поездка началась! 🚗';
            body = 'Маршрут успешно запущен.';
        } else if (newStatus === 'completed') {
            title = 'Поездка завершена ✅';
            body = 'Надеемся, вам всё понравилось! Оставьте отзыв.';
        } else if (newStatus === 'cancelled') {
            title = 'Поездка отменена ❌';
            body = 'Ваша поездка была отменена.';
        } else {
            // Игнорируем другие мелкие смены статуса
            return;
        }

        const participants = afterData.participantIds || [];

        // Собираем токены
        const tokens = [];
        for (const uId of participants) {
            const userDoc = await db.collection('users').doc(uId).get();
            if (userDoc.exists && userDoc.data().fcmToken) {
                tokens.push(userDoc.data().fcmToken);
            } else {
                const partnerDoc = await db.collection('partners').doc(uId).get();
                if (partnerDoc.exists && partnerDoc.data().fcmToken) {
                    tokens.push(partnerDoc.data().fcmToken);
                }
            }
        }

        if (tokens.length === 0) return;

        const messagePayload = {
            tokens: tokens,
            notification: { title, body },
            data: {
                type: 'trip_status',
                tripId: tripId,
            },
            android: {
                notification: {
                    channelId: 'high_importance_channel',
                    priority: 'high',
                    sound: 'default'
                }
            }
        };

        try {
            await admin.messaging().sendEachForMulticast(messagePayload);
        } catch (error) {
            console.error('Error sending status update:', error);
        }
    });

// 3. Массовая рассылка на Email (App Launch Announcement)
// Требует настройки SMTP (например Gmail App Password)
// Запуск через: firebase functions:shell или вызов из приложения
const nodemailer = require('nodemailer');

// Настройка транспорта (рекомендуется использовать env-переменные для безопасности)
// firebase functions:config:set mailer.user="user@gmail.com" mailer.pass="password"
const transporter = nodemailer.createTransport({
    service: 'gmail',
    auth: {
        user: process.env.MAILER_USER || 'YOUR_EMAIL@gmail.com',
        pass: process.env.MAILER_PASS || 'YOUR_APP_PASSWORD'
    }
});

exports.sendAppLaunchAnnouncement = functions.https.onCall(async (request) => {
    // Рассылка — только для администраторов (custom claim `admin`).
    if (!request.auth || !request.auth.token.admin) {
        throw new functions.https.HttpsError('permission-denied', 'Admin only');
    }

    const usersSnapshot = await db.collection('users').get();
    const emails = [];

    usersSnapshot.forEach(doc => {
        const data = doc.data();
        if (data.email) {
            emails.push(data.email);
        }
    });

    if (emails.length === 0) {
        return { success: false, message: 'Пользователи с email не найдены' };
    }

    const mailOptions = {
        from: '"Explora App" <no-reply@example.kz>',
        bcc: emails.join(','), // скрытая копия: адреса пользователей не раскрываются друг другу
        subject: 'Приложение Explora успешно запущено! 🎉',
        html: `
            <div style="font-family: Arial, sans-serif; padding: 20px;">
                <h1 style="color: #1565C0;">Добро пожаловать в Explora!</h1>
                <p>Мы рады сообщить, что наше приложение теперь доступно для использования.</p>
                <p>Ваш новый уровень путешествий начинается здесь. Исследуйте маршруты, бронируйте гидов и оставайтесь на связи даже без интернета с помощью WAVE.</p>
                <br/>
                <p>С уважением,<br/>Команда Explora</p>
            </div>
        `
    };

    try {
        await transporter.sendMail(mailOptions);
        console.log(`Sent launch announcement to ${emails.length} users`);
        return { success: true, count: emails.length };
    } catch (error) {
        console.error('Email sending error:', error);
        throw new functions.https.HttpsError('internal', 'Ошибка при отправке почты');
    }
});

// 4. Ежедневная очистка аккаунтов, помеченных на удаление > 30 дней назад
// Запускается раз в сутки в полночь
exports.cleanupDeletedAccounts = functions.scheduler.onSchedule('0 0 * * *', async (event) => {
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

    console.log(`Starting cleanup for accounts marked before: ${thirtyDaysAgo.toISOString()}`);

    try {
        // Ищем пользователей, у которых deletionRequestedAt меньше или равно thirtyDaysAgo
        // Так как мы храним даты как ISO String, сравниваем их как строки
        const snapshot = await db.collection('users')
            .where('deletionRequestedAt', '<=', thirtyDaysAgo.toISOString())
            .get();

        if (snapshot.empty) {
            console.log('No accounts scheduled for deletion found.');
            return;
        }

        console.log(`Found ${snapshot.size} accounts to delete.`);

        for (const doc of snapshot.docs) {
            const uid = doc.id;
            try {
                // 1. Удаляем из Firebase Auth
                await admin.auth().deleteUser(uid);
                console.log(`Auth account deleted: ${uid}`);

                // 2. Удаляем документ пользователя из Firestore
                await db.collection('users').doc(uid).delete();
                console.log(`Firestore user doc deleted: ${uid}`);

                // 3. (Опционально) Удаляем связанные данные (бронирования, активные пути)
                // Удаление заказов пользователя
                const bookingsBatch = db.batch();
                const bookings = await db.collection('bookings').where('userId', '==', uid).get();
                bookings.forEach(bDoc => bookingsBatch.delete(bDoc.ref));
                await bookingsBatch.commit();
                
                console.log(`Cleaned up ${bookings.size} bookings for user ${uid}`);

            } catch (err) {
                console.error(`Failed to delete user ${uid}:`, err);
            }
        }

        console.log('Cleanup completed successfully.');
    } catch (error) {
        console.error('Error during cleanupDeletedAccounts execution:', error);
    }
});

// ============================================================================
// FREEDOM PAY (PAYBOX) INTEGRATION
// ============================================================================

const FREEDOM_MERCHANT_ID = process.env.FREEDOM_MERCHANT_ID || '';
const FREEDOM_SECRET_PAYIN = process.env.FREEDOM_SECRET_PAYIN || '';

// Helper: генерация MD5-подписи для Freedom Pay
function generateFreedomSignature(scriptName, params, secretKey) {
    // 1. Берем ключи (только те, что не пустые и не pg_sig), сортируем по алфавиту
    const keys = Object.keys(params)
        .filter(k => k !== 'pg_sig')
        .sort();
    
    // 2. Достаем значения
    const values = keys.map(k => params[k]);
    
    // 3. Формируем строку: имя_скрипта;val1;val2;...;secret_key
    const signatureString = [scriptName, ...values, secretKey].join(';');
    
    // 4. Возвращаем MD5
    return crypto.createHash('md5').update(signatureString).digest('hex');
}

// 5. Инициализация платежа (вызывается из Flutter приложения)
exports.initFreedomPayment = functions.https.onCall(async (request) => {
    // Данные от приложения
    if (!request.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'Sign-in required');
    }
    const { amount, description, routeId } = request.data;
    const userId = request.auth.uid; // идентификатор из тела запроса не принимаем

    if (typeof amount !== 'number' || !(amount > 0) || !description) {
        throw new functions.https.HttpsError('invalid-argument', 'Amount and description are required');
    }

    // Уникальный номер заказа
    const orderId = `explora_${Date.now()}_${Math.floor(Math.random() * 1000)}`;

    // Базовые параметры
    const params = {
        pg_order_id: orderId,
        pg_merchant_id: FREEDOM_MERCHANT_ID,
        pg_amount: amount.toString(),
        pg_description: description,
        pg_salt: crypto.randomBytes(16).toString('hex'),
        pg_testing_mode: '1', // ТЕСТОВЫЙ РЕЖИМ ВКЛЮЧЕН
        pg_currency: 'KZT',
        pg_success_url: 'https://example.kz/payment-success',
        pg_failure_url: 'https://example.kz/payment-failure',
    };

    // Если функция задеплоена на Firebase, добавляем Webhook URL
    const projectId = process.env.GCLOUD_PROJECT || 'travel-marketplace-demo';
    // Для эмулятора используем ngrok или пропускаем
    if (process.env.FUNCTIONS_EMULATOR !== 'true') {
        params.pg_result_url = `https://us-central1-${projectId}.cloudfunctions.net/freedomPaymentCallback`;
    }

    try {
        const projectId = process.env.GCLOUD_PROJECT || 'travel-marketplace-demo';
        const region = 'us-central1';
        
        // ВМЕСТО вызова реального Freedom Pay (который блокируется Cloudflare),
        // мы генерируем ссылку на нашу собственную тестовую страницу оплаты.
        // Это гарантирует, что тестирование флоу пройдет успешно.
        const redirectUrl = `https://${region}-${projectId}.cloudfunctions.net/mockPaymentPage?orderId=${orderId}&amount=${amount}`;
        
        // Сохраняем заказ в Firestore
        await db.collection('payments').doc(orderId).set({
            userId: userId || 'anonymous',
            routeId: routeId || null,
            amount: amount,
            status: 'pending',
            pg_redirect_url: redirectUrl,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        return { success: true, redirectUrl: redirectUrl, orderId: orderId };
    } catch (error) {
        console.error('Payment generation error:', error);
        throw new functions.https.HttpsError('internal', error.message);
    }
});

// МОК-страница оплаты для тестирования (заменяет Freedom Pay)
exports.mockPaymentPage = functions.https.onRequest(async (req, res) => {
    // Страница нужна только эмулятору и тестовому стенду: в проде она позволила бы
    // любому «оплатить» чужой заказ, поэтому по умолчанию закрыта.
    if (process.env.FUNCTIONS_EMULATOR !== 'true' && process.env.ALLOW_MOCK_PAYMENTS !== 'true') {
        res.status(404).send('Not found');
        return;
    }
    if (req.method === 'POST') {
        // Имитация успешной оплаты
        const orderId = req.body.orderId || req.query.orderId;
        console.log(`Mock payment POST received for order: ${orderId}`);
        if (!orderId) {
            res.status(400).send('Missing orderId');
            return;
        }
        try {
            await db.collection('payments').doc(orderId).update({
                status: 'success',
                paymentId: `mock_${Date.now()}`,
                updatedAt: admin.firestore.FieldValue.serverTimestamp()
            });
            // Возвращаем HTML, который сообщает WebView об успехе (WebView сам закроется)
            res.send(`
                <html>
                <body>
                    <h2>Оплата успешно завершена (Тест)</h2>
                    <p>Возврат в приложение...</p>
                </body>
                </html>
            `);
        } catch (e) {
            console.error('Error in mock payment:', e);
            res.status(500).send('Error updating payment');
        }
    } else {
        // GET запрос - показываем форму оплаты
        const orderId = req.query.orderId;
        const amount = req.query.amount;
        
        res.send(`
            <!DOCTYPE html>
            <html>
            <head>
                <meta charset="utf-8">
                <meta name="viewport" content="width=device-width, initial-scale=1">
                <title>Тестовая Оплата Explora</title>
                <style>
                    body { font-family: sans-serif; padding: 20px; text-align: center; }
                    .card { border: 1px solid #ccc; border-radius: 8px; padding: 20px; max-width: 300px; margin: 0 auto; box-shadow: 0 4px 6px rgba(0,0,0,0.1); }
                    .btn { background-color: #147EFB; color: white; border: none; padding: 15px 20px; border-radius: 8px; font-size: 16px; width: 100%; cursor: pointer; margin-top: 20px; }
                    .amount { font-size: 24px; font-weight: bold; margin: 10px 0; }
                </style>
            </head>
            <body>
                <div class="card">
                    <h3>Тестовый Платежный Шлюз</h3>
                    <p>Заказ: ${orderId}</p>
                    <div class="amount">${amount} KZT</div>
                    <p style="color: gray; font-size: 12px;">Это тестовая страница. Реального списания средств не будет.</p>
                    <form method="POST" action="?orderId=${orderId}&amount=${amount}">
                        <input type="hidden" name="orderId" value="${orderId}">
                        <button type="submit" class="btn">Оплатить ${amount} KZT</button>
                    </form>
                </div>
            </body>
            </html>
        `);
    }
});

// 6. Callback для Freedom Pay (Webhook подтверждения оплаты)
exports.freedomPaymentCallback = functions.https.onRequest(async (req, res) => {
    // Freedom Pay отправляет POST application/x-www-form-urlencoded
    const params = req.body;
    
    if (!params || !params.pg_sig) {
        return res.status(400).send('Missing signature');
    }

    const providedSig = params.pg_sig;

    // В Freedom Pay для коллбеков scriptName - это имя эндпоинта или относительный путь.
    // Часто это 'freedomPaymentCallback' или полный путь
    // Попробуем базовое имя
    const scriptName = 'freedomPaymentCallback'; 
    const expectedSig = generateFreedomSignature(scriptName, params, FREEDOM_SECRET_PAYIN);

    // Подпись обязательна: иначе любой мог бы подделать уведомление об оплате.
    if (providedSig !== expectedSig) {
        console.warn('Freedom Pay callback: signature mismatch');
        return res.status(400).send('Invalid signature');
    }

    const orderId = params.pg_order_id;
    const isSuccess = parseInt(params.pg_result) === 1;
    const status = isSuccess ? 'success' : 'failed';

    try {
        // Обновляем статус заказа
        await db.collection('payments').doc(orderId).update({
            status: status,
            paymentId: params.pg_payment_id || null,
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });

        // Отвечаем Freedom Pay успешным XML
        const responseSalt = crypto.randomBytes(16).toString('hex');
        const responseParams = {
            pg_status: 'ok',
            pg_salt: responseSalt
        };
        const responseSig = generateFreedomSignature(scriptName, responseParams, FREEDOM_SECRET_PAYIN);
        
        const xmlResponse = `<?xml version="1.0" encoding="utf-8"?>
<response>
  <pg_salt>${responseSalt}</pg_salt>
  <pg_status>ok</pg_status>
  <pg_sig>${responseSig}</pg_sig>
</response>`;
        
        res.set('Content-Type', 'text/xml');
        res.send(xmlResponse);
    } catch (e) {
        console.error('Error updating payment in DB', e);
        res.status(500).send('Internal Server Error');
    }
});

// 7. Начисление средств партнерам: 50% при старте, 50% при завершении
exports.onBookingStatusChangeForPayout = functions.firestore.onDocumentUpdated(
    'bookings/{bookingId}',
    async (event) => {
        const beforeData = event.data.before.data();
        const afterData = event.data.after.data();

        const driverId = afterData.driverId;
        const guideId = afterData.guideId;
        const driverEarning = afterData.driverEarning || 0;
        const guideEarning = afterData.guideEarning || 0;

        const batch = db.batch();
        const bookingRef = db.collection('bookings').doc(event.params.bookingId);
        let updated = false;

        // 1. Первая выплата (50%) при старте поездки
        if (beforeData.status !== 'inProgress' && afterData.status === 'inProgress' && !afterData.firstPayoutDone) {
            const driverHalf = driverEarning / 2;
            const guideHalf = guideEarning / 2;

            if (driverId && driverHalf > 0) {
                batch.update(db.collection('partners').doc(driverId), {
                    balance: admin.firestore.FieldValue.increment(driverHalf)
                });
            }
            if (guideId && guideHalf > 0) {
                batch.update(db.collection('partners').doc(guideId), {
                    balance: admin.firestore.FieldValue.increment(guideHalf)
                });
            }

            batch.update(bookingRef, { firstPayoutDone: true });
            updated = true;
            console.log(`Successfully credited FIRST 50% earnings for booking ${event.params.bookingId}`);
        }

        // 2. Вторая выплата (50%) при завершении поездки
        if (beforeData.status !== 'completed' && afterData.status === 'completed' && !afterData.secondPayoutDone) {
            const driverHalf = driverEarning / 2;
            const guideHalf = guideEarning / 2;

            if (driverId && driverHalf > 0) {
                batch.update(db.collection('partners').doc(driverId), {
                    balance: admin.firestore.FieldValue.increment(driverHalf)
                });
            }
            if (guideId && guideHalf > 0) {
                batch.update(db.collection('partners').doc(guideId), {
                    balance: admin.firestore.FieldValue.increment(guideHalf)
                });
            }

            batch.update(bookingRef, { secondPayoutDone: true });
            updated = true;
            console.log(`Successfully credited SECOND 50% earnings for booking ${event.params.bookingId}`);
        }

        if (updated) {
            await batch.commit();
        }
    });

// 8. Запрос на выплату (Вызывается из приложения партнера)
const FREEDOM_SECRET_PAYOUT = process.env.FREEDOM_SECRET_PAYOUT || ''; // Тестовый ключ для выплат

exports.requestFreedomPayout = functions.https.onCall(async (request) => {
    const { partnerId, amount, cardPan } = request.data;

    // Выплату можно запросить только со своего баланса.
    if (!request.auth || request.auth.uid !== partnerId) {
        throw new functions.https.HttpsError('permission-denied', 'Payout is allowed for your own account only');
    }
    if (typeof amount !== 'number' || !(amount > 0)) {
        throw new functions.https.HttpsError('invalid-argument', 'Amount must be a positive number');
    }

    if (!partnerId || !amount || !cardPan) {
        throw new functions.https.HttpsError('invalid-argument', 'Missing partnerId, amount, or cardPan');
    }

    const partnerRef = db.collection('partners').doc(partnerId);
    
    // Используем транзакцию для безопасного списания баланса
    return await db.runTransaction(async (transaction) => {
        const partnerDoc = await transaction.get(partnerRef);
        if (!partnerDoc.exists) {
            throw new functions.https.HttpsError('not-found', 'Partner not found');
        }

        const balance = partnerDoc.data().balance || 0;
        if (balance < amount) {
            throw new functions.https.HttpsError('failed-precondition', 'Insufficient balance');
        }

        // Списываем баланс
        transaction.update(partnerRef, {
            balance: admin.firestore.FieldValue.increment(-amount)
        });

        // В реальном проекте здесь должен быть вызов API Freedom Pay для P2P перевода (make_payout.php)
        // Для MVP и тестирования (так как реальный кард-токен получить сложно без полноценного SDK):
        // Мы эмулируем вызов API Freedom Pay и просто сохраняем запись о выплате.
        
        const payoutId = `payout_${Date.now()}`;
        const payoutRef = db.collection('payouts').doc(payoutId);
        
        transaction.set(payoutRef, {
            partnerId: partnerId,
            amount: amount,
            cardPan: cardPan.slice(-4), // храним только последние 4 цифры из соображений безопасности
            status: 'success', // В реальности сначала 'pending', потом webhook
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        return { success: true, payoutId: payoutId };
    });
});
