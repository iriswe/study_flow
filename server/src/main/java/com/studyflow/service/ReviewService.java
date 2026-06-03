package com.studyflow.service;

import com.studyflow.dto.*;
import com.studyflow.entity.Goal;
import com.studyflow.entity.Review;
import com.studyflow.entity.Task;
import com.studyflow.entity.User;
import com.studyflow.exception.BusinessException;
import com.studyflow.repository.GoalRepository;
import com.studyflow.repository.ReviewRepository;
import com.studyflow.repository.TaskRepository;
import com.studyflow.security.UserPrincipal;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class ReviewService {

    private final ReviewRepository reviewRepository;
    private final TaskRepository taskRepository;
    private final GoalRepository goalRepository;

    @Transactional(readOnly = true)
    public List<ReviewResponse> getTodayReviews(UserPrincipal userPrincipal) {
        User user = getUser(userPrincipal);
        List<Review> reviews = reviewRepository.findTodayReviews(user, LocalDate.now());

        return reviews.stream()
                .map(ReviewResponse::from)
                .collect(Collectors.toList());
    }

    @Transactional
    public ReviewResponse review(Long id, ReviewRequest request, UserPrincipal userPrincipal) {
        User user = getUser(userPrincipal);
        Review review = reviewRepository.findById(id)
                .filter(r -> r.getUser().getId().equals(user.getId()))
                .orElseThrow(() -> new BusinessException(404, "复习记录不存在"));

        // 保存独立复习笔记
        if (request.getNote() != null) {
            review.setNote(request.getNote());
        }

        // FSRS 算法计算下次复习间隔
        calculateNextReview(review, request.getResponse());

        review.setLastResponse(request.getResponse());
        review.setReviewCount(review.getReviewCount() + 1);
        review.setStatus(Review.ReviewStatus.PENDING);

        review = reviewRepository.save(review);
        return ReviewResponse.from(review);
    }

    @Transactional
    public void skipReview(Long id, UserPrincipal userPrincipal) {
        User user = getUser(userPrincipal);
        Review review = reviewRepository.findById(id)
                .filter(r -> r.getUser().getId().equals(user.getId()))
                .orElseThrow(() -> new BusinessException(404, "复习记录不存在"));

        // 跳过：将复习日期推迟一天
        review.setNextReviewDate(LocalDate.now().plusDays(1));
        reviewRepository.save(review);
    }

    @Transactional
    public void delayReview(Long id, int days, UserPrincipal userPrincipal) {
        User user = getUser(userPrincipal);
        Review review = reviewRepository.findById(id)
                .filter(r -> r.getUser().getId().equals(user.getId()))
                .orElseThrow(() -> new BusinessException(404, "复习记录不存在"));

        // 延后复习
        review.setNextReviewDate(LocalDate.now().plusDays(days));
        reviewRepository.save(review);
    }

    @Transactional
    public void createReviewForTask(Long taskId, UserPrincipal userPrincipal) {
        User user = getUser(userPrincipal);
        Task task = taskRepository.findByIdAndGoalUser(taskId, user)
                .orElseThrow(() -> new BusinessException(404, "任务不存在"));

        Review review = Review.builder()
                .user(user)
                .task(task)
                .nextReviewDate(LocalDate.now())
                .stability(BigDecimal.valueOf(1.0))
                .difficulty(BigDecimal.valueOf(5.0))
                .status(Review.ReviewStatus.PENDING)
                .interval(1)
                .build();

        reviewRepository.save(review);
    }

    /**
     * FSRS 算法简化实现
     */
    private void calculateNextReview(Review review, Review.ReviewResponse response) {
        BigDecimal stability = review.getStability();
        BigDecimal difficulty = review.getDifficulty();
        int currentInterval = review.getInterval();

        if (response == Review.ReviewResponse.FORGOT) {
            // 忘记：重置间隔为1天，降低稳定度
            review.setInterval(1);
            review.setStability(BigDecimal.valueOf(0.1));
            review.setNextReviewDate(LocalDate.now().plusDays(1));
        } else if (response == Review.ReviewResponse.FUZZY) {
            // 模糊：缩短间隔
            int newInterval = Math.max(1, (int) (currentInterval * 0.5));
            review.setInterval(newInterval);
            review.setStability(stability.multiply(BigDecimal.valueOf(0.8)));
            review.setNextReviewDate(LocalDate.now().plusDays(newInterval));
        } else if (response == Review.ReviewResponse.GOOD) {
            // 良好：按固定倍数增加间隔
            int newInterval = (int) (currentInterval * 1.5);
            newInterval = Math.min(newInterval, 365); // 上限365天
            review.setInterval(newInterval);
            review.setStability(stability.multiply(BigDecimal.valueOf(1.2)));
            review.setNextReviewDate(LocalDate.now().plusDays(newInterval));
        } else {
            // 简单：大幅增加间隔
            int newInterval = (int) (currentInterval * 2.5);
            newInterval = Math.min(newInterval, 365);
            review.setInterval(newInterval);
            review.setStability(stability.multiply(BigDecimal.valueOf(1.4)));
            review.setDifficulty(difficulty.subtract(BigDecimal.valueOf(0.15)));
            review.setNextReviewDate(LocalDate.now().plusDays(newInterval));
        }

        // 调整难度范围
        if (review.getDifficulty().compareTo(BigDecimal.ZERO) < 0) {
            review.setDifficulty(BigDecimal.ZERO);
        }
        if (review.getDifficulty().compareTo(BigDecimal.valueOf(10)) > 0) {
            review.setDifficulty(BigDecimal.valueOf(10));
        }

        // 达到一定稳定度后标记为已掌握
        if (review.getStability().compareTo(BigDecimal.valueOf(21)) > 0) {
            review.setStatus(Review.ReviewStatus.MASTERED);
        }
    }

    private User getUser(UserPrincipal userPrincipal) {
        return User.builder()
                .id(userPrincipal.getId())
                .username(userPrincipal.getUsername())
                .build();
    }

    @Transactional(readOnly = true)
    public Map<String, Object> getReviewStatsSummary(UserPrincipal userPrincipal) {
        User user = getUser(userPrincipal);
        Map<String, Object> stats = new HashMap<>();

        // 今日到期数
        LocalDate today = LocalDate.now();
        long todayDue = reviewRepository.countPendingReviews(user, today);
        stats.put("todayDue", todayDue);

        // 本周到期的数量
        LocalDate weekEnd = today.plusDays(7);
        List<Review> weekReviews = reviewRepository.findTodayReviews(user, weekEnd);
        stats.put("weekDue", weekReviews.size());

        // 平均记忆稳定度
        List<Review> allReviews = reviewRepository.findByUserAndStatus(user, Review.ReviewStatus.PENDING);
        allReviews.addAll(reviewRepository.findByUserAndStatus(user, Review.ReviewStatus.REVIEWING));
        allReviews.addAll(reviewRepository.findByUserAndStatus(user, Review.ReviewStatus.MASTERED));
        if (!allReviews.isEmpty()) {
            double avgStability = allReviews.stream()
                    .mapToDouble(r -> r.getStability() != null ? r.getStability().doubleValue() : 0.0)
                    .average()
                    .orElse(0.0);
            // 稳定度范围 0-21，转换为百分比 (21 = 100%)
            double stabilityPercent = Math.min(100, (avgStability / 21.0) * 100);
            stats.put("avgStabilityPercent", (int) Math.round(stabilityPercent));
        } else {
            stats.put("avgStabilityPercent", 0);
        }

        return stats;
    }
}
