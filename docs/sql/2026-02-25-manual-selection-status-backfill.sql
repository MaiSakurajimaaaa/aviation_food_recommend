USE aviation_food_recommend;

-- 将历史手动预选记录从 status=1 回填为 status=3（已确认）
-- 规则：单号以 SEL 开头视为人工选择；AUTO 开头保持自动分配逻辑
UPDATE meal_selection
SET status = 3,
    update_time = NOW()
WHERE status = 1
  AND number LIKE 'SEL%';

-- 校验结果
SELECT status, COUNT(*) AS cnt
FROM meal_selection
GROUP BY status
ORDER BY status;
