package edu.unisphere.api.security;

import com.google.auth.oauth2.AccessToken;
import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import com.google.firebase.auth.FirebaseAuth;
import com.google.cloud.firestore.Firestore;
import com.google.firebase.cloud.FirestoreClient;
import java.io.IOException;
import java.util.Date;

public final class FirebaseContext {
    private static FirebaseApp app;

    private FirebaseContext() {}

    static synchronized FirebaseApp app() throws IOException {
        if (app != null) return app;
        String project = System.getenv("FIREBASE_PROJECT_ID");
        if (project == null || project.isBlank()) throw new IllegalStateException("FIREBASE_PROJECT_ID is required");
        String emulator = System.getenv("FIREBASE_AUTH_EMULATOR_HOST");
        GoogleCredentials credentials = emulator != null && !emulator.isBlank()
                ? GoogleCredentials.create(new AccessToken("owner", new Date(Long.MAX_VALUE)))
                : GoogleCredentials.getApplicationDefault();
        app = FirebaseApp.initializeApp(FirebaseOptions.builder()
                .setCredentials(credentials).setProjectId(project).build());
        return app;
    }

    public static FirebaseAuth auth() throws IOException { return FirebaseAuth.getInstance(app()); }
    public static Firestore firestore() throws IOException { return FirestoreClient.getFirestore(app()); }
}
