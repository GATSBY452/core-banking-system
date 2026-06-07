package com.corebanking.gateway.service;

import com.corebanking.gateway.config.AppConfig;
import com.corebanking.gateway.model.request.LoginRequest;
import com.corebanking.gateway.model.request.RegisterRequest;
import com.corebanking.gateway.model.response.AuthResponse;
import com.corebanking.gateway.security.JwtUtil;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.client.RestTemplate;

import java.util.HashMap;
import java.util.Map;

@Slf4j
@Service
@RequiredArgsConstructor
public class AuthService {

    private final AppConfig appConfig;
    private final JwtUtil jwtUtil;
    private final TokenStoreService tokenStoreService;

    @Qualifier("traditionalRestTemplate")
    private final RestTemplate traditionalRestTemplate;

    // ============================================================
    // REGISTER
    // ============================================================
    public AuthResponse register(RegisterRequest request) {
        log.info("Registering new customer: {}", request.getEmail());

        // Build request body — never send empty string for date fields
        Map<String, Object> cbsRequest = new HashMap<>();
        cbsRequest.put("firstName", request.getFirstName());
        cbsRequest.put("lastName",  request.getLastName());
        cbsRequest.put("email",     request.getEmail());
        cbsRequest.put("phone",     request.getPhone());
        cbsRequest.put("password",  request.getPassword());

        if (request.getDateOfBirth() != null && !request.getDateOfBirth().isEmpty()) {
            cbsRequest.put("dateOfBirth", request.getDateOfBirth());
        }
        if (request.getAddress() != null && !request.getAddress().isEmpty()) {
            cbsRequest.put("address", request.getAddress());
        }

        // Forward to Node.js CBS
        String url = appConfig.getTraditionalBaseUrl() + "/auth/register";
        Map<String, Object> cbsResponse = callCBS(
                traditionalRestTemplate, url, HttpMethod.POST, cbsRequest, null
        );

        // Extract customer and account from CBS response
        Map<String, Object> data     = (Map<String, Object>) cbsResponse.get("data");
        Map<String, Object> customer = (Map<String, Object>) data.get("customer");
        Map<String, Object> account  = (Map<String, Object>) data.get("account");

        String customerId = (String) customer.get("id");
        String email      = (String) customer.get("email");

        // Generate Spring Boot JWT — iOS app gets THIS token
        String springToken = jwtUtil.generateToken(email, customerId);
        // Save Node.js token so we can forward it on future requests
        String cbsToken = (String) data.get("accessToken");
        tokenStoreService.saveCbsToken(customerId, cbsToken);


        log.info("Customer registered successfully: {}", email);

        return AuthResponse.builder()
                .customer(AuthResponse.CustomerData.builder()
                        .id(customerId)
                        .firstName((String) customer.get("first_name"))
                        .lastName((String)  customer.get("last_name"))
                        .email(email)
                        .phone((String)     customer.get("phone"))
                        .kycStatus((String) customer.get("kyc_status"))
                        .status((String)    customer.get("status"))
                        .build())
                .account(AuthResponse.AccountData.builder()
                        .id((String)          account.get("id"))
                        .accountNumber((String) account.get("accountNumber"))
                        .accountType((String)   account.get("accountType"))
                        .accountName((String)   account.get("accountName"))
                        .currency((String)      account.get("currency"))
                        .balance(0)
                        .build())
                .accessToken(springToken)
                .system("traditional")
                .build();
    }

    // ============================================================
    // LOGIN
    // ============================================================
    public AuthResponse login(LoginRequest request) {
        log.info("Login attempt for: {}", request.getEmail());

        Map<String, Object> cbsRequest = new HashMap<>();
        cbsRequest.put("email",    request.getEmail());
        cbsRequest.put("password", request.getPassword());

        String url = appConfig.getTraditionalBaseUrl() + "/auth/login";
        Map<String, Object> cbsResponse = callCBS(
                traditionalRestTemplate, url, HttpMethod.POST, cbsRequest, null
        );

        Map<String, Object> data     = (Map<String, Object>) cbsResponse.get("data");
        Map<String, Object> customer = (Map<String, Object>) data.get("customer");

        String customerId = (String) customer.get("id");
        String email      = (String) customer.get("email");

        String springToken = jwtUtil.generateToken(email, customerId);
        String cbsToken = (String) data.get("accessToken");
        tokenStoreService.saveCbsToken(customerId, cbsToken);

        log.info("Login successful for: {}", email);

        return AuthResponse.builder()
                .customer(AuthResponse.CustomerData.builder()
                        .id(customerId)
                        .firstName((String) customer.get("firstName"))
                        .lastName((String)  customer.get("lastName"))
                        .email(email)
                        .phone((String)     customer.get("phone"))
                        .kycStatus((String) customer.get("kycStatus"))
                        .status((String)    customer.get("status"))
                        .build())
                .accessToken(springToken)
                .system("traditional")
                .build();
    }

    // ============================================================
    // CALL CBS — forwards requests to Node.js
    // ============================================================
    @SuppressWarnings("unchecked")
    public Map<String, Object> callCBS(
            RestTemplate restTemplate,
            String url,
            HttpMethod method,
            Object body,
            String cbsToken
    ) {
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        if (cbsToken != null) {
            headers.setBearerAuth(cbsToken);
        }

        HttpEntity<Object> entity = new HttpEntity<>(body, headers);

        try {
            log.debug("Calling CBS: {} {}", method, url);
            ResponseEntity<Map> response = restTemplate.exchange(
                    url, method, entity, Map.class
            );
            log.debug("CBS response: {}", response.getStatusCode());
            return response.getBody();

        } catch (HttpClientErrorException e) {
            log.error("CBS error: {} - {}", e.getStatusCode(), e.getResponseBodyAsString());
            try {
                Map<String, Object> errorBody = e.getResponseBodyAs(Map.class);
                String message = errorBody != null
                        ? (String) errorBody.get("message")
                        : "CBS error";
                throw new RuntimeException(message);
            } catch (RuntimeException re) {
                throw re;
            } catch (Exception ex) {
                throw new RuntimeException("CBS request failed: " + e.getMessage());
            }
        } catch (Exception e) {
            log.error("Failed to reach CBS: {}", e.getMessage());
            throw new RuntimeException("Could not connect to banking service. Please try again.");
        }
    }
}