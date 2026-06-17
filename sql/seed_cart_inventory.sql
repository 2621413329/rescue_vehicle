-- 抢救车清单批量导入 SQL
-- 生成自 scripts/generate_cart_inventory_sql.py
-- 表结构: departments -> crash_carts -> crash_cart_layers -> items -> inventories

BEGIN;

-- ========== 1. 确保科室存在 ==========
INSERT INTO departments (name, description)
VALUES ('急诊科', '急诊科')
ON CONFLICT (name) DO NOTHING;

-- ========== 2. 抢救车（若已存在则跳过） ==========
INSERT INTO crash_carts (department_id, cart_code, cart_name, location, manager_name, status)
SELECT d.id,
       'ER-CART-001',
       '急诊1号抢救车',
       '急诊大厅',
       '值班护士',
       'ACTIVE'
FROM departments d
WHERE d.name = '急诊科' AND d.is_deleted = FALSE
ON CONFLICT (cart_code) DO NOTHING;

-- ========== 3. 五层抽屉 ==========
INSERT INTO crash_cart_layers (cart_id, layer_no, layer_name, sort_order)
SELECT c.id,
       1,
       '1',
       1
FROM crash_carts c
WHERE c.cart_code = 'ER-CART-001' AND c.is_deleted = FALSE
ON CONFLICT (cart_id, layer_no) DO NOTHING;

INSERT INTO crash_cart_layers (cart_id, layer_no, layer_name, sort_order)
SELECT c.id,
       2,
       '2',
       2
FROM crash_carts c
WHERE c.cart_code = 'ER-CART-001' AND c.is_deleted = FALSE
ON CONFLICT (cart_id, layer_no) DO NOTHING;

INSERT INTO crash_cart_layers (cart_id, layer_no, layer_name, sort_order)
SELECT c.id,
       3,
       '3',
       3
FROM crash_carts c
WHERE c.cart_code = 'ER-CART-001' AND c.is_deleted = FALSE
ON CONFLICT (cart_id, layer_no) DO NOTHING;

INSERT INTO crash_cart_layers (cart_id, layer_no, layer_name, sort_order)
SELECT c.id,
       4,
       '4',
       4
FROM crash_carts c
WHERE c.cart_code = 'ER-CART-001' AND c.is_deleted = FALSE
ON CONFLICT (cart_id, layer_no) DO NOTHING;

INSERT INTO crash_cart_layers (cart_id, layer_no, layer_name, sort_order)
SELECT c.id,
       5,
       '5',
       5
FROM crash_carts c
WHERE c.cart_code = 'ER-CART-001' AND c.is_deleted = FALSE
ON CONFLICT (cart_id, layer_no) DO NOTHING;

