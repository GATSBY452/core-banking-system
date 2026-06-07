package com.corebanking.gateway.controller;

import com.corebanking.gateway.model.request.TransactionRequest;
import com.corebanking.gateway.model.response.ApiResponse;
import com.corebanking.gateway.service.TokenStoreService;
import com.corebanking.gateway.service.TransactionService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/**
 * TRANSACTION CONTROLLER
 *
 * POST /api/v1/transactions/deposit
 * POST /api/v1/transactions/withdraw
 * POST /api/v1/transactions/transfer
 * GET  /api/v1/transactions/:id
 * POST /api/v1/transactions/:id/reverse
 */
@Slf4j
@RestController
@RequestMapping("/api/v1/transactions")
@RequiredArgsConstructor
public class TransactionController {

    private final TransactionService transactionService;
    private final TokenStoreService  tokenStoreService;

    /**
     * POST /api/v1/transactions/deposit
     */
    @PostMapping("/deposit")
    public ResponseEntity<ApiResponse<Object>> deposit(
            @Valid @RequestBody TransactionRequest request,
            @RequestAttribute("customerId") String customerId,
            @RequestHeader(value = "Idempotency-Key", required = false)
            String idempotencyKey
    ) {
        try {
            String cbsToken = tokenStoreService.getCbsToken(customerId);
            Map<String, Object> result = transactionService.deposit(
                    request.getAccountId(),
                    request.getAmount(),
                    request.getDescription(),
                    idempotencyKey,
                    cbsToken
            );
            return ResponseEntity.status(201).body(
                    ApiResponse.success("Deposit successful.", result.get("data"))
            );
        } catch (Exception e) {
            log.error("Deposit error: {}", e.getMessage());
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error(e.getMessage()));
        }
    }

    /**
     * POST /api/v1/transactions/withdraw
     */
    @PostMapping("/withdraw")
    public ResponseEntity<ApiResponse<Object>> withdraw(
            @Valid @RequestBody TransactionRequest request,
            @RequestAttribute("customerId") String customerId,
            @RequestHeader(value = "Idempotency-Key", required = false)
            String idempotencyKey
    ) {
        try {
            String cbsToken = tokenStoreService.getCbsToken(customerId);
            Map<String, Object> result = transactionService.withdraw(
                    request.getAccountId(),
                    request.getAmount(),
                    request.getDescription(),
                    idempotencyKey,
                    cbsToken
            );
            return ResponseEntity.status(201).body(
                    ApiResponse.success("Withdrawal successful.", result.get("data"))
            );
        } catch (Exception e) {
            log.error("Withdrawal error: {}", e.getMessage());
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error(e.getMessage()));
        }
    }

    /**
     * POST /api/v1/transactions/transfer
     */
    @PostMapping("/transfer")
    public ResponseEntity<ApiResponse<Object>> transfer(
            @Valid @RequestBody TransactionRequest request,
            @RequestAttribute("customerId") String customerId,
            @RequestHeader(value = "Idempotency-Key", required = false)
            String idempotencyKey
    ) {
        try {
            String cbsToken = tokenStoreService.getCbsToken(customerId);
            Map<String, Object> result = transactionService.transfer(
                    request.getFromAccountId(),
                    request.getToAccountNumber(),
                    request.getAmount(),
                    request.getDescription(),
                    idempotencyKey,
                    cbsToken
            );
            return ResponseEntity.status(201).body(
                    ApiResponse.success("Transfer successful.", result.get("data"))
            );
        } catch (Exception e) {
            log.error("Transfer error: {}", e.getMessage());
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error(e.getMessage()));
        }
    }

    /**
     * GET /api/v1/transactions/:id
     */
    @GetMapping("/{transactionId}")
    public ResponseEntity<ApiResponse<Object>> getTransaction(
            @PathVariable String transactionId,
            @RequestAttribute("customerId") String customerId
    ) {
        try {
            String cbsToken = tokenStoreService.getCbsToken(customerId);
            Map<String, Object> result = transactionService.getTransaction(
                    transactionId, cbsToken
            );
            return ResponseEntity.ok(
                    ApiResponse.success("Transaction fetched.", result.get("data"))
            );
        } catch (Exception e) {
            log.error("Get transaction error: {}", e.getMessage());
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error(e.getMessage()));
        }
    }

    /**
     * POST /api/v1/transactions/:id/reverse
     */
    @PostMapping("/{transactionId}/reverse")
    public ResponseEntity<ApiResponse<Object>> reverse(
            @PathVariable String transactionId,
            @RequestBody(required = false) Map<String, Object> body,
            @RequestAttribute("customerId") String customerId
    ) {
        try {
            String reason   = body != null ? (String) body.get("reason") : null;
            String cbsToken = tokenStoreService.getCbsToken(customerId);
            Map<String, Object> result = transactionService.reverse(
                    transactionId, reason, cbsToken
            );
            return ResponseEntity.ok(
                    ApiResponse.success("Transaction reversed.", result.get("data"))
            );
        } catch (Exception e) {
            log.error("Reverse error: {}", e.getMessage());
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error(e.getMessage()));
        }
    }
}