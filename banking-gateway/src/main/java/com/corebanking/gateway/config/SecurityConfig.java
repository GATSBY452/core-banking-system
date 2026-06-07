package com.corebanking.gateway.config;

import com.corebanking.gateway.security.JwtFilter;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import java.util.List;

/**
 * SECURITY CONFIGURATION
 *
 * Defines:
 *   - Which routes are public (no token needed)
 *   - Which routes are protected (token required)
 *   - Where the JWT filter sits in the chain
 *   - CORS settings (allows iOS app to call us)
 *   - Session policy (stateless — JWT handles state)
 */
@Configuration
@EnableWebSecurity
@RequiredArgsConstructor
public class SecurityConfig {

    private final JwtFilter jwtFilter;

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
                // Disable CSRF — not needed for REST APIs with JWT
                .csrf(AbstractHttpConfigurer::disable)

                // Allow iOS app and browser to call our API
                .cors(cors -> cors.configurationSource(corsConfigurationSource()))

                // Define which routes need authentication
                .authorizeHttpRequests(auth -> auth
                        // PUBLIC routes — no token needed
                        .requestMatchers(
                                "/api/v1/auth/register",
                                "/api/v1/auth/login",
                                "/actuator/health",
                                "/actuator/info"
                        ).permitAll()

                        // EVERYTHING ELSE requires a valid JWT token
                        .anyRequest().authenticated()
                )

                // Use stateless sessions — JWT handles everything
                // No sessions stored on server
                .sessionManagement(session -> session
                        .sessionCreationPolicy(SessionCreationPolicy.STATELESS)
                )

                // Add our JWT filter BEFORE Spring's default auth filter
                .addFilterBefore(jwtFilter, UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }

    /**
     * CORS Configuration
     * Allows the iOS app (and browser) to call our API
     */
    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration config = new CorsConfiguration();

        // Allow requests from any origin (iOS app, Postman, browser)
        config.setAllowedOriginPatterns(List.of("*"));

        // Allow these HTTP methods
        config.setAllowedMethods(List.of("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"));

        // Allow these headers
        config.setAllowedHeaders(List.of("*"));

        // Allow Authorization header (needed for JWT)
        config.setAllowCredentials(true);

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", config);
        return source;
    }

    /**
     * Password encoder — BCrypt
     * Used if we ever store passwords in Spring Boot
     */
    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }
}