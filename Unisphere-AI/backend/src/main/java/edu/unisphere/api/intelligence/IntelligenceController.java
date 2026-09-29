package edu.unisphere.api.intelligence;

import edu.unisphere.api.security.AuthenticatedUser;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

@RestController
@RequestMapping("/api/intelligence")
public class IntelligenceController {
    private final IntegrityCheckerService integrity;

    public IntelligenceController(IntegrityCheckerService integrity) { this.integrity = integrity; }

    public record CompareRequest(@NotBlank String sourceText, @NotBlank String candidateText) {}

    @PostMapping("/integrity")
    public IntegrityCheckerService.Result compare(@Valid @RequestBody CompareRequest input,
                                                   HttpServletRequest request) {
        AuthenticatedUser user = (AuthenticatedUser) request.getAttribute("user");
        if (!user.hasAtLeast("FACULTY")) throw new ResponseStatusException(HttpStatus.FORBIDDEN);
        return integrity.compare(input.sourceText(), input.candidateText());
    }
}
