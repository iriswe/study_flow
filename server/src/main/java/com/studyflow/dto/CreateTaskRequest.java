package com.studyflow.dto;

import com.studyflow.entity.Goal;
import com.studyflow.entity.Task;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Data;
import org.springframework.format.annotation.DateTimeFormat;

import java.time.LocalDateTime;
import java.time.LocalTime;

@Data
public class CreateTaskRequest {

    @NotNull(message = "目标ID不能为空")
    private Long goalId;

    @NotBlank(message = "任务标题不能为空")
    @Size(max = 200, message = "标题长度不能超过 200 个字符")
    private String title;

    @NotNull(message = "优先级不能为空")
    private Goal.Priority priority;

    // 任务类型：默认进度任务
    private Task.TaskType taskType = Task.TaskType.PROGRESSION;

    // 习惯任务专用字段
    private Task.RecurringFrequency recurringFrequency;  // DAILY, WEEKLY, WEEKDAYS
    private LocalTime recurringTime;  // 每日几点

    private Integer estimateMinutes;

    @DateTimeFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss")
    private LocalDateTime dueDate;

    private String note;

    // 子任务列表（可选）
    private java.util.List<String> subTasks;
}