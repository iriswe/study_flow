package com.studyflow.controller;

import com.studyflow.dto.*;
import com.studyflow.security.UserPrincipal;
import com.studyflow.service.StatsService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/stats")
@RequiredArgsConstructor
@Tag(name = "统计分析", description = "学习数据统计")
public class StatsController {

    private final StatsService statsService;

    @Operation(summary = "概览统计", description = "获取 Dashboard 所需的统计数据")
    @GetMapping("/overview")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getOverview(
            @AuthenticationPrincipal UserPrincipal userPrincipal) {
        Map<String, Object> overview = statsService.getOverview(userPrincipal);
        return ResponseEntity.ok(ApiResponse.success(overview));
    }

    @Operation(summary = "学习趋势", description = "获取最近 N 天的学习时长趋势")
    @GetMapping("/learning")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getLearningStats(
            @AuthenticationPrincipal UserPrincipal userPrincipal,
            @RequestParam(defaultValue = "7") int days) {
        Map<String, Object> stats = statsService.getLearningStats(userPrincipal, days);
        return ResponseEntity.ok(ApiResponse.success(stats));
    }

    @Operation(summary = "复习统计", description = "获取复习统计数据")
    @GetMapping("/review")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getReviewStats(
            @AuthenticationPrincipal UserPrincipal userPrincipal) {
        Map<String, Object> stats = statsService.getReviewStats(userPrincipal);
        return ResponseEntity.ok(ApiResponse.success(stats));
    }
}