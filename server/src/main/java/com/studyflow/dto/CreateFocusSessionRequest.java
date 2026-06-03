package com.studyflow.dto;

import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class CreateFocusSessionRequest {

    private Long taskId;

    @NotNull(message = "专注时长不能为空")
    private Integer duration;  // 分钟
}