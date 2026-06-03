package com.studyflow.dto;

import com.studyflow.entity.Task;
import com.studyflow.entity.Goal;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class TaskResponse {
    private Long id;
    private Long goalId;
    private String goalTitle;
    private String title;
    private Task.TaskStatus status;
    private Goal.Priority priority;
    private Integer estimateMinutes;
    private Integer actualMinutes;
    private LocalDateTime dueDate;
    private Integer sortOrder;
    private String note;

    // 任务类型和习惯任务统计
    private Task.TaskType taskType;
    private Task.RecurringFrequency recurringFrequency;
    private LocalTime recurringTime;
    private Integer currentStreak;
    private Integer longestStreak;
    private Integer totalCompleted;

    private List<SubTaskResponse> subTasks;
    private Boolean hasReview;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    // 进度计算
    private Integer progressPercent;  // 子任务完成百分比

    // 习惯签到状态
    private Boolean checkedInToday;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class SubTaskResponse {
        private Long id;
        private String title;
        private Boolean completed;
        private Integer sortOrder;
    }

    public static TaskResponse from(Task task, List<SubTaskResponse> subTasks) {
        // 计算进度百分比
        Integer progressPercent = null;
        if (subTasks != null && !subTasks.isEmpty()) {
            long completedCount = subTasks.stream().filter(s -> Boolean.TRUE.equals(s.getCompleted())).count();
            progressPercent = (int) ((completedCount * 100) / subTasks.size());
        }

        return TaskResponse.builder()
                .id(task.getId())
                .goalId(task.getGoal().getId())
                .goalTitle(task.getGoal().getTitle())
                .title(task.getTitle())
                .status(task.getStatus())
                .priority(task.getPriority())
                .estimateMinutes(task.getEstimateMinutes())
                .actualMinutes(task.getActualMinutes())
                .dueDate(task.getDueDate())
                .sortOrder(task.getSortOrder())
                .note(task.getNote())
                .taskType(task.getTaskType())
                .recurringFrequency(task.getRecurringFrequency())
                .recurringTime(task.getRecurringTime())
                .currentStreak(task.getCurrentStreak())
                .longestStreak(task.getLongestStreak())
                .totalCompleted(task.getTotalCompleted())
                .subTasks(subTasks)
                .hasReview(task.getReview() != null)
                .progressPercent(progressPercent)
                .createdAt(task.getCreatedAt())
                .updatedAt(task.getUpdatedAt())
                .build();
    }
}