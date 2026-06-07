package com.corebanking.gateway.security;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.ArrayList;

/**
 * JWT FILTER
 *
 * Intercepts every HTTP request coming from the iOS app.
 * Runs BEFORE the controller handles anything.
 *
 * Flow for every request:
 *   1. Extract token from Authorization header
 *   2. Validate the token
 *   3. If valid → let the request through
 *   4. If invalid/missing → Spring Security blocks it (401)
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class JwtFilter extends OncePerRequestFilter {

    private final JwtUtil jwtUtil;

    @Override
    protected void doFilterInternal(
            HttpServletRequest request,
            HttpServletResponse response,
            FilterChain filterChain
    ) throws ServletException, IOException {

        final String path = request.getRequestURI();
        log.debug("→ Incoming request: {} {}", request.getMethod(), path);

        // Step 1 — Get Authorization header
        final String authHeader = request.getHeader("Authorization");

        // Step 2 — Check if token exists
        // Public routes (login, register) won't have a token — that's fine
        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            log.debug("  No token found — passing to security config to decide");
            filterChain.doFilter(request, response);
            return;
        }

        // Step 3 — Extract the token (remove "Bearer " prefix)
        final String token = authHeader.substring(7);

        // Step 4 — Validate token
        if (!jwtUtil.isTokenValid(token)) {
            log.warn("  Invalid or expired token for request: {}", path);
            filterChain.doFilter(request, response);
            return;
        }

        // Step 5 — Extract user info from token
        final String email      = jwtUtil.extractEmail(token);
        final String customerId = jwtUtil.extractCustomerId(token);
        log.debug("  Valid token for customer: {} ({})", email, customerId);

        // Step 6 — Tell Spring Security this request is authenticated
        // Only do this if not already authenticated
        if (email != null &&
                SecurityContextHolder.getContext().getAuthentication() == null) {

            UsernamePasswordAuthenticationToken authToken =
                    new UsernamePasswordAuthenticationToken(
                            email,          // principal (who the user is)
                            null,           // credentials (not needed — token already verified)
                            new ArrayList<>() // authorities (roles — empty for now)
                    );

            authToken.setDetails(
                    new WebAuthenticationDetailsSource().buildDetails(request)
            );

            // Attach to the current request's security context
            SecurityContextHolder.getContext().setAuthentication(authToken);

            // Make customer ID available to controllers
            request.setAttribute("customerId", customerId);
            request.setAttribute("customerEmail", email);
        }

        // Step 7 — Pass request to next step (controller)
        filterChain.doFilter(request, response);
    }
}