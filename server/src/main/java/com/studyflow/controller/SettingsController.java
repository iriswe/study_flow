package com.studyflow.controller;

import com.studyflow.dto.*;
import com.studyflow.security.UserPrincipal;
import com.studyflow.service.SettingsService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/settings")
@RequiredArgsConstructor
@Tag(name = "设置", description = "用户设置管理")
public class SettingsController {

    private final SettingsService settingsService;

    @Operation(summary = "获取设置", description = "获取当前用户的设置")
    @GetMapping
    public ResponseEntity<ApiResponse<SettingsResponse>> getSettings(
            @AuthenticationPrincipal UserPrincipal userPrincipal) {
        SettingsResponse settings = settingsService.getSettings(userPrincipal);
        return ResponseEntity.ok(ApiResponse.success(settings));
    }

    @Operation(summary = "更新设置", description = "更新用户设置")
    @PutMapping
    public ResponseEntity<ApiResponse<SettingsResponse>> updateSettings(
            @RequestBody UpdateSettingsRequest request,
            @AuthenticationPrincipal UserPrincipal userPrincipal) {
        SettingsResponse settings = settingsService.updateSettings(request, userPrincipal);
        return ResponseEntity.ok(ApiResponse.success("设置已更新", settings));
    }

    @Operation(summary = "手动同步", description = "触发数据同步，返回最新设置")
    @PostMapping("/sync")
    public ResponseEntity<ApiResponse<SettingsResponse>> syncSettings(
            @AuthenticationPrincipal UserPrincipal userPrincipal) {
        SettingsResponse settings = settingsService.getSettings(userPrincipal);
        return ResponseEntity.ok(ApiResponse.success("同步完成", settings));
    }
}