package edu.unisphere.api.security;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

@Component
public class ApiAuthenticationFilter extends OncePerRequestFilter {
    private final UserAuthenticator authenticator;

    public ApiAuthenticationFilter(UserAuthenticator authenticator) {
        this.authenticator = authenticator;
    }

    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) {
        return !request.getRequestURI().startsWith("/api/");
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response,
                                    FilterChain chain) throws ServletException, IOException {
        String header = request.getHeader("Authorization");
        if (header == null || !header.startsWith("Bearer ") || header.length() <= 7) {
            response.sendError(401, "Bearer token required");
            return;
        }
        AuthenticatedUser user;
        try {
            user = authenticator.authenticate(header.substring(7));
        } catch (SecurityException e) {
            response.sendError(403, e.getMessage());
            return;
        } catch (Exception e) {
            response.sendError(401, "Invalid authentication token");
            return;
        }
        request.setAttribute("user", user);
        chain.doFilter(request, response);
    }
}