-- ========== 4. 物资主数据 ==========
INSERT INTO items (item_code, item_name, item_type, warning_days, default_warning_tag)
VALUES
    ('ITEM-001', '呋塞米', 'MEDICINE', 180, '6个月预警'),
    ('ITEM-002', '去乙酰毛花苷注射液(西地兰)', 'MEDICINE', 180, '6个月预警'),
    ('ITEM-003', '盐酸胺碘酮注射液', 'MEDICINE', 180, '6个月预警'),
    ('ITEM-004', '硫酸阿托品注射液', 'MEDICINE', 180, '6个月预警'),
    ('ITEM-005', '盐酸多巴胺注射液', 'MEDICINE', 180, '6个月预警'),
    ('ITEM-006', '注射用甲泼尼龙琥珀酸钠', 'MEDICINE', 180, '6个月预警'),
    ('ITEM-007', '盐酸肾上腺素注射液', 'MEDICINE', 180, '6个月预警'),
    ('ITEM-008', '盐酸异丙肾上腺素注射器', 'MEDICINE', 180, '6个月预警'),
    ('ITEM-009', '重酒石酸去甲肾上腺素', 'MEDICINE', 180, '6个月预警'),
    ('ITEM-010', '盐酸纳洛酮', 'MEDICINE', 180, '6个月预警'),
    ('ITEM-011', '盐酸利多卡因', 'MEDICINE', 180, '6个月预警'),
    ('ITEM-012', '葡萄糖酸钙', 'MEDICINE', 180, '6个月预警'),
    ('ITEM-013', '尼可刹米注射液', 'MEDICINE', 180, '6个月预警'),
    ('ITEM-014', '地西泮注射液', 'MEDICINE', 180, '6个月预警'),
    ('ITEM-015', '硝酸甘油注射液', 'MEDICINE', 180, '6个月预警'),
    ('ITEM-016', '盐酸乌拉地尔注射液', 'MEDICINE', 180, '6个月预警'),
    ('ITEM-017', '盐酸异丙嗪', 'MEDICINE', 180, '6个月预警'),
    ('ITEM-018', '硝酸甘油片', 'MEDICINE', 180, '6个月预警'),
    ('ITEM-019', '电插板', 'EQUIPMENT', 180, '6个月预警'),
    ('ITEM-020', '50%葡萄糖', 'MEDICINE', 180, '6个月预警'),
    ('ITEM-021', '0.9%氯化钠100ml', 'MEDICINE', 180, '6个月预警'),
    ('ITEM-022', '0.9%氯化钠250ml', 'MEDICINE', 180, '6个月预警'),
    ('ITEM-023', '0.9%氯化钠500ml', 'MEDICINE', 180, '6个月预警'),
    ('ITEM-024', '5%葡萄糖注射液250ml', 'MEDICINE', 180, '6个月预警'),
    ('ITEM-025', '5%葡萄糖氯化钠250ml', 'MEDICINE', 180, '6个月预警'),
    ('ITEM-026', '5%碳酸氢钠250ml', 'MEDICINE', 180, '6个月预警'),
    ('ITEM-027', '20%甘露醇250ml', 'MEDICINE', 180, '6个月预警'),
    ('ITEM-028', '气切包', 'CONSUMABLE', 180, '6个月预警'),
    ('ITEM-029', '气管套管', 'CONSUMABLE', 180, '6个月预警'),
    ('ITEM-030', '面罩', 'CONSUMABLE', 180, '6个月预警'),
    ('ITEM-031', '舌钳', 'EQUIPMENT', 180, '6个月预警'),
    ('ITEM-032', '压舌板', 'CONSUMABLE', 180, '6个月预警'),
    ('ITEM-033', '开口器', 'CONSUMABLE', 180, '6个月预警'),
    ('ITEM-034', '纱布', 'CONSUMABLE', 180, '6个月预警'),
    ('ITEM-035', '绷带', 'CONSUMABLE', 180, '6个月预警'),
    ('ITEM-036', '棉球', 'CONSUMABLE', 180, '6个月预警'),
    ('ITEM-037', '无菌手套', 'CONSUMABLE', 180, '6个月预警'),
    ('ITEM-038', '空针2ml', 'CONSUMABLE', 180, '6个月预警'),
    ('ITEM-039', '空针5ml', 'CONSUMABLE', 180, '6个月预警'),
    ('ITEM-040', '空针10ml', 'CONSUMABLE', 180, '6个月预警'),
    ('ITEM-041', '空针20ml', 'CONSUMABLE', 180, '6个月预警'),
    ('ITEM-042', '空针50ml', 'CONSUMABLE', 180, '6个月预警'),
    ('ITEM-043', '1.2号针头', 'CONSUMABLE', 180, '6个月预警'),
    ('ITEM-044', '输血器', 'CONSUMABLE', 180, '6个月预警'),
    ('ITEM-045', '输液器', 'CONSUMABLE', 180, '6个月预警'),
    ('ITEM-046', '敷贴', 'CONSUMABLE', 180, '6个月预警'),
    ('ITEM-047', '留置针', 'CONSUMABLE', 180, '6个月预警'),
    ('ITEM-048', '棉签', 'CONSUMABLE', 180, '6个月预警'),
    ('ITEM-049', '9号头皮针', 'CONSUMABLE', 180, '6个月预警'),
    ('ITEM-050', '采血针', 'CONSUMABLE', 180, '6个月预警'),
    ('ITEM-051', '肤必净', 'CONSUMABLE', 180, '6个月预警'),
    ('ITEM-052', '氯己定', 'CONSUMABLE', 180, '6个月预警'),
    ('ITEM-053', '胶布', 'CONSUMABLE', 180, '6个月预警'),
    ('ITEM-054', '换药包', 'CONSUMABLE', 180, '6个月预警'),
    ('ITEM-055', '压脉带', 'CONSUMABLE', 180, '6个月预警'),
    ('ITEM-056', '小方盘', 'EQUIPMENT', 180, '6个月预警'),
    ('ITEM-057', '简易呼吸器', 'RESCUE_SUPPLY', 180, '6个月预警'),
    ('ITEM-058', '口咽通气管', 'RESCUE_SUPPLY', 180, '6个月预警'),
    ('ITEM-059', '血压计', 'EQUIPMENT', 180, '6个月预警'),
    ('ITEM-060', '听诊器', 'EQUIPMENT', 180, '6个月预警'),
    ('ITEM-061', '电极片', 'CONSUMABLE', 180, '6个月预警'),
    ('ITEM-062', '吸氧装置贝舒清', 'RESCUE_SUPPLY', 180, '6个月预警'),
    ('ITEM-063', '弯盘', 'EQUIPMENT', 180, '6个月预警'),
    ('ITEM-064', '止血带', 'CONSUMABLE', 180, '6个月预警'),
    ('ITEM-065', 'PE手套', 'CONSUMABLE', 180, '6个月预警'),
    ('ITEM-066', '胃管', 'CONSUMABLE', 180, '6个月预警'),
    ('ITEM-067', '桔管', 'CONSUMABLE', 180, '6个月预警'),
    ('ITEM-068', '泵管', 'CONSUMABLE', 180, '6个月预警'),
    ('ITEM-069', '尿管', 'CONSUMABLE', 180, '6个月预警'),
    ('ITEM-070', '应急灯', 'EQUIPMENT', 180, '6个月预警'),
    ('ITEM-071', '真空表', 'EQUIPMENT', 180, '6个月预警'),
    ('ITEM-072', '吸引连接管', 'CONSUMABLE', 180, '6个月预警'),
    ('ITEM-073', '砂轮', 'CONSUMABLE', 180, '6个月预警'),
    ('ITEM-074', '氧气头(小)', 'RESCUE_SUPPLY', 180, '6个月预警'),
    ('ITEM-075', '电筒', 'EQUIPMENT', 180, '6个月预警'),
    ('ITEM-076', '引流瓶', 'EQUIPMENT', 180, '6个月预警'),
    ('ITEM-077', '吸痰管', 'CONSUMABLE', 180, '6个月预警'),
    ('ITEM-078', '氧气面罩', 'RESCUE_SUPPLY', 180, '6个月预警'),
    ('ITEM-079', '一次性麻醉面罩', 'CONSUMABLE', 180, '6个月预警'),
    ('ITEM-080', '简易呼吸器储氧袋', 'RESCUE_SUPPLY', 180, '6个月预警')
