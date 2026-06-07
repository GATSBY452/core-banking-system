package com.corebanking.gateway.controller;

import com.corebanking.gateway.model.request.LoginRequest;
import com.corebanking.gateway.model.request.RegisterRequest;
import com.corebanking.gateway.model.response.ApiResponse;
import com.corebanking.gateway.model.response.AuthResponse;
import com.corebanking.gateway.service.AuthService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/**
 * AUTH CONTROLLER
 *
 * The endpoints the iOS app calls for login and register.
 * Spring Boot is the only thing the iOS app ever talks to.
 *
 * POST /api/v1/auth/register  → create account
 * POST /api/v1/auth/login     → login
 * GET  /api/v1/auth/me        → get profile
 */
@Slf4j
@RestController
@RequestMapping("/api/v1/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;

    /**
     * REGISTER
     * iOS app creates a new account
     */
    @PostMapping("/register")
    public ResponseEntity<ApiResponse<AuthResponse>> register(
            @Valid @RequestBody RegisterRequest request
    ) {
        try {
            log.info("Register request for: {}", request.getEmail());
            AuthResponse response = authService.register(request);
            return ResponseEntity
                    .status(HttpStatus.CREATED)
                    .body(ApiResponse.success("Account created successfully.", response));

        } catch (Exception e) {
            log.error("Register failed: {}", e.getMessage());
            return ResponseEntity
                    .status(HttpStatus.BAD_REQUEST)
                    .body(ApiResponse.error(e.getMessage()));
        }
    }

    /**
     * LOGIN
     * iOS app logs in
     */
    @PostMapping("/login")
    public ResponseEntity<ApiResponse<AuthResponse>> login(
            @Valid @RequestBody LoginRequest request
    ) {
        try {
            log.info("Login request for: {}", request.getEmail());
            AuthResponse response = authService.login(request);
            return ResponseEntity.ok(
                    ApiResponse.success("Login successful.", response)
            );

        } catch (Exception e) {
            log.error("Login failed: {}", e.getMessage());
            return ResponseEntity
                    .status(HttpStatus.UNAUTHORIZED)
                    .body(ApiResponse.error(e.getMessage()));
        }
    }

    /**
     * ME
     * Get the currently logged in customer's info
     * Token is required — JwtFilter extracts customer details
     */
    @GetMapping("/me")
    public ResponseEntity<ApiResponse<Object>> getMe(
            @RequestAttribute("customerId") String customerId,
            @RequestAttribute("customerEmail") String email
    ) {
        return ResponseEntity.ok(
                ApiResponse.success("Profile fetched.", Map.of(
                        "customerId", customerId,
                        "email",      email
                ))
        );
    }
}