package com.corebanking.gateway.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.client.RestTemplate;

/**
 * APP CONFIGURATION
 *
 * Sets up the RestTemplate — Spring Boot's HTTP client.
 * This is what Spring Boot uses to call our Node.js CBS APIs.
 *
 * Think of it like fetch() in JavaScript or URLSession in Swift.
 */
@Configuration
public class AppConfig {

    @Value("${cbs.traditional.base-url}")
    private String traditionalBaseUrl;

    @Value("${cbs.blockchain.base-url}")
    private String blockchainBaseUrl;

    /**
     * RestTemplate for Traditional CBS
     * Calls our Node.js API on port 3000
     */
    @Bean(name = "traditionalRestTemplate")
    public RestTemplate traditionalRestTemplate() {
        return new RestTemplate();
    }

    /**
     * RestTemplate for Blockchain CBS
     * Calls our Node.js API on port 3001
     */
    @Bean(name = "blockchainRestTemplate")
    public RestTemplate blockchainRestTemplate() {
        return new RestTemplate();
    }

    public String getTraditionalBaseUrl() {
        return traditionalBaseUrl;
    }

    public String getBlockchainBaseUrl() {
        return blockchainBaseUrl;
    }
}