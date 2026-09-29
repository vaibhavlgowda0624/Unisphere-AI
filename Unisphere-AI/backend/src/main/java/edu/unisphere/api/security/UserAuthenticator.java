package edu.unisphere.api.security;

import com.google.cloud.firestore.DocumentSnapshot;
import com.google.firebase.auth.FirebaseToken;
import java.util.concurrent.TimeUnit;
import org.springframework.stereotype.Service;

@Service
public class UserAuthenticator {
    public AuthenticatedUser authenticate(String token) throws Exception {
        FirebaseToken verified = FirebaseContext.auth().verifyIdToken(token, true);
        if (!verified.isEmailVerified()) throw new SecurityException("Email not verified");
        DocumentSnapshot profile = FirebaseContext.firestore().collection("users")
                .document(verified.getUid()).get().get(10, TimeUnit.SECONDS);
        if (!profile.exists() || Boolean.TRUE.equals(profile.getBoolean("suspended")))
            throw new SecurityException("User unavailable");
        String role = profile.getString("role");
        if (role == null) throw new SecurityException("Role unavailable");
        return new AuthenticatedUser(verified.getUid(), role);
    }
}
