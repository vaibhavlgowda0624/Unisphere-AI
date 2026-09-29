package edu.unisphere.api.events;

import java.time.Instant;

public final class EventRegistrationPolicy {
    private EventRegistrationPolicy() {}

    public record Event(String status, Instant endsAt, int maxSeats, int registeredCount) {}

    public static void ensureCanRegister(Event event, boolean alreadyRegistered, Instant now) {
        if (!"PUBLISHED".equals(event.status())) throw new IllegalStateException("Event is not open");
        if (event.endsAt() == null || !event.endsAt().isAfter(now))
            throw new IllegalStateException("Event has ended");
        if (alreadyRegistered) throw new IllegalStateException("Already registered");
        if (event.maxSeats() > 0 && event.registeredCount() >= event.maxSeats())
            throw new IllegalStateException("Event is full");
    }
}
