package edu.unisphere.api;

import java.util.Map;
import java.util.concurrent.ExecutionException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@RestControllerAdvice
public class ApiErrorHandler {
    @ExceptionHandler(SecurityException.class)
    ResponseEntity<Map<String, String>> forbidden(SecurityException error) {
        return ResponseEntity.status(HttpStatus.FORBIDDEN).body(Map.of("error", error.getMessage()));
    }

    @ExceptionHandler(IllegalArgumentException.class)
    ResponseEntity<Map<String, String>> invalid(IllegalArgumentException error) {
        return ResponseEntity.badRequest().body(Map.of("error", error.getMessage()));
    }

    @ExceptionHandler(IllegalStateException.class)
    ResponseEntity<Map<String, String>> conflict(IllegalStateException error) {
        return ResponseEntity.status(HttpStatus.CONFLICT).body(Map.of("error", error.getMessage()));
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    ResponseEntity<Map<String, String>> validation(MethodArgumentNotValidException error) {
        return ResponseEntity.badRequest().body(Map.of("error", "Invalid request fields"));
    }

    @ExceptionHandler(ExecutionException.class)
    ResponseEntity<Map<String, String>> transaction(ExecutionException error) {
        Throwable cause = error.getCause();
        if (cause instanceof IllegalStateException) return conflict((IllegalStateException) cause);
        if (cause instanceof IllegalArgumentException) return invalid((IllegalArgumentException) cause);
        if (cause instanceof SecurityException) return forbidden((SecurityException) cause);
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(Map.of("error", "The operation failed. Try again."));
    }
}
