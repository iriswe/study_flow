package com.studyflow.entity;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import lombok.Builder;

import java.time.LocalDateTime;

@Data
@Entity
@Table(name = "user_settings")
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UserSettings {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false, unique = true)
    private User user;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    @Builder.Default
    private Theme theme = Theme.LIGHT;

    @Column(nullable = false)
    @Builder.Default
    private Boolean sidebarCollapsed = false;

    // 番茄钟设置
    @Column(name = "focus_duration")
    @Builder.Default
    private Integer focusDuration = 25;  // 分钟

    @Column(name = "break_duration")
    @Builder.Default
    private Integer breakDuration = 5;   // 分钟

    @Column(name = "long_break_duration")
    @Builder.Default
    private Integer longBreakDuration = 15;  // 分钟

    @Column(name = "cycles_before_long_break")
    @Builder.Default
    private Integer cyclesBeforeLongBreak = 4;

    // 通知设置
    @Column(name = "review_notification_enabled")
    @Builder.Default
    private Boolean reviewNotificationEnabled = true;

    @Column(name = "review_notification_time")
    private String reviewNotificationTime;  // HH:mm 格式

    @Column(name = "focus_notification_enabled")
    @Builder.Default
    private Boolean focusNotificationEnabled = true;

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

    public enum Theme {
        LIGHT,      // 浅色
        DARK,       // 深色
        SYSTEM      // 跟随系统
    }
}