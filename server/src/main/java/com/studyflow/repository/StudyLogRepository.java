package com.studyflow.repository;

import com.studyflow.entity.Task;
import com.studyflow.entity.User;
import com.studyflow.entity.StudyLog;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface StudyLogRepository extends JpaRepository<StudyLog, Long> {

    Page<StudyLog> findByUserOrderByCreatedAtDesc(User user, Pageable pageable);

    @Query("SELECT s FROM StudyLog s WHERE s.user = :user AND s.task.goal.id = :goalId ORDER BY s.createdAt DESC")
    List<StudyLog> findByUserAndGoalId(@Param("user") User user, @Param("goalId") Long goalId);

    List<StudyLog> findByUserAndCreatedAtBetweenOrderByCreatedAtDesc(
            User user, LocalDateTime start, LocalDateTime end);

    List<StudyLog> findByTask(Task task);

    @Query("SELECT COALESCE(SUM(s.duration), 0) FROM StudyLog s WHERE s.user = :user AND s.createdAt >= :start")
    Integer sumDurationByUserAndDate(@Param("user") User user, @Param("start") LocalDateTime start);

    @Query("SELECT COALESCE(SUM(s.duration), 0) FROM StudyLog s WHERE s.user = :user AND s.createdAt BETWEEN :start AND :end")
    Integer sumDurationByUserAndDateRange(
            @Param("user") User user,
            @Param("start") LocalDateTime start,
            @Param("end") LocalDateTime end);

    @Query("SELECT COUNT(DISTINCT DATE(s.createdAt)) FROM StudyLog s WHERE s.user = :user AND s.createdAt >= :start")
    Long countStudyDaysByUser(@Param("user") User user, @Param("start") LocalDateTime start);
}