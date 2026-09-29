package edu.unisphere.api.events;

import static org.junit.jupiter.api.Assertions.*;
import java.time.Instant;
import org.junit.jupiter.api.Test;

class EventRegistrationPolicyTest {
    @Test void rejectsFullExpiredAndDuplicateRegistrations() {
        Instant now = Instant.parse("2026-09-28T12:00:00Z");
        var open = new EventRegistrationPolicy.Event("PUBLISHED", now.plusSeconds(3600), 10, 9);
        assertDoesNotThrow(() -> EventRegistrationPolicy.ensureCanRegister(open, false, now));
        assertThrows(IllegalStateException.class, () -> EventRegistrationPolicy.ensureCanRegister(open, true, now));
        assertThrows(IllegalStateException.class, () -> EventRegistrationPolicy.ensureCanRegister(
                new EventRegistrationPolicy.Event("PUBLISHED", now.plusSeconds(3600), 10, 10), false, now));
        assertThrows(IllegalStateException.class, () -> EventRegistrationPolicy.ensureCanRegister(
                new EventRegistrationPolicy.Event("PUBLISHED", now.minusSeconds(1), 10, 0), false, now));
    }
}
