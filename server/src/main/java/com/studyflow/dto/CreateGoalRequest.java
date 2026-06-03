package com.studyflow.dto;

import com.studyflow.entity.Goal;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Data;
import org.springframework.format.annotation.DateTimeFormat;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
public class CreateGoalRequest {

    @NotBlank(message = "目标标题不能为空")
    @Size(max = 200, message = "标题长度不能超过 200 个字符")
    private String title;

    private String description;

    @NotNull(message = "目标类型不能为空")
    private Goal.GoalType type;

    @NotNull(message = "优先级不能为空")
    private Goal.Priority priority;

    @DateTimeFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss")
    private LocalDateTime deadline;
}