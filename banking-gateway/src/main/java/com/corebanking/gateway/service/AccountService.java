package com.corebanking.gateway.service;

import com.corebanking.gateway.config.AppConfig;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.http.HttpMethod;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.util.Map;

/**
 * ACCOUNT SERVICE
 *
 * Handles all account operations by forwarding
 * requests to the Node.js CBS and returning results.
 *
 * Spring Boot never touches PostgreSQL directly.
 * It always goes through Node.js CBS.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class AccountService {

    private final AppConfig appConfig;
    private final AuthService authService; // reuse callCBS()

    @Qualifier("traditionalRestTemplate")
    private final RestTemplate traditionalRestTemplate;

    /**
     * Get all accounts for a customer
     * Called when iOS app loads the home screen
     */
    public Map<String, Object> getMyAccounts(String cbsToken) {
        log.info("Fetching customer accounts");

        String url = appConfig.getTraditionalBaseUrl() + "/accounts";

        return authService.callCBS(
                traditionalRestTemplate,
                url,
                HttpMethod.GET,
                null,     // no body for GET request
                cbsToken  // pass the Node.js token
        );
    }

    /**
     * Get a single account by ID
     */
    public Map<String, Object> getAccount(String accountId, String cbsToken) {
        log.info("Fetching account: {}", accountId);

        String url = appConfig.getTraditionalBaseUrl() + "/accounts/" + accountId;

        return authService.callCBS(
                traditionalRestTemplate,
                url,
                HttpMethod.GET,
                null,
                cbsToken
        );
    }

    /**
     * Get account balance only
     */
    public Map<String, Object> getBalance(String accountId, String cbsToken) {
        log.info("Fetching balance for account: {}", accountId);

        String url = appConfig.getTraditionalBaseUrl()
                + "/accounts/" + accountId + "/balance";

        return authService.callCBS(
                traditionalRestTemplate,
                url,
                HttpMethod.GET,
                null,
                cbsToken
        );
    }

    /**
     * Get transaction history for an account
     */
    public Map<String, Object> getAccountTransactions(
            String accountId,
            int limit,
            int offset,
            String cbsToken
    ) {
        log.info("Fetching transactions for account: {}", accountId);

        String url = appConfig.getTraditionalBaseUrl()
                + "/accounts/" + accountId
                + "/transactions?limit=" + limit + "&offset=" + offset;

        return authService.callCBS(
                traditionalRestTemplate,
                url,
                HttpMethod.GET,
                null,
                cbsToken
        );
    }

    /**
     * Create a new account for a customer
     */
    public Map<String, Object> createAccount(
            Map<String, Object> requestBody,
            String cbsToken
    ) {
        log.info("Creating new account: {}", requestBody.get("accountType"));

        String url = appConfig.getTraditionalBaseUrl() + "/accounts";

        return authService.callCBS(
                traditionalRestTemplate,
                url,
                HttpMethod.POST,
                requestBody,
                cbsToken
        );
    }

    /**
     * Freeze or unfreeze an account
     */
    public Map<String, Object> updateAccountStatus(
            String accountId,
            String status,
            String cbsToken
    ) {
        log.info("Updating account {} status to: {}", accountId, status);

        String url = appConfig.getTraditionalBaseUrl()
                + "/accounts/" + accountId + "/status";

        Map<String, Object> body = Map.of("status", status);

        return authService.callCBS(
                traditionalRestTemplate,
                url,
                HttpMethod.PATCH,
                body,
                cbsToken
        );
    }
}