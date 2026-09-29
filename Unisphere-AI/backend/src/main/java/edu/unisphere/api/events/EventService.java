package edu.unisphere.api.events;

import com.google.cloud.Timestamp;
import com.google.cloud.firestore.DocumentReference;
import com.google.cloud.firestore.DocumentSnapshot;
import com.google.cloud.firestore.Firestore;
import com.google.cloud.firestore.Transaction;
import edu.unisphere.api.security.AuthenticatedUser;
import edu.unisphere.api.security.FirebaseContext;
import java.time.Instant;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.TimeUnit;
import org.springframework.stereotype.Service;

@Service
public class EventService {
    public String create(AuthenticatedUser user, EventController.CreateEvent input) throws Exception {
        if (!user.hasAtLeast("FACULTY")) throw new SecurityException("Faculty role required");
        if (!input.endsAt().isAfter(input.startsAt()) || !input.startsAt().isAfter(Instant.now()))
            throw new IllegalArgumentException("Event dates are invalid");
        Firestore db = FirebaseContext.firestore();
        if (input.organizerClubId() != null && !input.organizerClubId().isBlank()
                && !user.role().equals("SUPER_ADMIN")) {
            DocumentSnapshot club = db.collection("clubs").document(input.organizerClubId())
                    .get().get(10, TimeUnit.SECONDS);
            if (!club.exists() || club.get("adminUids") == null
                    || !(club.get("adminUids") instanceof java.util.List<?> admins)
                    || !admins.contains(user.uid())) throw new SecurityException("Club admin access required");
        }
        DocumentReference ref = db.collection("events").document();
        Map<String, Object> data = new HashMap<>();
        data.put("title", input.title().trim());
        data.put("description", input.description().trim());
        data.put("venue", input.venue().trim());
        data.put("organizer", input.organizer().trim());
        data.put("category", input.category().trim());
        data.put("organizerClubId", input.organizerClubId());
        data.put("startsAt", Timestamp.ofTimeSecondsAndNanos(input.startsAt().getEpochSecond(), input.startsAt().getNano()));
        data.put("endsAt", Timestamp.ofTimeSecondsAndNanos(input.endsAt().getEpochSecond(), input.endsAt().getNano()));
        data.put("maxSeats", input.maxSeats());
        data.put("registeredCount", 0);
        data.put("creatorUid", user.uid());
        data.put("status", "DRAFT");
        data.put("createdAt", Timestamp.now());
        ref.set(data).get(10, TimeUnit.SECONDS);
        return ref.getId();
    }

    public void publish(AuthenticatedUser user, String eventId) throws Exception {
        Firestore db = FirebaseContext.firestore();
        DocumentReference ref = db.collection("events").document(eventId);
        DocumentSnapshot event = ref.get().get(10, TimeUnit.SECONDS);
        ensureManager(user, event);
        if (!"DRAFT".equals(event.getString("status"))) throw new IllegalStateException("Only drafts can be published");
        ref.update("status", "PUBLISHED").get(10, TimeUnit.SECONDS);
    }

    public void cancel(AuthenticatedUser user, String eventId) throws Exception {
        Firestore db = FirebaseContext.firestore();
        DocumentReference ref = db.collection("events").document(eventId);
        DocumentSnapshot event = ref.get().get(10, TimeUnit.SECONDS);
        ensureManager(user, event);
        ref.update("status", "CANCELLED").get(10, TimeUnit.SECONDS);
    }

    public void register(AuthenticatedUser user, String eventId) throws Exception {
        Firestore db = FirebaseContext.firestore();
        DocumentReference eventRef = db.collection("events").document(eventId);
        DocumentReference registrationRef = db.collection("event_registrations")
                .document(eventId + "_" + user.uid());
        db.runTransaction((Transaction transaction) -> {
            DocumentSnapshot event = transaction.get(eventRef).get();
            DocumentSnapshot registration = transaction.get(registrationRef).get();
            if (!event.exists()) throw new IllegalArgumentException("Event not found");
            Timestamp endsAt = event.getTimestamp("endsAt");
            EventRegistrationPolicy.ensureCanRegister(new EventRegistrationPolicy.Event(
                    event.getString("status"), endsAt == null ? null : endsAt.toDate().toInstant(),
                    number(event, "maxSeats"), number(event, "registeredCount")),
                    registration.exists(), Instant.now());
            transaction.create(registrationRef, Map.of("eventId", eventId, "uid", user.uid(),
                    "createdAt", Timestamp.now()));
            transaction.update(eventRef, "registeredCount", number(event, "registeredCount") + 1);
            return null;
        }).get(15, TimeUnit.SECONDS);
    }

    public void unregister(AuthenticatedUser user, String eventId) throws Exception {
        Firestore db = FirebaseContext.firestore();
        DocumentReference eventRef = db.collection("events").document(eventId);
        DocumentReference registrationRef = db.collection("event_registrations")
                .document(eventId + "_" + user.uid());
        db.runTransaction((Transaction transaction) -> {
            DocumentSnapshot event = transaction.get(eventRef).get();
            DocumentSnapshot registration = transaction.get(registrationRef).get();
            if (!event.exists() || !registration.exists()) throw new IllegalArgumentException("Registration not found");
            transaction.delete(registrationRef);
            transaction.update(eventRef, "registeredCount", Math.max(0, number(event, "registeredCount") - 1));
            return null;
        }).get(15, TimeUnit.SECONDS);
    }

    private static int number(DocumentSnapshot doc, String field) {
        Number value = doc.getLong(field);
        return value == null ? 0 : value.intValue();
    }

    private static void ensureManager(AuthenticatedUser user, DocumentSnapshot event) {
        if (!event.exists()) throw new IllegalArgumentException("Event not found");
        if (!user.role().equals("SUPER_ADMIN") && !user.uid().equals(event.getString("creatorUid")))
            throw new SecurityException("Event manager access required");
    }
}
