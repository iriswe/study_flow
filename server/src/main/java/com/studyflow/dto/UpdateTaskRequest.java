package com.studyflow.dto;

import com.studyflow.entity.Goal;
import com.studyflow.entity.Task;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.Size;
import lombok.Data;
import org.springframework.format.annotation.DateTimeFormat;

import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;

@Data
public class UpdateTaskRequest {

    @Size(max = 200, message = "标题长度不能超过 200 个字符")
    private String title;

    private Long goalId;

    private Goal.Priority priority;

    private Task.TaskStatus status;

    private Task.TaskType taskType;

    private Task.RecurringFrequency recurringFrequency;

    private LocalTime recurringTime;

    @Min(value = 1, message = "预计时长最少为 1 分钟")
    @Max(value = 1440, message = "预计时长不能超过 24 小时")
    private Integer estimateMinutes;

    private Integer actualMinutes;

    @DateTimeFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss")
    private LocalDateTime dueDate;

    @Size(max = 2000, message = "备注长度不能超过 2000 个字符")
    private String note;

    private Integer sortOrder;

    private List<String> subTasks;
}