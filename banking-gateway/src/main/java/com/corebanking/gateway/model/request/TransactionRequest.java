package com.corebanking.gateway.model.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Positive;
import lombok.Data;

/**
 * TRANSACTION REQUEST
 * Used for deposit, withdraw, and transfer
 */
@Data
public class TransactionRequest {

    // For deposit and withdraw
    private String accountId;
    private String accountNumber;

    // For transfer
    private String fromAccountId;
    private String toAccountNumber;

    @Positive(message = "Amount must be greater than zero")
    private double amount;

    private String description;

    // Which system to use
    // "traditional" or "blockchain"
    private String system = "traditional";
}