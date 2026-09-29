package edu.unisphere.api.admin;

import edu.unisphere.api.security.AuthenticatedUser;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/admin")
public class AdminController {
    private final AdminService service;
    public AdminController(AdminService service) { this.service = service; }

    @PostMapping("/role-requests/{id}/approve")
    public void approveRole(@PathVariable String id, HttpServletRequest request) throws Exception {
        service.resolveRoleRequest(user(request), id, true);
    }
    @PostMapping("/role-requests/{id}/reject")
    public void rejectRole(@PathVariable String id, HttpServletRequest request) throws Exception {
        service.resolveRoleRequest(user(request), id, false);
    }
    @PostMapping("/notes/{id}/approve")
    public void approveNote(@PathVariable String id, HttpServletRequest request) throws Exception {
        service.moderateNote(user(request), id, true);
    }
    @PostMapping("/notes/{id}/reject")
    public void rejectNote(@PathVariable String id, HttpServletRequest request) throws Exception {
        service.moderateNote(user(request), id, false);
    }

    private static AuthenticatedUser user(HttpServletRequest request) {
        return (AuthenticatedUser) request.getAttribute("user");
    }
}
