/**
 * Liminal — Cloud Functions
 *
 * 1. onUserCreate  — server-side role validation on signup. Prevents clients
 *    from escalating their own role.  @yvl.dev emails are auto-upgraded to
 *    'developer'; @ulk.ac.rw emails may be 'rep'; everything else is 'student'.
 *
 * 2. onBroadcastWrite — verifies the caller's role before allowing a broadcast
 *    document to be committed.  Rejects writes from non-rep / non-developer
 *    accounts and enforces a per-user rate limit (5 broadcasts / hour).
 *
 * 3. onBroadcastCreate — pushes a notification to every student whose
 *    department matches the chosen audience (or all students for 'All dept.'),
 *    skipping the author's own device.
 *
 * Requires the Firebase Blaze (pay-as-you-go) plan + an APNs push key in the
 * Firebase console for iOS delivery.
 */

const { onDocumentCreated, onDocumentWritten } = require('firebase-functions/v2/firestore');
const { logger } = require('firebase-functions');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');

initializeApp();

// ── Constants ────────────────────────────────────────────────────────────────

const DEV_EMAIL_DOMAIN = '@yvl.dev';
const REP_EMAIL_DOMAIN = '@ulk.ac.rw';
const BROADCAST_RATE_LIMIT = 5;       // max broadcasts per window
const RATE_WINDOW_MS = 60 * 60 * 1000; // 1 hour

// ── 1. onUserCreate ─────────────────────────────────────────────────────────
// Triggered when a new user document is created by the client at signup.
// Corrects the role based on the email domain and deletes the doc if the
// client tries to set 'developer' directly (only the server can do that).

exports.onUserCreate = onDocumentWritten(
  'users/{userId}',
  async (event) => {
    const change = event.data;
    if (!change) return;

    // Only fire on creates, not updates.
    if (change.before.exists) return;

    const after = change.after.data();
    if (!after) return;

    const userId = event.params.userId;
    const email = String(after.email || '').trim().toLowerCase();
    const clientRole = String(after.role || 'student');

    let correctRole = 'student';

    if (email.endsWith(DEV_EMAIL_DOMAIN)) {
      correctRole = 'developer';
    } else if (email.endsWith(REP_EMAIL_DOMAIN)) {
      // Only allow 'rep' if the client set it; otherwise default to student.
      correctRole = clientRole === 'rep' ? 'rep' : 'student';
    }

    // If the role is already correct, nothing to do.
    if (clientRole === correctRole) {
      logger.info('User created with correct role', { userId, role: correctRole });
      return;
    }

    // Overwrite the role with the server-validated value.
    await getFirestore().collection('users').doc(userId).update({
      role: correctRole,
    });

    logger.info('Role corrected on user creation', {
      userId,
      clientRole,
      correctedRole: correctRole,
    });
  },
);

// ── 2. onBroadcastWrite ──────────────────────────────────────────────────────
// Validates that the broadcast author has rep or developer role BEFORE the
// document is committed.  Also enforces a per-user rate limit to prevent spam.

exports.onBroadcastWrite = onDocumentWritten(
  'broadcast/{docId}',
  async (event) => {
    const change = event.data;
    if (!change) return;

    // Only validate creates.
    if (change.before.exists) return;

    const after = change.after.data();
    if (!after) return;

    const authorUid = String(after.uid || '');
    const docId = event.params.docId;

    if (!authorUid) {
      logger.warn('Broadcast missing uid — deleting', { docId });
      await getFirestore().collection('broadcast').doc(docId).delete();
      return;
    }

    // Look up the author's role.
    const userDoc = await getFirestore().collection('users').doc(authorUid).get();
    if (!userDoc.exists) {
      logger.warn('Broadcast author not found — deleting', { docId, authorUid });
      await getFirestore().collection('broadcast').doc(docId).delete();
      return;
    }

    const role = userDoc.data()?.role;
    if (role !== 'rep' && role !== 'developer') {
      logger.warn('Broadcast from non-rep — deleting', { docId, authorUid, role });
      await getFirestore().collection('broadcast').doc(docId).delete();
      return;
    }

    // Rate limit: count broadcasts in the last hour for this author.
    const oneHourAgo = new Date(Date.now() - RATE_WINDOW_MS);
    const recentBroadcasts = await getFirestore()
      .collection('broadcast')
      .where('uid', '==', authorUid)
      .where('createdAt', '>=', oneHourAgo)
      .get();

    if (recentBroadcasts.size > BROADCAST_RATE_LIMIT) {
      logger.warn('Broadcast rate limit exceeded — deleting', {
        docId,
        authorUid,
        recentCount: recentBroadcasts.size,
      });
      await getFirestore().collection('broadcast').doc(docId).delete();
      return;
    }

    logger.info('Broadcast authorized', { docId, authorUid, role });
  },
);

// ── 3. onBroadcastCreate (push notifications) ────────────────────────────────
// After the broadcast doc is validated and committed, push a notification to
// matching users.

exports.onBroadcastCreate = onDocumentCreated(
  'broadcast/{docId}',
  async (event) => {
    const data = event.data?.data();
    if (!data) return;

    const title = String(data.title || 'New task update');
    const body = data.urgency === 'Urgent'
      ? `Urgent: ${title}`
      : title;
    const source = String(data.source || 'Liminal');
    const audience = String(data.audience || '');
    const authorUid = String(data.uid || '');

    // Resolve target users. 'All dept.' (and empty) reach everyone; specific
    // audiences match by the department string stored on the user's profile.
    let query = getFirestore().collection('users');
    if (audience !== 'All dept.' && audience !== '') {
      query = query.where('department', '==', audience);
    }
    const snap = await query.get();

    const tokens = snap.docs
      .filter((doc) => doc.id !== authorUid)
      .map((doc) => doc.data().fcmToken)
      .filter((token) => typeof token === 'string' && token.length > 0);

    if (tokens.length === 0) {
      logger.info('No FCM tokens matched broadcast audience', { audience });
      return;
    }

    const response = await getMessaging().sendEachForMulticast({
      tokens,
      notification: {
        title: source,
        body,
      },
      data: {
        type: 'broadcast',
        docId: event.params.docId,
      },
      apns: {
        payload: {
          aps: { sound: 'default' },
        },
      },
      android: {
        priority: 'high',
        notification: {
          channelId: 'task_reminders',
        },
      },
    });

    logger.info('Broadcast push sent', {
      tokens: tokens.length,
      success: response.successCount,
      failure: response.failureCount,
    });

    // Prune tokens the driver reports as dead so we don't retry them forever.
    const deadTokens = [];
    response.responses.forEach((result, i) => {
      if (result.messageId) return;
      const code = result.error?.code;
      if (
        code === 'messaging/registration-token-not-registered' ||
        code === 'messaging/invalid-registration-token'
      ) {
        deadTokens.push(tokens[i]);
      }
    });

    if (deadTokens.length > 0) {
      const db = getFirestore();
      const batch = db.batch();
      for (const token of deadTokens) {
        const hit = snap.docs.find((doc) => doc.data().fcmToken === token);
        if (hit) {
          batch.update(db.collection('users').doc(hit.id), {
            fcmToken: FieldValue.delete(),
          });
        }
      }
      await batch.commit();
      logger.info('Pruned stale FCM tokens', { count: deadTokens.length });
    }
  },
);
