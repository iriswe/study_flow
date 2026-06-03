package com.studyflow.entity;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import lombok.Builder;

import java.time.LocalDateTime;

@Data
@Entity
@Table(name = "study_logs")
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class StudyLog {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "task_id", nullable = false)
    private Task task;

    @Column(nullable = false)
    private Integer duration;  // 学习时长（分钟）

    @Column(columnDefinition = "TEXT")
    private String note;  // 笔记内容（Markdown）

    @Column(name = "image_urls", columnDefinition = "JSON")
    private String imageUrls;  // JSON 数组，存储图片 URL

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private ComprehensionScore score;  // 理解程度

    @Column(columnDefinition = "TEXT")
    private String problem;  // 遇到的问题

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
    }

    public enum ComprehensionScore {
        // NOTE: UNDERSAND is a typo preserved for backward DB compatibility.
        // New code should use UNDERSTAND. When DB is migrated, remove UNDERSAND.
        UNDERSAND,   // 不理解 (typo — use UNDERSTAND)
        FUZZY,       // 模糊
        UNDERSTAND,  // 理解
        MASTERY      // 精通
    }
}
