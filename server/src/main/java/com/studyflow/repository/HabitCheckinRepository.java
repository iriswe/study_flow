package com.studyflow.repository;

import com.studyflow.entity.HabitCheckin;
import com.studyflow.entity.Task;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.Set;

@Repository
public interface HabitCheckinRepository extends JpaRepository<HabitCheckin, Long> {

    Optional<HabitCheckin> findByTaskAndCheckinDate(Task task, LocalDate date);

    List<HabitCheckin> findByTaskAndCheckinDateAfterOrderByCheckinDateDesc(Task task, LocalDate after);

    long countByTask(Task task);

    @Modifying
    @Transactional
    void deleteByTaskAndCheckinDate(Task task, LocalDate date);

    @Query("SELECT h.task.id FROM HabitCheckin h WHERE h.checkinDate = :date")
    Set<Long> findTodayCheckinTaskIds(@Param("date") LocalDate date);
}
