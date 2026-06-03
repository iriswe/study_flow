package com.studyflow.exception;

import lombok.Getter;

import java.util.Map;

@Getter
public class ValidationException extends BusinessException {

    private final Map<String, String> errors;

    public ValidationException(String message) {
        super(422, message);
        this.errors = null;
    }

    public ValidationException(Map<String, String> errors) {
        super(422, "Validation failed");
        this.errors = errors;
    }
}