package com.corebanking.gateway.controller;

import com.corebanking.gateway.model.response.ApiResponse;
import com.corebanking.gateway.service.AccountService;
import com.corebanking.gateway.service.TokenStoreService;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/**
 * ACCOUNT CONTROLLER
 *
 * Handles all account-related endpoints.
 * Extracts the CBS token from TokenStore
 * and forwards requests to AccountService.
 *
 * GET  /api/v1/accounts                     → all accounts
 * GET  /api/v1/accounts/:id                 → single account
 * GET  /api/v1/accounts/:id/balance         → balance only
 * GET  /api/v1/accounts/:id/transactions    → history
 * POST /api/v1/accounts                     → create account
 * PATCH /api/v1/accounts/:id/status         → freeze/unfreeze
 */
@Slf4j
@RestController
@RequestMapping("/api/v1/accounts")
@RequiredArgsConstructor
public class AccountController {

    private final AccountService accountService;
    private final TokenStoreService tokenStoreService;

    /**
     * GET /api/v1/accounts
     * Home screen — all accounts with live balances
     */
    @GetMapping
    public ResponseEntity<ApiResponse<Object>> getMyAccounts(
            @RequestAttribute("customerId") String customerId
    ) {
        try {
            String cbsToken = tokenStoreService.getCbsToken(customerId);
            Map<String, Object> result = accountService.getMyAccounts(cbsToken);
            return ResponseEntity.ok(
                    ApiResponse.success("Accounts fetched.", result.get("data"))
            );
        } catch (Exception e) {
            log.error("Get accounts error: {}", e.getMessage());
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error(e.getMessage()));
        }
    }

    /**
     * GET /api/v1/accounts/:id
     */
    @GetMapping("/{accountId}")
    public ResponseEntity<ApiResponse<Object>> getAccount(
            @PathVariable String accountId,
            @RequestAttribute("customerId") String customerId
    ) {
        try {
            String cbsToken = tokenStoreService.getCbsToken(customerId);
            Map<String, Object> result = accountService.getAccount(
                    accountId, cbsToken
            );
            return ResponseEntity.ok(
                    ApiResponse.success("Account fetched.", result.get("data"))
            );
        } catch (Exception e) {
            log.error("Get account error: {}", e.getMessage());
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error(e.getMessage()));
        }
    }

    /**
     * GET /api/v1/accounts/:id/balance
     */
    @GetMapping("/{accountId}/balance")
    public ResponseEntity<ApiResponse<Object>> getBalance(
            @PathVariable String accountId,
            @RequestAttribute("customerId") String customerId
    ) {
        try {
            String cbsToken = tokenStoreService.getCbsToken(customerId);
            Map<String, Object> result = accountService.getBalance(
                    accountId, cbsToken
            );
            return ResponseEntity.ok(
                    ApiResponse.success("Balance fetched.", result.get("data"))
            );
        } catch (Exception e) {
            log.error("Get balance error: {}", e.getMessage());
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error(e.getMessage()));
        }
    }

    /**
     * GET /api/v1/accounts/:id/transactions
     */
    @GetMapping("/{accountId}/transactions")
    public ResponseEntity<ApiResponse<Object>> getTransactions(
            @PathVariable String accountId,
            @RequestParam(defaultValue = "20") int limit,
            @RequestParam(defaultValue = "0")  int offset,
            @RequestAttribute("customerId") String customerId
    ) {
        try {
            String cbsToken = tokenStoreService.getCbsToken(customerId);
            Map<String, Object> result = accountService.getAccountTransactions(
                    accountId, limit, offset, cbsToken
            );
            return ResponseEntity.ok(
                    ApiResponse.success("Transactions fetched.", result.get("data"))
            );
        } catch (Exception e) {
            log.error("Get transactions error: {}", e.getMessage());
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error(e.getMessage()));
        }
    }

    /**
     * POST /api/v1/accounts
     * Create additional account
     */
    @PostMapping
    public ResponseEntity<ApiResponse<Object>> createAccount(
            @RequestBody Map<String, Object> requestBody,
            @RequestAttribute("customerId") String customerId
    ) {
        try {
            String cbsToken = tokenStoreService.getCbsToken(customerId);
            Map<String, Object> result = accountService.createAccount(
                    requestBody, cbsToken
            );
            return ResponseEntity.status(201).body(
                    ApiResponse.success("Account created.", result.get("data"))
            );
        } catch (Exception e) {
            log.error("Create account error: {}", e.getMessage());
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error(e.getMessage()));
        }
    }

    /**
     * PATCH /api/v1/accounts/:id/status
     * Freeze or unfreeze
     */
    @PatchMapping("/{accountId}/status")
    public ResponseEntity<ApiResponse<Object>> updateStatus(
            @PathVariable String accountId,
            @RequestBody Map<String, Object> requestBody,
            @RequestAttribute("customerId") String customerId
    ) {
        try {
            String status   = (String) requestBody.get("status");
            String cbsToken = tokenStoreService.getCbsToken(customerId);
            Map<String, Object> result = accountService.updateAccountStatus(
                    accountId, status, cbsToken
            );
            return ResponseEntity.ok(
                    ApiResponse.success("Account status updated.", result.get("data"))
            );
        } catch (Exception e) {
            log.error("Update status error: {}", e.getMessage());
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error(e.getMessage()));
        }
    }
}