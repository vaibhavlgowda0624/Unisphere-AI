package edu.unisphere.api.admin;

import edu.unisphere.api.security.FirebaseContext;
import java.util.concurrent.TimeUnit;

/** Explicit one-time administrator provisioning from a trusted developer shell. */
public final class BootstrapSuperAdmin {
    private BootstrapSuperAdmin() {}
    public static void main(String[] args) throws Exception {
        if (!"true".equals(System.getenv("ALLOW_ADMIN_BOOTSTRAP")))
            throw new SecurityException("Set ALLOW_ADMIN_BOOTSTRAP=true for this one-time command");
        String uid = System.getenv("BOOTSTRAP_SUPER_ADMIN_UID");
        if (uid == null || uid.isBlank()) throw new IllegalArgumentException("BOOTSTRAP_SUPER_ADMIN_UID is required");
        var user = FirebaseContext.auth().getUser(uid);
        if (!user.isEmailVerified()) throw new SecurityException("Administrator email must be verified");
        var ref = FirebaseContext.firestore().collection("users").document(uid);
        if (!ref.get().get(10, TimeUnit.SECONDS).exists()) throw new IllegalArgumentException("Profile not found");
        ref.update("role", "SUPER_ADMIN").get(10, TimeUnit.SECONDS);
        System.out.println("Super admin assigned to UID " + uid);
    }
}
