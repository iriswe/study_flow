package com.studyflow.dto;

import com.studyflow.entity.Review;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ReviewResponse {
    private Long id;
    private Long taskId;
    private String taskTitle;
    private String goalTitle;     // ADDED: 关联目标名称（来自 Task -> Goal）
    private String taskNote;     // 任务备注（来自 Task.note）
    private String note;         // 独立复习笔记（Review.note）
    private LocalDate nextReviewDate;
    private BigDecimal stability;
    private BigDecimal difficulty;
    private Review.ReviewResponse lastResponse;
    private Integer reviewCount;
    private Integer interval;
    private Review.ReviewStatus status;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    public static ReviewResponse from(Review review) {
        return ReviewResponse.builder()
                .id(review.getId())
                .taskId(review.getTask().getId())
                .taskTitle(review.getTask().getTitle())
                .goalTitle(review.getTask().getGoal().getTitle())
                .taskNote(review.getTask().getNote())
                .note(review.getNote())
                .nextReviewDate(review.getNextReviewDate())
                .stability(review.getStability())
                .difficulty(review.getDifficulty())
                .lastResponse(review.getLastResponse())
                .reviewCount(review.getReviewCount())
                .interval(review.getInterval())
                .status(review.getStatus())
                .createdAt(review.getCreatedAt())
                .updatedAt(review.getUpdatedAt())
                .build();
    }
}