ON CONFLICT (item_code) DO UPDATE SET
    item_name = EXCLUDED.item_name,
    item_type = EXCLUDED.item_type,
    updated_at = NOW();

-- ========== 5. 清理该抢救车已有库存（先删标签打印记录，避免外键约束） ==========
DELETE FROM label_print_records
WHERE inventory_id IN (
    SELECT inv.id FROM inventories inv
    JOIN crash_carts c ON c.id = inv.cart_id
    WHERE c.cart_code = 'ER-CART-001' AND c.is_deleted = FALSE
);

DELETE FROM inventories
WHERE cart_id = (
    SELECT id FROM crash_carts
    WHERE cart_code = 'ER-CART-001' AND is_deleted = FALSE
);

-- ========== 6. 库存记录（效期字段按 CURRENT_DATE 自动计算） ==========
INSERT INTO inventories (
    item_id, cart_id, layer_id,
    quantity, minimum_quantity, expiry_date,
    warning_days, warning_tag,
    remaining_days, expiry_status, label_color,
    is_near_expiry, is_expired, is_low_stock
)
SELECT
    i.id,
    c.id,
    l.id,
    v.quantity,
    v.quantity,
    v.expiry_date,
    180,
    '6个月预警',
    CASE WHEN v.expiry_date IS NULL THEN NULL ELSE (v.expiry_date - CURRENT_DATE) END,
    CASE
        WHEN v.expiry_date IS NULL THEN 'NORMAL'
        WHEN v.expiry_date < CURRENT_DATE THEN 'EXPIRED'
        WHEN v.expiry_date <= CURRENT_DATE + 180 THEN 'WARNING'
        ELSE 'NORMAL'
    END,
    CASE
        WHEN v.expiry_date IS NULL THEN 'GREEN'
        WHEN v.expiry_date < CURRENT_DATE THEN 'RED'
        WHEN v.expiry_date <= CURRENT_DATE + 180 THEN 'YELLOW'
        ELSE 'GREEN'
    END,
    CASE
        WHEN v.expiry_date IS NULL THEN FALSE
        WHEN v.expiry_date < CURRENT_DATE THEN FALSE
        WHEN v.expiry_date <= CURRENT_DATE + 180 THEN TRUE
        ELSE FALSE
    END,
    CASE WHEN v.expiry_date IS NOT NULL AND v.expiry_date < CURRENT_DATE THEN TRUE ELSE FALSE END,
    FALSE
