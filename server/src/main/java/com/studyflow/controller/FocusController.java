package com.studyflow.controller;

import com.studyflow.dto.*;
import com.studyflow.security.UserPrincipal;
import com.studyflow.service.FocusService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/focus")
@RequiredArgsConstructor
@Tag(name = "专注模式", description = "番茄钟专注")
public class FocusController {

    private final FocusService focusService;

    @Operation(summary = "获取专注记录", description = "获取当前用户的所有专注记录")
    @GetMapping
    public ResponseEntity<ApiResponse<List<FocusSessionResponse>>> getSessions(
            @AuthenticationPrincipal UserPrincipal userPrincipal) {
        List<FocusSessionResponse> sessions = focusService.getSessions(userPrincipal);
        return ResponseEntity.ok(ApiResponse.success(sessions));
    }

    @Operation(summary = "获取今日专注", description = "获取今日的专注记录")
    @GetMapping("/today")
    public ResponseEntity<ApiResponse<List<FocusSessionResponse>>> getTodaySessions(
            @AuthenticationPrincipal UserPrincipal userPrincipal) {
        List<FocusSessionResponse> sessions = focusService.getTodaySessions(userPrincipal);
        return ResponseEntity.ok(ApiResponse.success(sessions));
    }

    @Operation(summary = "创建专注会话", description = "创建一个新的番茄钟会话")
    @PostMapping
    public ResponseEntity<ApiResponse<FocusSessionResponse>> createSession(
            @Valid @RequestBody CreateFocusSessionRequest request,
            @AuthenticationPrincipal UserPrincipal userPrincipal) {
        FocusSessionResponse session = focusService.createSession(request, userPrincipal);
        return ResponseEntity.ok(ApiResponse.success("专注记录已创建", session));
    }

    @Operation(summary = "开始专注", description = "开始计时专注")
    @PostMapping("/{id}/start")
    public ResponseEntity<ApiResponse<FocusSessionResponse>> startSession(
            @PathVariable Long id,
            @AuthenticationPrincipal UserPrincipal userPrincipal) {
        FocusSessionResponse session = focusService.startSession(id, userPrincipal);
        return ResponseEntity.ok(ApiResponse.success("专注已开始", session));
    }

    @Operation(summary = "完成专注", description = "结束专注并记录实际时长")
    @PostMapping("/{id}/complete")
    public ResponseEntity<ApiResponse<FocusSessionResponse>> completeSession(
            @PathVariable Long id,
            @RequestParam(defaultValue = "0") int actualDuration,
            @AuthenticationPrincipal UserPrincipal userPrincipal) {
        FocusSessionResponse session = focusService.completeSession(id, actualDuration, userPrincipal);
        return ResponseEntity.ok(ApiResponse.success("专注已完成", session));
    }

    @Operation(summary = "中断专注", description = "提前结束专注")
    @PostMapping("/{id}/interrupt")
    public ResponseEntity<ApiResponse<FocusSessionResponse>> interruptSession(
            @PathVariable Long id,
            @RequestParam(defaultValue = "0") int actualDuration,
            @AuthenticationPrincipal UserPrincipal userPrincipal) {
        FocusSessionResponse session = focusService.interruptSession(id, actualDuration, userPrincipal);
        return ResponseEntity.ok(ApiResponse.success("专注已中断", session));
    }

    @Operation(summary = "今日专注时长", description = "获取今日累计专注时长")
    @GetMapping("/today-duration")
    public ResponseEntity<ApiResponse<Integer>> getTodayFocusDuration(
            @AuthenticationPrincipal UserPrincipal userPrincipal) {
        Integer duration = focusService.getTodayFocusDuration(userPrincipal);
        return ResponseEntity.ok(ApiResponse.success(duration));
    }
}