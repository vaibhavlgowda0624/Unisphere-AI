package edu.unisphere.api.events;

import edu.unisphere.api.security.AuthenticatedUser;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.time.Instant;
import java.util.Map;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.annotation.ResponseStatus;

@RestController
@RequestMapping("/api/events")
public class EventController {
    private final EventService service;
    public EventController(EventService service) { this.service = service; }

    public record CreateEvent(@NotBlank String title, @NotBlank String description,
                              @NotBlank String organizer, @NotBlank String venue,
                              @NotBlank String category, String organizerClubId,
                              @NotNull Instant startsAt, @NotNull Instant endsAt,
                              @Min(0) int maxSeats) {}

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public Map<String, String> create(@Valid @RequestBody CreateEvent input,
                                      HttpServletRequest request) throws Exception {
        return Map.of("id", service.create(user(request), input));
    }

    @PostMapping("/{id}/publish")
    public void publish(@PathVariable String id, HttpServletRequest request) throws Exception {
        service.publish(user(request), id);
    }

    @DeleteMapping("/{id}")
    public void cancel(@PathVariable String id, HttpServletRequest request) throws Exception {
        service.cancel(user(request), id);
    }

    @PostMapping("/{id}/registrations")
    @ResponseStatus(HttpStatus.CREATED)
    public void register(@PathVariable String id, HttpServletRequest request) throws Exception {
        service.register(user(request), id);
    }

    @DeleteMapping("/{id}/registrations")
    public void unregister(@PathVariable String id, HttpServletRequest request) throws Exception {
        service.unregister(user(request), id);
    }

    private static AuthenticatedUser user(HttpServletRequest request) {
        return (AuthenticatedUser) request.getAttribute("user");
    }
}
