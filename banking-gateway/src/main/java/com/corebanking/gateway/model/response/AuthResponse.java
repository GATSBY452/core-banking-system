package com.corebanking.gateway.model.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * AUTH RESPONSE
 * Returned after login or register
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AuthResponse {

    private CustomerData customer;
    private AccountData account;    // only on register
    private String accessToken;
    private String system;          // "traditional" or "blockchain"

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class CustomerData {
        private String id;
        private String firstName;
        private String lastName;
        private String email;
        private String phone;
        private String kycStatus;
        private String status;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class AccountData {
        private String id;
        private String accountNumber;
        private String accountType;
        private String accountName;
        private String currency;
        private double balance;
    }
}
