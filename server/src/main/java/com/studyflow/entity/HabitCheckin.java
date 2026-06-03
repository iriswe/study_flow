package com.studyflow.entity;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "habit_checkin", uniqueConstraints = @UniqueConstraint(columnNames = {"task_id", "checkin_date"}))
@Data
@NoArgsConstructor
public class HabitCheckin {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "task_id", nullable = false)
    private Task task;

    @Column(name = "checkin_date", nullable = false)
    private LocalDate checkinDate;

    @Column(name = "created_at")
    private LocalDateTime createdAt;

    public HabitCheckin(Task task, LocalDate checkinDate) {
        this.task = task;
        this.checkinDate = checkinDate;
    }

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
    }
}
