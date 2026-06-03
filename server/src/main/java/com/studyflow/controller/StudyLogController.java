package com.studyflow.controller;

import com.studyflow.dto.*;
import com.studyflow.security.UserPrincipal;
import com.studyflow.service.StudyLogService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;

@RestController
@RequestMapping("/study-logs")
@RequiredArgsConstructor
@Tag(name = "学习记录", description = "学习时长记录与笔记")
public class StudyLogController {

    private final StudyLogService studyLogService;

    @Operation(summary = "获取学习记录", description = "分页获取当前用户的学习记录")
    @GetMapping
    public ResponseEntity<ApiResponse<List<StudyLogResponse>>> getStudyLogs(
            @AuthenticationPrincipal UserPrincipal userPrincipal,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        Pageable pageable = PageRequest.of(page, size);
        List<StudyLogResponse> logs = studyLogService.getStudyLogs(userPrincipal, pageable);
        return ResponseEntity.ok(ApiResponse.success(logs));
    }

    @Operation(summary = "按目标获取笔记", description = "获取指定目标的关联笔记")
    @GetMapping("/goal/{goalId}")
    public ResponseEntity<ApiResponse<List<StudyLogResponse>>> getStudyLogsByGoalId(
            @PathVariable Long goalId,
            @AuthenticationPrincipal UserPrincipal userPrincipal) {
        List<StudyLogResponse> logs = studyLogService.getStudyLogsByGoalId(userPrincipal, goalId);
        return ResponseEntity.ok(ApiResponse.success(logs));
    }

    @Operation(summary = "按日期范围查询", description = "获取指定日期范围的学习记录")
    @GetMapping("/date-range")
    public ResponseEntity<ApiResponse<List<StudyLogResponse>>> getStudyLogsByDateRange(
            @AuthenticationPrincipal UserPrincipal userPrincipal,
            @RequestParam LocalDateTime start,
            @RequestParam LocalDateTime end) {
        List<StudyLogResponse> logs = studyLogService.getStudyLogsByDateRange(userPrincipal, start, end);
        return ResponseEntity.ok(ApiResponse.success(logs));
    }

    @Operation(summary = "创建学习记录", description = "记录一次学习过程")
    @PostMapping
    public ResponseEntity<ApiResponse<StudyLogResponse>> createStudyLog(
            @Valid @RequestBody CreateStudyLogRequest request,
            @AuthenticationPrincipal UserPrincipal userPrincipal) {
        StudyLogResponse log = studyLogService.createStudyLog(request, userPrincipal);
        return ResponseEntity.ok(ApiResponse.success("学习记录创建成功", log));
    }

    @Operation(summary = "获取学习记录详情", description = "根据 ID 获取单条学习记录")
    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<StudyLogResponse>> getStudyLog(
            @PathVariable Long id,
            @AuthenticationPrincipal UserPrincipal userPrincipal) {
        StudyLogResponse log = studyLogService.getStudyLog(id, userPrincipal);
        return ResponseEntity.ok(ApiResponse.success(log));
    }

    @Operation(summary = "更新学习记录", description = "更新已有学习记录")
    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<StudyLogResponse>> updateStudyLog(
            @PathVariable Long id,
            @Valid @RequestBody CreateStudyLogRequest request,
            @AuthenticationPrincipal UserPrincipal userPrincipal) {
        StudyLogResponse log = studyLogService.updateStudyLog(id, request, userPrincipal);
        return ResponseEntity.ok(ApiResponse.success("学习记录更新成功", log));
    }

    @Operation(summary = "删除学习记录", description = "删除指定的学习记录")
    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteStudyLog(
            @PathVariable Long id,
            @AuthenticationPrincipal UserPrincipal userPrincipal) {
        studyLogService.deleteStudyLog(id, userPrincipal);
        return ResponseEntity.ok(ApiResponse.success("学习记录删除成功", null));
    }
}