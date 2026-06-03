package com.studyflow.service;

import com.studyflow.dto.*;
import com.studyflow.entity.User;
import com.studyflow.entity.UserSettings;
import com.studyflow.exception.BusinessException;
import com.studyflow.repository.UserSettingsRepository;
import com.studyflow.security.UserPrincipal;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class SettingsService {

    private final UserSettingsRepository userSettingsRepository;

    public SettingsResponse getSettings(UserPrincipal userPrincipal) {
        UserSettings settings = userSettingsRepository.findByUserId(userPrincipal.getId())
                .orElseGet(() -> createDefaultSettings(userPrincipal));
        return SettingsResponse.from(settings);
    }

    @Transactional
    public SettingsResponse updateSettings(UpdateSettingsRequest request, UserPrincipal userPrincipal) {
        UserSettings settings = userSettingsRepository.findByUserId(userPrincipal.getId())
                .orElseGet(() -> createDefaultSettings(userPrincipal));

        if (request.getTheme() != null) {
            settings.setTheme(request.getTheme());
        }
        if (request.getSidebarCollapsed() != null) {
            settings.setSidebarCollapsed(request.getSidebarCollapsed());
        }
        if (request.getFocusDuration() != null) {
            settings.setFocusDuration(request.getFocusDuration());
        }
        if (request.getBreakDuration() != null) {
            settings.setBreakDuration(request.getBreakDuration());
        }
        if (request.getLongBreakDuration() != null) {
            settings.setLongBreakDuration(request.getLongBreakDuration());
        }
        if (request.getCyclesBeforeLongBreak() != null) {
            settings.setCyclesBeforeLongBreak(request.getCyclesBeforeLongBreak());
        }
        if (request.getReviewNotificationEnabled() != null) {
            settings.setReviewNotificationEnabled(request.getReviewNotificationEnabled());
        }
        if (request.getReviewNotificationTime() != null) {
            settings.setReviewNotificationTime(request.getReviewNotificationTime());
        }
        if (request.getFocusNotificationEnabled() != null) {
            settings.setFocusNotificationEnabled(request.getFocusNotificationEnabled());
        }

        settings = userSettingsRepository.save(settings);
        return SettingsResponse.from(settings);
    }

    private UserSettings createDefaultSettings(UserPrincipal userPrincipal) {
        UserSettings newSettings = UserSettings.builder()
                .user(User.builder().id(userPrincipal.getId()).username(userPrincipal.getUsername()).build())
                .build();
        return userSettingsRepository.save(newSettings);
    }
}