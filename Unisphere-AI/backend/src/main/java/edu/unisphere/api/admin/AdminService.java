package edu.unisphere.api.admin;

import com.google.cloud.Timestamp;
import com.google.cloud.firestore.DocumentReference;
import com.google.cloud.firestore.DocumentSnapshot;
import com.google.cloud.firestore.Firestore;
import com.google.cloud.firestore.Transaction;
import edu.unisphere.api.security.AuthenticatedUser;
import edu.unisphere.api.security.FirebaseContext;
import java.util.Map;
import java.util.concurrent.TimeUnit;
import org.springframework.stereotype.Service;

@Service
public class AdminService {
    public void resolveRoleRequest(AuthenticatedUser admin, String requestId, boolean approve) throws Exception {
        requireAdmin(admin);
        Firestore db = FirebaseContext.firestore();
        DocumentReference requestRef = db.collection("role_requests").document(requestId);
        DocumentReference auditRef = db.collection("audit_logs").document();
        db.runTransaction((Transaction transaction) -> {
            DocumentSnapshot request = transaction.get(requestRef).get();
            if (!request.exists() || !"PENDING".equals(request.getString("status")))
                throw new IllegalStateException("Role request is no longer pending");
            String uid = request.getString("uid");
            String role = request.getString("requestedRole");
            if (uid == null || !("FACULTY".equals(role) || "CLUB_ADMIN".equals(role)))
                throw new IllegalArgumentException("Invalid role request");
            DocumentReference userRef = db.collection("users").document(uid);
            DocumentSnapshot user = transaction.get(userRef).get();
            if (!user.exists()) throw new IllegalArgumentException("User not found");
            if (approve) transaction.update(userRef, "role", role);
            transaction.update(requestRef, "status", approve ? "APPROVED" : "REJECTED",
                    "reviewedBy", admin.uid(), "reviewedAt", Timestamp.now());
            transaction.create(auditRef, Map.of("actorUid", admin.uid(), "action",
                    approve ? "ROLE_APPROVED" : "ROLE_REJECTED", "targetUid", uid,
                    "requestId", requestId, "createdAt", Timestamp.now()));
            return null;
        }).get(15, TimeUnit.SECONDS);
    }

    public void moderateNote(AuthenticatedUser admin, String noteId, boolean approve) throws Exception {
        requireAdmin(admin);
        Firestore db = FirebaseContext.firestore();
        DocumentReference ref = db.collection("notes").document(noteId);
        DocumentReference auditRef = db.collection("audit_logs").document();
        db.runTransaction((Transaction transaction) -> {
            DocumentSnapshot note = transaction.get(ref).get();
            if (!note.exists() || !"PENDING".equals(note.getString("status")))
                throw new IllegalStateException("Note is no longer pending");
            transaction.update(ref, "status", approve ? "APPROVED" : "REJECTED",
                    "reviewedBy", admin.uid(), "reviewedAt", Timestamp.now());
            transaction.create(auditRef, Map.of("actorUid", admin.uid(), "action",
                    approve ? "NOTE_APPROVED" : "NOTE_REJECTED", "targetId", noteId,
                    "createdAt", Timestamp.now()));
            return null;
        }).get(15, TimeUnit.SECONDS);
    }

    private static void requireAdmin(AuthenticatedUser user) {
        if (!"SUPER_ADMIN".equals(user.role())) throw new SecurityException("Super admin role required");
    }
}
