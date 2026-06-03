package com.studyflow.service;

import com.studyflow.dto.*;
import com.studyflow.entity.*;
import com.studyflow.repository.*;
import com.studyflow.security.UserPrincipal;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
@RequiredArgsConstructor
public class StatsService {

    private final TaskRepository taskRepository;
    private final GoalRepository goalRepository;
    private final StudyLogRepository studyLogRepository;
    private final ReviewRepository reviewRepository;
    private final SubTaskRepository subTaskRepository;

    @Transactional(readOnly = true)
    public Map<String, Object> getOverview(UserPrincipal userPrincipal) {
        User user = getUser(userPrincipal);
        Map<String, Object> overview = new HashMap<>();

        // 今日任务数（截止日期在今天及之前的未完成任务）
        LocalDateTime now = LocalDateTime.now();
        List<Task> todayTasks = taskRepository.findTodayTasks(user, now.with(LocalTime.MIN), now.with(LocalTime.MAX));
        overview.put("todayTasks", todayTasks.size());

        // 今日复习数
        long pendingReviews = reviewRepository.countPendingReviews(user, LocalDate.now());
        overview.put("todayReviews", pendingReviews);

        // 今日完成数
        long completedToday = taskRepository.findByUserAndStatus(user, Task.TaskStatus.COMPLETED).stream()
                .filter(t -> t.getUpdatedAt() != null &&
                        t.getUpdatedAt().toLocalDate().equals(LocalDate.now()))
                .count();
        overview.put("completedToday", completedToday);

        // 今日学习时长
        Integer todayDuration = studyLogRepository.sumDurationByUserAndDate(user, now.with(LocalTime.MIN));
        overview.put("todayStudyDuration", todayDuration != null ? todayDuration : 0);

        // 连续学习天数（简化版：从第一条学习记录开始算）
        LocalDateTime oneYearAgo = LocalDate.now().minusYears(1).atStartOfDay();
        Long studyDays = studyLogRepository.countStudyDaysByUser(user, oneYearAgo);
        overview.put("consecutiveDays", studyDays != null ? studyDays : 0);

        // 总体进度
        long totalGoals = goalRepository.countByUser(user);
        long totalTasks = taskRepository.findByUserOrderByPriority(user).size();
        long completedTasks = taskRepository.findByUserAndStatus(user, Task.TaskStatus.COMPLETED).size();
        overview.put("totalGoals", totalGoals);
        overview.put("totalTasks", totalTasks);
        overview.put("completedTasks", completedTasks);
        overview.put("completionRate", totalTasks > 0 ?
                BigDecimal.valueOf(completedTasks * 100).divide(BigDecimal.valueOf(totalTasks), 2, BigDecimal.ROUND_HALF_UP) :
                BigDecimal.ZERO);

        return overview;
    }

    @Transactional(readOnly = true)
    public Map<String, Object> getLearningStats(UserPrincipal userPrincipal, int days) {
        User user = getUser(userPrincipal);
        Map<String, Object> stats = new HashMap<>();

        LocalDateTime startDate = LocalDateTime.now().minusDays(days);

        // 按日期分组的学习时长
        List<StudyLog> logs = studyLogRepository.findByUserAndCreatedAtBetweenOrderByCreatedAtDesc(user, startDate, LocalDateTime.now());
        Map<String, Integer> dailyDuration = new HashMap<>();
        for (StudyLog log : logs) {
            String dateKey = log.getCreatedAt().toLocalDate().toString();
            dailyDuration.merge(dateKey, log.getDuration(), Integer::sum);
        }
        stats.put("dailyDuration", dailyDuration);

        // 总学习时长
        int totalDuration = logs.stream().mapToInt(StudyLog::getDuration).sum();
        stats.put("totalDuration", totalDuration);

        // 平均每日学习时长
        stats.put("avgDailyDuration", days > 0 ? totalDuration / days : 0);

        return stats;
    }

    @Transactional(readOnly = true)
    public Map<String, Object> getReviewStats(UserPrincipal userPrincipal) {
        User user = getUser(userPrincipal);
        Map<String, Object> stats = new HashMap<>();

        long pendingCount = reviewRepository.countByUserAndStatus(user, Review.ReviewStatus.PENDING);
        long reviewingCount = reviewRepository.countByUserAndStatus(user, Review.ReviewStatus.REVIEWING);
        long masteredCount = reviewRepository.countByUserAndStatus(user, Review.ReviewStatus.MASTERED);

        stats.put("pendingCount", pendingCount);
        stats.put("reviewingCount", reviewingCount);
        stats.put("masteredCount", masteredCount);
        stats.put("totalCount", pendingCount + reviewingCount + masteredCount);

        return stats;
    }

    private User getUser(UserPrincipal userPrincipal) {
        return User.builder()
                .id(userPrincipal.getId())
                .username(userPrincipal.getUsername())
                .build();
    }
}