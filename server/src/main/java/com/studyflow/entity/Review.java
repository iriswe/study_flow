package com.studyflow.entity;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import lombok.Builder;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
@Entity
@Table(name = "reviews", indexes = {
    @Index(name = "idx_review_user_date", columnList = "user_id, next_review_date"),
    @Index(name = "idx_review_task", columnList = "task_id")
})
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Review {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "task_id", nullable = false)
    private Task task;

    @Column(name = "next_review_date", nullable = false)
    private LocalDate nextReviewDate;

    @Column(precision = 6, scale = 2)
    @Builder.Default
    private BigDecimal stability = BigDecimal.valueOf(1.0);  // 记忆稳定度（天）

    @Column(precision = 3, scale = 2)
    @Builder.Default
    private BigDecimal difficulty = BigDecimal.valueOf(5.0);  // 难度系数（0-10）

    @Enumerated(EnumType.STRING)
    @Column(name = "last_response")
    private ReviewResponse lastResponse;  // 上次复习的反馈

    @Column(name = "review_count")
    @Builder.Default
    private Integer reviewCount = 0;  // 复习次数

    @Column(name = "review_interval")
    @Builder.Default
    private Integer interval = 1;  // 当前间隔（天）

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    @Builder.Default
    private ReviewStatus status = ReviewStatus.PENDING;

    // 独立复习笔记字段（不同于 Task.note）
    @Column(columnDefinition = "TEXT")
    private String note;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        updatedAt = LocalDateTime.now();
        if (nextReviewDate == null) {
            nextReviewDate = LocalDate.now();
        }
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }

    public enum ReviewResponse {
        FORGOT,      // 忘记（-3）
        FUZZY,       // 模糊（-2）
        GOOD,        // 良好（0）
        EASY         // 简单（3）
    }

    public enum ReviewStatus {
        PENDING,     // 待复习
        REVIEWING,   // 复习中
        MASTERED     // 已掌握
    }
}