FROM (VALUES
    (1, 'ITEM-001', 2, '2027-03-20'::date),
    (1, 'ITEM-002', 2, '2027-01-01'::date),
    (1, 'ITEM-003', 3, '2027-12-29'::date),
    (1, 'ITEM-004', 2, '2027-08-01'::date),
    (1, 'ITEM-005', 2, '2028-08-04'::date),
    (1, 'ITEM-006', 2, '2027-01-01'::date),
    (1, 'ITEM-007', 5, '2026-08-01'::date),
    (1, 'ITEM-008', 1, '2026-07-01'::date),
    (1, 'ITEM-009', 4, '2027-03-01'::date),
    (2, 'ITEM-010', 1, '2027-04-01'::date),
    (2, 'ITEM-011', 2, '2028-08-01'::date),
    (2, 'ITEM-012', 2, '2026-10-01'::date),
    (2, 'ITEM-013', 2, '2027-12-01'::date),
    (2, 'ITEM-014', 2, '2026-07-20'::date),
    (2, 'ITEM-015', 2, '2027-01-01'::date),
    (2, 'ITEM-016', 2, '2026-10-01'::date),
    (2, 'ITEM-017', 1, '2027-03-01'::date),
    (2, 'ITEM-018', 1, '2027-03-01'::date),
    (2, 'ITEM-019', 2, '2027-11-01'::date),
    (3, 'ITEM-020', 2, '2027-07-01'::date),
    (3, 'ITEM-021', 1, '2027-10-01'::date),
    (3, 'ITEM-022', 1, '2027-08-01'::date),
    (3, 'ITEM-023', 1, '2027-10-01'::date),
    (3, 'ITEM-024', 1, '2028-01-01'::date),
    (3, 'ITEM-025', 1, '2027-08-01'::date),
    (3, 'ITEM-026', 1, '2027-01-01'::date),
    (3, 'ITEM-027', 1, '2027-01-01'::date),
    (4, 'ITEM-028', 1, '2026-10-10'::date),
    (4, 'ITEM-029', 2, '2026-08-10'::date),
    (4, 'ITEM-030', 1, '2027-05-01'::date),
    (4, 'ITEM-031', 1, '2028-08-01'::date),
    (4, 'ITEM-032', 1, '2026-11-01'::date),
    (4, 'ITEM-033', 1, '2026-11-01'::date),
    (4, 'ITEM-034', 2, '2027-05-01'::date),
    (4, 'ITEM-035', 2, NULL),
    (4, 'ITEM-036', 2, '2027-07-01'::date),
    (4, 'ITEM-037', 2, '2027-07-01'::date),
    (4, 'ITEM-038', 3, '2028-01-01'::date),
    (4, 'ITEM-039', 3, '2028-09-01'::date),
    (4, 'ITEM-040', 3, '2028-06-01'::date),
    (4, 'ITEM-041', 3, '2027-01-01'::date),
    (4, 'ITEM-042', 1, '2027-02-01'::date),
    (4, 'ITEM-043', 3, '2030-01-01'::date),
    (4, 'ITEM-044', 2, '2027-01-01'::date),
    (4, 'ITEM-045', 2, '2027-11-01'::date),
    (4, 'ITEM-046', 2, '2028-01-01'::date),
    (4, 'ITEM-047', 2, '2028-01-01'::date),
    (4, 'ITEM-048', 5, '2027-03-01'::date),
    (4, 'ITEM-049', 2, '2027-09-01'::date),
    (4, 'ITEM-050', 2, '2027-02-01'::date),
    (4, 'ITEM-051', 1, '2028-01-01'::date),
    (4, 'ITEM-052', 1, '2027-05-01'::date),
    (4, 'ITEM-053', 1, NULL),
    (4, 'ITEM-054', 1, '2027-01-01'::date),
    (4, 'ITEM-055', 1, NULL),
    (4, 'ITEM-056', 1, NULL),
    (5, 'ITEM-057', 1, '2026-11-01'::date),
    (5, 'ITEM-058', 3, '2027-06-01'::date),
    (5, 'ITEM-059', 1, '2026-09-01'::date),
    (5, 'ITEM-060', 1, NULL),
    (5, 'ITEM-061', 1, '2027-08-01'::date),
    (5, 'ITEM-062', 1, '2027-10-01'::date),
    (5, 'ITEM-063', 1, NULL),
    (5, 'ITEM-064', 1, '2028-10-10'::date),
    (5, 'ITEM-065', 1, '2027-08-01'::date),
    (5, 'ITEM-066', 3, '2026-07-25'::date),
    (5, 'ITEM-067', 3, '2027-01-01'::date),
    (5, 'ITEM-068', 3, '2027-04-01'::date),
    (5, 'ITEM-069', 1, '2026-12-01'::date),
    (5, 'ITEM-070', 1, '2026-08-02'::date),
    (5, 'ITEM-071', 1, '2025-09-01'::date),
    (5, 'ITEM-072', 2, '2026-12-01'::date),
    (5, 'ITEM-073', 1, NULL),
    (5, 'ITEM-074', 1, '2026-09-01'::date),
    (5, 'ITEM-075', 1, NULL),
    (5, 'ITEM-076', 1, NULL),
    (5, 'ITEM-019', 1, NULL),
    (5, 'ITEM-077', 2, '2028-01-01'::date),
    (5, 'ITEM-078', 1, '2028-06-01'::date),
    (5, 'ITEM-079', 1, '2028-01-01'::date),
    (5, 'ITEM-080', 1, '2028-08-01'::date)
) AS v(layer_no, item_code, quantity, expiry_date)
JOIN items i ON i.item_code = v.item_code AND i.is_deleted = FALSE
JOIN crash_carts c ON c.cart_code = 'ER-CART-001' AND c.is_deleted = FALSE
JOIN crash_cart_layers l ON l.cart_id = c.id AND l.layer_no = v.layer_no AND l.is_deleted = FALSE;

COMMIT;

-- 共 80 种物资，81 条库存记录