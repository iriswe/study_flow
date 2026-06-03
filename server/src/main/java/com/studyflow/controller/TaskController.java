package com.studyflow.controller;

import com.studyflow.dto.*;
import com.studyflow.security.UserPrincipal;
import com.studyflow.service.TaskService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/tasks")
@RequiredArgsConstructor
@Tag(name = "任务", description = "任务 CRUD 操作")
public class TaskController {

    private final TaskService taskService;

    @Operation(summary = "获取任务列表", description = "获取当前用户的所有任务")
    @GetMapping
    public ResponseEntity<ApiResponse<List<TaskResponse>>> getTasks(
            @AuthenticationPrincipal UserPrincipal userPrincipal,
            @RequestParam(required = false) Long goalId,
            @RequestParam(defaultValue = "false") boolean todayOnly) {
        List<TaskResponse> tasks = taskService.getTasks(userPrincipal, goalId, todayOnly);
        return ResponseEntity.ok(ApiResponse.success(tasks));
    }

    @Operation(summary = "获取任务详情", description = "根据 ID 获取单个任务详情")
    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<TaskResponse>> getTask(
            @PathVariable Long id,
            @AuthenticationPrincipal UserPrincipal userPrincipal) {
        TaskResponse task = taskService.getTask(id, userPrincipal);
        return ResponseEntity.ok(ApiResponse.success(task));
    }

    @Operation(summary = "创建任务", description = "在指定目标下创建新任务")
    @PostMapping
    public ResponseEntity<ApiResponse<TaskResponse>> createTask(
            @Valid @RequestBody CreateTaskRequest request,
            @AuthenticationPrincipal UserPrincipal userPrincipal) {
        TaskResponse task = taskService.createTask(request, userPrincipal);
        return ResponseEntity.ok(ApiResponse.success("任务创建成功", task));
    }

    @Operation(summary = "更新任务", description = "更新任务信息")
    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<TaskResponse>> updateTask(
            @PathVariable Long id,
            @Valid @RequestBody UpdateTaskRequest request,
            @AuthenticationPrincipal UserPrincipal userPrincipal) {
        TaskResponse task = taskService.updateTask(id, request, userPrincipal);
        return ResponseEntity.ok(ApiResponse.success("任务更新成功", task));
    }

    @Operation(summary = "完成任务", description = "标记任务为已完成")
    @PostMapping("/{id}/complete")
    public ResponseEntity<ApiResponse<TaskResponse>> completeTask(
            @PathVariable Long id,
            @AuthenticationPrincipal UserPrincipal userPrincipal) {
        TaskResponse task = taskService.completeTask(id, userPrincipal);
        return ResponseEntity.ok(ApiResponse.success("任务已完成", task));
    }

    @Operation(summary = "删除任务", description = "删除任务及其子任务")
    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteTask(
            @PathVariable Long id,
            @AuthenticationPrincipal UserPrincipal userPrincipal) {
        taskService.deleteTask(id, userPrincipal);
        return ResponseEntity.ok(ApiResponse.success("任务删除成功", null));
    }

    @Operation(summary = "取消完成任务", description = "取消任务的完成状态（习惯任务取消签到）")
    @PostMapping("/{id}/uncomplete")
    public ResponseEntity<ApiResponse<TaskResponse>> uncompleteTask(
            @PathVariable Long id,
            @AuthenticationPrincipal UserPrincipal userPrincipal) {
        TaskResponse task = taskService.uncompleteTask(id, userPrincipal);
        return ResponseEntity.ok(ApiResponse.success("已取消完成", task));
    }

    @Operation(summary = "批量创建子任务", description = "通过序列生成或粘贴导入批量创建子任务")
    @PostMapping("/{id}/subtasks/batch")
    public ResponseEntity<ApiResponse<TaskResponse>> batchCreateSubTasks(
            @PathVariable Long id,
            @Valid @RequestBody BatchCreateSubTaskRequest request,
            @AuthenticationPrincipal UserPrincipal userPrincipal) {
        TaskResponse task = taskService.batchCreateSubTasks(id, request, userPrincipal);
        return ResponseEntity.ok(ApiResponse.success("子任务批量创建成功", task));
    }

    @Operation(summary = "切换子任务状态", description = "完成或取消完成子任务")
    @PatchMapping("/{taskId}/subtasks/{subTaskId}/toggle")
    public ResponseEntity<ApiResponse<TaskResponse>> toggleSubTask(
            @PathVariable Long taskId,
            @PathVariable Long subTaskId,
            @AuthenticationPrincipal UserPrincipal userPrincipal) {
        TaskResponse task = taskService.toggleSubTask(taskId, subTaskId, userPrincipal);
        return ResponseEntity.ok(ApiResponse.success("子任务状态已更新", task));
    }
}