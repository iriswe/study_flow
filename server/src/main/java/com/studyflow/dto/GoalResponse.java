package com.studyflow.dto;

import com.studyflow.entity.Goal;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class GoalResponse {
    private Long id;
    private String title;
    private String description;
    private Goal.GoalType type;
    private Goal.Priority priority;
    private LocalDateTime deadline;
    private BigDecimal progress;
    private Integer totalTasks;
    private Integer completedTasks;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    public static GoalResponse from(Goal goal, int totalTasks, int completedTasks) {
        return GoalResponse.builder()
                .id(goal.getId())
                .title(goal.getTitle())
                .description(goal.getDescription())
                .type(goal.getType())
                .priority(goal.getPriority())
                .deadline(goal.getDeadline())
                .progress(goal.getProgress())
                .totalTasks(totalTasks)
                .completedTasks(completedTasks)
                .createdAt(goal.getCreatedAt())
                .updatedAt(goal.getUpdatedAt())
                .build();
    }
}