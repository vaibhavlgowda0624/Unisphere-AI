package edu.unisphere.api.security;

public record AuthenticatedUser(String uid, String role) {
    public boolean hasAtLeast(String required) {
        return rank(role) >= rank(required);
    }

    private static int rank(String role) {
        return switch (role) {
            case "STUDENT" -> 0;
            case "FACULTY" -> 1;
            case "CLUB_ADMIN" -> 2;
            case "SUPER_ADMIN" -> 3;
            default -> -1;
        };
    }
}
