package com.studyflow.dto;

import com.studyflow.entity.UserSettings;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SettingsResponse {
    private Long id;
    private UserSettings.Theme theme;
    private Boolean sidebarCollapsed;
    private Integer focusDuration;
    private Integer breakDuration;
    private Integer longBreakDuration;
    private Integer cyclesBeforeLongBreak;
    private Boolean reviewNotificationEnabled;
    private String reviewNotificationTime;
    private Boolean focusNotificationEnabled;

    public static SettingsResponse from(UserSettings settings) {
        return SettingsResponse.builder()
                .id(settings.getId())
                .theme(settings.getTheme())
                .sidebarCollapsed(settings.getSidebarCollapsed())
                .focusDuration(settings.getFocusDuration())
                .breakDuration(settings.getBreakDuration())
                .longBreakDuration(settings.getLongBreakDuration())
                .cyclesBeforeLongBreak(settings.getCyclesBeforeLongBreak())
                .reviewNotificationEnabled(settings.getReviewNotificationEnabled())
                .reviewNotificationTime(settings.getReviewNotificationTime())
                .focusNotificationEnabled(settings.getFocusNotificationEnabled())
                .build();
    }
}