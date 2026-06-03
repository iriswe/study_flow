package com.studyflow.repository;

import com.studyflow.entity.FocusSession;
import com.studyflow.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface FocusSessionRepository extends JpaRepository<FocusSession, Long> {

    List<FocusSession> findByUserOrderByCreatedAtDesc(User user);

    @Query("SELECT fs FROM FocusSession fs WHERE fs.user = :user AND fs.createdAt >= :start AND fs.createdAt <= :end ORDER BY fs.createdAt DESC")
    List<FocusSession> findByUserAndDateRange(
            @Param("user") User user,
            @Param("start") LocalDateTime start,
            @Param("end") LocalDateTime end);

    @Query("SELECT COALESCE(SUM(fs.actualDuration), 0) FROM FocusSession fs WHERE fs.user = :user AND fs.createdAt >= :start AND fs.status = 'COMPLETED'")
    Integer sumCompletedDurationByUserAndDate(@Param("user") User user, @Param("start") LocalDateTime start);

    @Query("SELECT COUNT(fs) FROM FocusSession fs WHERE fs.user = :user AND fs.status = 'COMPLETED' AND fs.createdAt >= :start")
    Long countCompletedSessionsByUser(@Param("user") User user, @Param("start") LocalDateTime start);

    List<FocusSession> findByTaskId(Long taskId);
}