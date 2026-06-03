package com.studyflow.repository;

import com.studyflow.entity.Goal;
import com.studyflow.entity.User;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface GoalRepository extends JpaRepository<Goal, Long> {

    List<Goal> findByUserOrderByCreatedAtDesc(User user);

    Page<Goal> findByUserOrderByCreatedAtDesc(User user, Pageable pageable);

    List<Goal> findByUserAndStatusOrderByCreatedAtDesc(User user, Goal.GoalStatus status);

    Page<Goal> findByUserAndStatusOrderByCreatedAtDesc(User user, Goal.GoalStatus status, Pageable pageable);

    Optional<Goal> findByIdAndUser(Long id, User user);

    long countByUser(User user);
}
