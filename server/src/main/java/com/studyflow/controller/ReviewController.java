package com.studyflow.controller;

import com.studyflow.dto.*;
import com.studyflow.security.UserPrincipal;
import com.studyflow.service.ReviewService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/reviews")
@RequiredArgsConstructor
@Tag(name = "复习系统", description = "FSRS 间隔复习")
public class ReviewController {

    private final ReviewService reviewService;

    @Operation(summary = "获取今日复习", description = "获取今日应复习的项目列表")
    @GetMapping("/today")
    public ResponseEntity<ApiResponse<List<ReviewResponse>>> getTodayReviews(
            @AuthenticationPrincipal UserPrincipal userPrincipal) {
        List<ReviewResponse> reviews = reviewService.getTodayReviews(userPrincipal);
        return ResponseEntity.ok(ApiResponse.success(reviews));
    }

    @Operation(summary = "执行复习", description = "提交复习反馈，更新下次复习时间")
    @PostMapping("/{id}/review")
    public ResponseEntity<ApiResponse<ReviewResponse>> review(
            @PathVariable Long id,
            @Valid @RequestBody ReviewRequest request,
            @AuthenticationPrincipal UserPrincipal userPrincipal) {
        ReviewResponse review = reviewService.review(id, request, userPrincipal);
        return ResponseEntity.ok(ApiResponse.success("复习完成", review));
    }

    @Operation(summary = "跳过复习", description = "将复习推迟到明天")
    @PostMapping("/{id}/skip")
    public ResponseEntity<ApiResponse<Void>> skipReview(
            @PathVariable Long id,
            @AuthenticationPrincipal UserPrincipal userPrincipal) {
        reviewService.skipReview(id, userPrincipal);
        return ResponseEntity.ok(ApiResponse.success("已跳过", null));
    }

    @Operation(summary = "延后复习", description = "将复习推迟指定天数")
    @PostMapping("/{id}/delay")
    public ResponseEntity<ApiResponse<Void>> delayReview(
            @PathVariable Long id,
            @RequestParam(defaultValue = "1") int days,
            @AuthenticationPrincipal UserPrincipal userPrincipal) {
        reviewService.delayReview(id, days, userPrincipal);
        return ResponseEntity.ok(ApiResponse.success("已延后", null));
    }

    @Operation(summary = "为任务创建复习计划", description = "为指定任务开启 FSRS 复习")
    @PostMapping("/task/{taskId}")
    public ResponseEntity<ApiResponse<Void>> createReviewForTask(
            @PathVariable Long taskId,
            @AuthenticationPrincipal UserPrincipal userPrincipal) {
        reviewService.createReviewForTask(taskId, userPrincipal);
        return ResponseEntity.ok(ApiResponse.success("复习计划已创建", null));
    }

    @Operation(summary = "获取复习统计摘要", description = "获取今日到期、本周到期、平均记忆稳定度")
    @GetMapping("/stats")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getReviewStatsSummary(
            @AuthenticationPrincipal UserPrincipal userPrincipal) {
        Map<String, Object> stats = reviewService.getReviewStatsSummary(userPrincipal);
        return ResponseEntity.ok(ApiResponse.success(stats));
    }
}