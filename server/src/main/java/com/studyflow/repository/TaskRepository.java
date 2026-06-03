package com.studyflow.repository;

import com.studyflow.entity.Goal;
import com.studyflow.entity.Task;
import com.studyflow.entity.User;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface TaskRepository extends JpaRepository<Task, Long> {

    List<Task> findByGoal(Goal goal);

    List<Task> findByGoalOrderBySortOrderAsc(Goal goal);

    @Query("SELECT t FROM Task t WHERE t.goal.user = :user ORDER BY t.priority, t.dueDate ASC")
    List<Task> findByUserOrderByPriority(@Param("user") User user);

    @Query("SELECT t FROM Task t WHERE t.goal.user = :user ORDER BY t.priority, t.dueDate ASC")
    Page<Task> findByUserOrderByPriority(@Param("user") User user, Pageable pageable);

    @Query("SELECT t FROM Task t WHERE t.goal.user = :user AND t.status = :status ORDER BY t.priority, t.dueDate ASC")
    List<Task> findByUserAndStatus(@Param("user") User user, @Param("status") Task.TaskStatus status);

    @Query("SELECT t FROM Task t WHERE t.goal.user = :user AND t.status = :status ORDER BY t.priority, t.dueDate ASC")
    Page<Task> findByUserAndStatus(@Param("user") User user, @Param("status") Task.TaskStatus status, Pageable pageable);

    @Query("SELECT t FROM Task t WHERE t.goal.user = :user AND t.dueDate <= :date AND t.status != 'COMPLETED' ORDER BY t.dueDate ASC")
    List<Task> findOverdueTasks(@Param("user") User user, @Param("date") LocalDateTime date);

    @Query("SELECT t FROM Task t WHERE t.goal.user = :user AND t.dueDate BETWEEN :start AND :end AND t.status != 'COMPLETED' ORDER BY t.dueDate ASC")
    List<Task> findTodayTasks(@Param("user") User user, @Param("start") LocalDateTime start, @Param("end") LocalDateTime end);

    Optional<Task> findByIdAndGoalUser(Long id, User user);

    long countByGoal(Goal goal);

    long countByGoalAndStatus(Goal goal, Task.TaskStatus status);
}
