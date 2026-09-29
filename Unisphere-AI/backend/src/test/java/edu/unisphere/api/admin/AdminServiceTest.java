package edu.unisphere.api.admin;

import static org.junit.jupiter.api.Assertions.assertThrows;
import edu.unisphere.api.security.AuthenticatedUser;
import org.junit.jupiter.api.Test;

class AdminServiceTest {
    @Test void studentsCannotResolveRoleRequests() {
        var service = new AdminService();
        assertThrows(SecurityException.class, () -> service.resolveRoleRequest(
                new AuthenticatedUser("student-1", "STUDENT"), "request-1", true));
    }
}
