package com.corebanking.gateway.service;

import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.concurrent.ConcurrentHashMap;

/**
 * TOKEN STORE SERVICE
 *
 * When a customer logs in or registers:
 *   1. Spring Boot calls Node.js CBS
 *   2. Node.js returns its own JWT token
 *   3. Spring Boot stores that token here
 *   4. When iOS app makes requests, Spring Boot
 *      retrieves the CBS token and forwards it
 *
 * This is an in-memory store (good for dev).
 * In production use Redis for distributed caching.
 *
 * customerId → cbsToken mapping
 */
@Slf4j
@Service
public class TokenStoreService {

    // Thread-safe map: customerId → Node.js CBS token
    private final ConcurrentHashMap<String, String> tokenStore
            = new ConcurrentHashMap<>();

    /**
     * Save a CBS token for a customer
     * Called after successful login or register
     */
    public void saveCbsToken(String customerId, String cbsToken) {
        tokenStore.put(customerId, cbsToken);
        log.debug("CBS token saved for customer: {}", customerId);
    }

    /**
     * Get the CBS token for a customer
     * Called before every forwarded request
     */
    public String getCbsToken(String customerId) {
        String token = tokenStore.get(customerId);
        if (token == null) {
            log.warn("No CBS token found for customer: {}", customerId);
            throw new RuntimeException(
                    "Session expired. Please log in again."
            );
        }
        return token;
    }

    /**
     * Remove token on logout
     */
    public void removeCbsToken(String customerId) {
        tokenStore.remove(customerId);
        log.debug("CBS token removed for customer: {}", customerId);
    }

    /**
     * Check if customer has a valid CBS token
     */
    public boolean hasCbsToken(String customerId) {
        return tokenStore.containsKey(customerId);
    }
}