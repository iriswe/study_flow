package com.studyflow.dto;

import com.studyflow.entity.Goal;
import lombok.Data;
import org.springframework.format.annotation.DateTimeFormat;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
public class UpdateGoalRequest {

    private String title;
    private String description;
    private Goal.GoalType type;
    private Goal.Priority priority;

    @DateTimeFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss")
    private LocalDateTime deadline;

    private BigDecimal progress;
}