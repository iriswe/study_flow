package com.studyflow.repository;

import com.studyflow.entity.Review;
import com.studyflow.entity.Task;
import com.studyflow.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

@Repository
public interface ReviewRepository extends JpaRepository<Review, Long> {

    @Query("SELECT r FROM Review r WHERE r.user = :user AND r.nextReviewDate <= :date AND r.status != 'MASTERED' ORDER BY r.nextReviewDate ASC")
    List<Review> findTodayReviews(@Param("user") User user, @Param("date") LocalDate date);

    @Query("SELECT r FROM Review r WHERE r.user = :user AND r.nextReviewDate = :date AND r.status != 'MASTERED' ORDER BY r.nextReviewDate ASC")
    List<Review> findPendingReviewsByDate(@Param("user") User user, @Param("date") LocalDate date);

    @Query("SELECT r FROM Review r WHERE r.user = :user AND r.task = :task AND r.status != 'MASTERED' ORDER BY r.createdAt DESC")
    List<Review> findActiveByUserAndTask(@Param("user") User user, @Param("task") Task task);

    @Query("SELECT r FROM Review r WHERE r.user = :user AND r.status = :status ORDER BY r.nextReviewDate ASC")
    List<Review> findByUserAndStatus(@Param("user") User user, @Param("status") Review.ReviewStatus status);

    long countByUserAndStatus(User user, Review.ReviewStatus status);

    @Query("SELECT COUNT(r) FROM Review r WHERE r.user = :user AND r.nextReviewDate <= :date AND r.status != 'MASTERED'")
    long countPendingReviews(@Param("user") User user, @Param("date") LocalDate date);
}
