package com.studyflow.entity;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import lombok.Builder;

import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.ArrayList;
import java.util.List;

@Data
@Entity
@Table(name = "tasks")
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Task {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "goal_id", nullable = false)
    private Goal goal;

    @Column(nullable = false, length = 200)
    private String title;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    @Builder.Default
    private TaskStatus status = TaskStatus.PENDING;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private Goal.Priority priority;

    @Column(name = "estimate_minutes")
    private Integer estimateMinutes;

    @Column(name = "actual_minutes")
    private Integer actualMinutes;

    @Column(name = "due_date")
    private LocalDateTime dueDate;

    @Column(name = "sort_order")
    @Builder.Default
    private Integer sortOrder = 0;

    @Column(columnDefinition = "TEXT")
    private String note;

    // 任务类型：进度任务 或 习惯任务
    @Enumerated(EnumType.STRING)
    @Column(name = "task_type", nullable = false)
    @Builder.Default
    private TaskType taskType = TaskType.PROGRESSION;

    // 习惯任务专用字段
    @Enumerated(EnumType.STRING)
    @Column(name = "recurring_frequency")
    private RecurringFrequency recurringFrequency;  // DAILY, WEEKLY, WEEKDAYS

    @Column(name = "recurring_time")
    private LocalTime recurringTime;  // 每日几点

    @Column(name = "current_streak")
    @Builder.Default
    private Integer currentStreak = 0;  // 当前连续天数

    @Column(name = "longest_streak")
    @Builder.Default
    private Integer longestStreak = 0;  // 历史最长

    @Column(name = "total_completed")
    @Builder.Default
    private Integer totalCompleted = 0;  // 总完成次数

    @Column(name = "last_completed_date")
    private LocalDateTime lastCompletedDate;  // 上次完成日期

    @OneToMany(mappedBy = "task", cascade = CascadeType.ALL, orphanRemoval = true)
    @Builder.Default
    private List<SubTask> subTasks = new ArrayList<>();

    @OneToOne(mappedBy = "task", cascade = CascadeType.ALL)
    private Review review;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        updatedAt = LocalDateTime.now();
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }

    public enum TaskStatus {
        PENDING,    // 待办
        IN_PROGRESS, // 进行中
        COMPLETED   // 已完成
    }

    // 任务类型枚举
    public enum TaskType {
        PROGRESSION,  // 进度任务 - 有进度条
        HABIT         // 习惯任务 - 有连续天数
    }

    // 循环频率枚举
    public enum RecurringFrequency {
        DAILY,       // 每天
        WEEKLY,      // 每周
        WEEKDAYS     // 工作日
    }
}