package com.studyflow.controller;

import com.studyflow.dto.*;
import com.studyflow.security.UserPrincipal;
import com.studyflow.service.GoalService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/goals")
@RequiredArgsConstructor
@Tag(name = "学习目标", description = "目标 CRUD 操作")
public class GoalController {

    private final GoalService goalService;

    @Operation(summary = "获取目标列表", description = "获取当前用户的所有目标")
    @GetMapping
    public ResponseEntity<ApiResponse<List<GoalResponse>>> getGoals(
            @AuthenticationPrincipal UserPrincipal userPrincipal) {
        List<GoalResponse> goals = goalService.getGoals(userPrincipal);
        return ResponseEntity.ok(ApiResponse.success(goals));
    }

    @Operation(summary = "获取目标详情", description = "根据 ID 获取单个目标详情")
    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<GoalResponse>> getGoal(
            @PathVariable Long id,
            @AuthenticationPrincipal UserPrincipal userPrincipal) {
        GoalResponse goal = goalService.getGoal(id, userPrincipal);
        return ResponseEntity.ok(ApiResponse.success(goal));
    }

    @Operation(summary = "创建目标", description = "创建新的学习目标")
    @PostMapping
    public ResponseEntity<ApiResponse<GoalResponse>> createGoal(
            @Valid @RequestBody CreateGoalRequest request,
            @AuthenticationPrincipal UserPrincipal userPrincipal) {
        GoalResponse goal = goalService.createGoal(request, userPrincipal);
        return ResponseEntity.ok(ApiResponse.success("目标创建成功", goal));
    }

    @Operation(summary = "更新目标", description = "更新现有目标信息")
    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<GoalResponse>> updateGoal(
            @PathVariable Long id,
            @RequestBody UpdateGoalRequest request,
            @AuthenticationPrincipal UserPrincipal userPrincipal) {
        GoalResponse goal = goalService.updateGoal(id, request, userPrincipal);
        return ResponseEntity.ok(ApiResponse.success("目标更新成功", goal));
    }

    @Operation(summary = "删除目标", description = "删除目标及其关联任务")
    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteGoal(
            @PathVariable Long id,
            @AuthenticationPrincipal UserPrincipal userPrincipal) {
        goalService.deleteGoal(id, userPrincipal);
        return ResponseEntity.ok(ApiResponse.success("目标删除成功", null));
    }
}