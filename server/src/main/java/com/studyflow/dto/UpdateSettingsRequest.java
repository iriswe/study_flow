package com.studyflow.dto;

import com.studyflow.entity.UserSettings;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import lombok.Data;

@Data
public class UpdateSettingsRequest {

    private UserSettings.Theme theme;
    private Boolean sidebarCollapsed;

    // 番茄钟设置
    @Min(value = 1, message = "专注时长不能少于1分钟")
    @Max(value = 120, message = "专注时长不能超过120分钟")
    private Integer focusDuration;

    @Min(value = 1, message = "休息时长不能少于1分钟")
    @Max(value = 30, message = "休息时长不能超过30分钟")
    private Integer breakDuration;

    @Min(value = 5, message = "长休息时长不能少于5分钟")
    @Max(value = 60, message = "长休息时长不能超过60分钟")
    private Integer longBreakDuration;

    @Min(value = 2, message = "循环次数不能少于2")
    @Max(value = 8, message = "循环次数不能超过8")
    private Integer cyclesBeforeLongBreak;

    // 通知设置
    private Boolean reviewNotificationEnabled;
    private String reviewNotificationTime;
    private Boolean focusNotificationEnabled;
}