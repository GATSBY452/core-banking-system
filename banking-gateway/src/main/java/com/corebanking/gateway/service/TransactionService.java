package com.corebanking.gateway.service;

import com.corebanking.gateway.config.AppConfig;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.http.HttpMethod;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.util.HashMap;
import java.util.Map;

/**
 * TRANSACTION SERVICE
 *
 * Handles deposit, withdraw, transfer, reverse.
 * Forwards every request to Node.js CBS.
 * Node.js handles all the double-entry logic.
 *
 * Spring Boot's job here is:
 *   1. Receive from iOS app
 *   2. Add the CBS token to the request
 *   3. Forward to Node.js
 *   4. Return the result
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class TransactionService {

    private final AppConfig appConfig;
    private final AuthService authService;

    @Qualifier("traditionalRestTemplate")
    private final RestTemplate traditionalRestTemplate;

    /**
     * DEPOSIT
     * Forwards deposit request to Node.js CBS
     * Node.js creates the double entry:
     *   DEBIT  Bank Vault
     *   CREDIT Customer Account
     */
    public Map<String, Object> deposit(
            String accountId,
            double amount,
            String description,
            String idempotencyKey,
            String cbsToken
    ) {
        log.info("Processing deposit: accountId={} amount={}", accountId, amount);

        Map<String, Object> body = new HashMap<>();
        body.put("accountId", accountId);
        body.put("amount", amount);
        if (description != null) body.put("description", description);

        String url = appConfig.getTraditionalBaseUrl() + "/transactions/deposit";

        // Pass idempotency key as a custom header via body
        // Node.js reads it from the Idempotency-Key header
        return callWithIdempotency(url, body, idempotencyKey, cbsToken);
    }

    /**
     * WITHDRAWAL
     * Forwards withdrawal to Node.js CBS
     * Node.js creates the double entry:
     *   DEBIT  Customer Account
     *   CREDIT Bank Vault
     */
    public Map<String, Object> withdraw(
            String accountId,
            double amount,
            String description,
            String idempotencyKey,
            String cbsToken
    ) {
        log.info("Processing withdrawal: accountId={} amount={}", accountId, amount);

        Map<String, Object> body = new HashMap<>();
        body.put("accountId", accountId);
        body.put("amount", amount);
        if (description != null) body.put("description", description);

        String url = appConfig.getTraditionalBaseUrl() + "/transactions/withdraw";

        return callWithIdempotency(url, body, idempotencyKey, cbsToken);
    }

    /**
     * TRANSFER
     * Forwards transfer to Node.js CBS
     * Node.js creates the double entry:
     *   DEBIT  Sender Account
     *   CREDIT Receiver Account
     */
    public Map<String, Object> transfer(
            String fromAccountId,
            String toAccountNumber,
            double amount,
            String description,
            String idempotencyKey,
            String cbsToken
    ) {
        log.info(
                "Processing transfer: from={} to={} amount={}",
                fromAccountId, toAccountNumber, amount
        );

        Map<String, Object> body = new HashMap<>();
        body.put("fromAccountId",   fromAccountId);
        body.put("toAccountNumber", toAccountNumber);
        body.put("amount",          amount);
        if (description != null) body.put("description", description);

        String url = appConfig.getTraditionalBaseUrl() + "/transactions/transfer";

        return callWithIdempotency(url, body, idempotencyKey, cbsToken);
    }

    /**
     * GET TRANSACTION
     * Fetch a single transaction with its ledger entries
     */
    public Map<String, Object> getTransaction(
            String transactionId,
            String cbsToken
    ) {
        log.info("Fetching transaction: {}", transactionId);

        String url = appConfig.getTraditionalBaseUrl()
                + "/transactions/" + transactionId;

        return authService.callCBS(
                traditionalRestTemplate,
                url,
                HttpMethod.GET,
                null,
                cbsToken
        );
    }

    /**
     * REVERSE TRANSACTION
     * Creates mirror ledger entries
     * Original marked as reversed
     */
    public Map<String, Object> reverse(
            String transactionId,
            String reason,
            String cbsToken
    ) {
        log.info("Reversing transaction: {}", transactionId);

        Map<String, Object> body = new HashMap<>();
        if (reason != null) body.put("reason", reason);

        String url = appConfig.getTraditionalBaseUrl()
                + "/transactions/" + transactionId + "/reverse";

        return authService.callCBS(
                traditionalRestTemplate,
                url,
                HttpMethod.POST,
                body,
                cbsToken
        );
    }

    /**
     * Internal helper — makes the CBS call
     * Idempotency key is passed in the request body
     * so Node.js can prevent duplicate transactions
     */
    private Map<String, Object> callWithIdempotency(
            String url,
            Map<String, Object> body,
            String idempotencyKey,
            String cbsToken
    ) {
        if (idempotencyKey != null && !idempotencyKey.isEmpty()) {
            body.put("_idempotencyKey", idempotencyKey);
        }

        return authService.callCBS(
                traditionalRestTemplate,
                url,
                HttpMethod.POST,
                body,
                cbsToken
        );
    }
}