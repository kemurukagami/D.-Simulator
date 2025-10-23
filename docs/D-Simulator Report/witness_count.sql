 SELECT a.inhabitant_id, MIN(a_info.first_name), MIN(a_info.last_name),
        COUNT(b.inhabitant_id) AS c
   FROM loc_time AS a
        JOIN inhabitant AS a_info
        ON a_info.inhabitant_id = a.inhabitant_id
        JOIN loc_time AS b
        ON a.inhabitant_id <> b.inhabitant_id
           AND a.vertex_id = b.vertex_id
           AND ((a.arrive <= b.arrive AND b.arrive <= a.leave)
                OR (a.arrive <= b.leave AND b.leave <= a.leave))
           AND (a_info.dead = FALSE OR a.arrive
                <= (SELECT MIN(min_of_death) FROM victim WHERE victim_id = a.inhabitant_id))
           AND b_info.dead = FALSE
        JOIN inhabitant AS b_info
        ON b_info.inhabitant_id = b.inhabitant_id
   WHERE a.vertex_id = ?
GROUP BY a.inhabitant_id
ORDER BY c DESC
