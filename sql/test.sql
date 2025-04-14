-- 基数估计实体查询
SELECT
    e.entity_name AS '概念',
    e.description AS '描述',
    r.relation_type AS '关系类型',
    e2.entity_name AS '关联概念',
    c.original_text AS '原文引用',
    CONCAT(f.file_name, ' P', p.page_number) AS '来源位置'
FROM
    entities e
LEFT JOIN
    relations r ON e.entity_id = r.source_entity_id
LEFT JOIN
    entities e2 ON e2.entity_id = r.target_entity_id
LEFT JOIN
    citations c ON c.entity_id = e.entity_id
LEFT JOIN
    ppt_pages p ON p.page_id = e.page_id
LEFT JOIN
    ppt_files f ON f.file_id = p.file_id
WHERE
    e.entity_name LIKE '%基数估计%'
    OR e.description LIKE '%基数估计%'
    OR c.original_text LIKE '%基数估计%'
ORDER BY
    f.file_name, p.page_number;

--# 溯源查询（从实体到PPT具体位置）
SELECT
    e.entity_name,
    p.page_number,
    f.file_name,
    pl.x1, pl.y1, pl.x2, pl.y2,
    c.original_text
FROM entities e
JOIN ppt_pages p ON e.page_id = p.page_id
JOIN ppt_files f ON p.file_id = f.file_id
LEFT JOIN page_locations pl ON pl.entity_id = e.entity_id AND pl.page_id = p.page_id
LEFT JOIN citations c ON c.entity_id = e.entity_id
WHERE e.entity_name = '查询优化器';