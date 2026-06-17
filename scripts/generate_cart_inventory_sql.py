"""根据抢救车清单生成批量插入 SQL。"""

from datetime import date
from pathlib import Path

# 清单数据: (层级, 物资名称, 数量, 效期YYYY-MM-DD或None, 物资类型)
CHECKLIST = [
    # 第一层
    (1, "呋塞米", 2, "2027-03-20", "MEDICINE"),
    (1, "去乙酰毛花苷注射液(西地兰)", 2, "2027-01-01", "MEDICINE"),
    (1, "盐酸胺碘酮注射液", 3, "2027-12-29", "MEDICINE"),
    (1, "硫酸阿托品注射液", 2, "2027-08-01", "MEDICINE"),
    (1, "盐酸多巴胺注射液", 2, "2028-08-04", "MEDICINE"),
    (1, "注射用甲泼尼龙琥珀酸钠", 2, "2027-01-01", "MEDICINE"),
    (1, "盐酸肾上腺素注射液", 5, "2026-08-01", "MEDICINE"),
    (1, "盐酸异丙肾上腺素注射器", 1, "2026-07-01", "MEDICINE"),
    (1, "重酒石酸去甲肾上腺素", 4, "2027-03-01", "MEDICINE"),
    # 第二层
    (2, "盐酸纳洛酮", 1, "2027-04-01", "MEDICINE"),
    (2, "盐酸利多卡因", 2, "2028-08-01", "MEDICINE"),
    (2, "葡萄糖酸钙", 2, "2026-10-01", "MEDICINE"),
    (2, "尼可刹米注射液", 2, "2027-12-01", "MEDICINE"),
    (2, "地西泮注射液", 2, "2026-07-20", "MEDICINE"),
    (2, "硝酸甘油注射液", 2, "2027-01-01", "MEDICINE"),
    (2, "盐酸乌拉地尔注射液", 2, "2026-10-01", "MEDICINE"),
    (2, "盐酸异丙嗪", 1, "2027-03-01", "MEDICINE"),
    (2, "硝酸甘油片", 1, "2027-03-01", "MEDICINE"),
    (2, "电插板", 2, "2027-11-01", "EQUIPMENT"),
    # 第三层
    (3, "50%葡萄糖", 2, "2027-07-01", "MEDICINE"),
    (3, "0.9%氯化钠100ml", 1, "2027-10-01", "MEDICINE"),
    (3, "0.9%氯化钠250ml", 1, "2027-08-01", "MEDICINE"),
    (3, "0.9%氯化钠500ml", 1, "2027-10-01", "MEDICINE"),
    (3, "5%葡萄糖注射液250ml", 1, "2028-01-01", "MEDICINE"),
    (3, "5%葡萄糖氯化钠250ml", 1, "2027-08-01", "MEDICINE"),
    (3, "5%碳酸氢钠250ml", 1, "2027-01-01", "MEDICINE"),
    (3, "20%甘露醇250ml", 1, "2027-01-01", "MEDICINE"),
    # 第四层
    (4, "气切包", 1, "2026-10-10", "CONSUMABLE"),
    (4, "气管套管", 2, "2026-08-10", "CONSUMABLE"),
    (4, "面罩", 1, "2027-05-01", "CONSUMABLE"),
    (4, "舌钳", 1, "2028-08-01", "EQUIPMENT"),
    (4, "压舌板", 1, "2026-11-01", "CONSUMABLE"),
    (4, "开口器", 1, "2026-11-01", "CONSUMABLE"),
    (4, "纱布", 2, "2027-05-01", "CONSUMABLE"),
    (4, "绷带", 2, None, "CONSUMABLE"),
    (4, "棉球", 2, "2027-07-01", "CONSUMABLE"),
    (4, "无菌手套", 2, "2027-07-01", "CONSUMABLE"),
    (4, "空针2ml", 3, "2028-01-01", "CONSUMABLE"),
    (4, "空针5ml", 3, "2028-09-01", "CONSUMABLE"),
    (4, "空针10ml", 3, "2028-06-01", "CONSUMABLE"),
    (4, "空针20ml", 3, "2027-01-01", "CONSUMABLE"),
    (4, "空针50ml", 1, "2027-02-01", "CONSUMABLE"),
    (4, "1.2号针头", 3, "2030-01-01", "CONSUMABLE"),
    (4, "输血器", 2, "2027-01-01", "CONSUMABLE"),
    (4, "输液器", 2, "2027-11-01", "CONSUMABLE"),
    (4, "敷贴", 2, "2028-01-01", "CONSUMABLE"),
    (4, "留置针", 2, "2028-01-01", "CONSUMABLE"),
    (4, "棉签", 5, "2027-03-01", "CONSUMABLE"),
    (4, "9号头皮针", 2, "2027-09-01", "CONSUMABLE"),
    (4, "采血针", 2, "2027-02-01", "CONSUMABLE"),
    (4, "肤必净", 1, "2028-01-01", "CONSUMABLE"),
    (4, "氯己定", 1, "2027-05-01", "CONSUMABLE"),
    (4, "胶布", 1, None, "CONSUMABLE"),
    (4, "换药包", 1, "2027-01-01", "CONSUMABLE"),
    (4, "压脉带", 1, None, "CONSUMABLE"),
    (4, "小方盘", 1, None, "EQUIPMENT"),
    # 第五层
    (5, "简易呼吸器", 1, "2026-11-01", "RESCUE_SUPPLY"),
    (5, "口咽通气管", 3, "2027-06-01", "RESCUE_SUPPLY"),
    (5, "血压计", 1, "2026-09-01", "EQUIPMENT"),
    (5, "听诊器", 1, None, "EQUIPMENT"),
    (5, "电极片", 1, "2027-08-01", "CONSUMABLE"),
    (5, "吸氧装置贝舒清", 1, "2027-10-01", "RESCUE_SUPPLY"),
    (5, "弯盘", 1, None, "EQUIPMENT"),
    (5, "止血带", 1, "2028-10-10", "CONSUMABLE"),
    (5, "PE手套", 1, "2027-08-01", "CONSUMABLE"),
    (5, "胃管", 3, "2026-07-25", "CONSUMABLE"),
    (5, "桔管", 3, "2027-01-01", "CONSUMABLE"),
    (5, "泵管", 3, "2027-04-01", "CONSUMABLE"),
    (5, "尿管", 1, "2026-12-01", "CONSUMABLE"),
    (5, "应急灯", 1, "2026-08-02", "EQUIPMENT"),
    (5, "真空表", 1, "2025-09-01", "EQUIPMENT"),
    (5, "吸引连接管", 2, "2026-12-01", "CONSUMABLE"),
    (5, "砂轮", 1, None, "CONSUMABLE"),
    (5, "氧气头(小)", 1, "2026-09-01", "RESCUE_SUPPLY"),
    (5, "电筒", 1, None, "EQUIPMENT"),
    (5, "引流瓶", 1, None, "EQUIPMENT"),
    (5, "电插板", 1, None, "EQUIPMENT"),
    (5, "吸痰管", 2, "2028-01-01", "CONSUMABLE"),
    (5, "氧气面罩", 1, "2028-06-01", "RESCUE_SUPPLY"),
    (5, "一次性麻醉面罩", 1, "2028-01-01", "CONSUMABLE"),
    (5, "简易呼吸器储氧袋", 1, "2028-08-01", "RESCUE_SUPPLY"),
]

CART_CODE = "ER-CART-001"
CART_NAME = "急诊1号抢救车"
DEPARTMENT_NAME = "急诊科"


def sql_str(value: str) -> str:
    return value.replace("'", "''")


def main() -> None:
    # 去重物资主数据（按名称）
    items_map: dict[str, str] = {}
    for _, name, _, _, item_type in CHECKLIST:
        if name not in items_map:
            code = f"ITEM-{len(items_map) + 1:03d}"
            items_map[name] = (code, item_type)

    lines: list[str] = [
        "-- 抢救车清单批量导入 SQL",
        "-- 生成自 scripts/generate_cart_inventory_sql.py",
        "-- 表结构: departments -> crash_carts -> crash_cart_layers -> items -> inventories",
        "",
        "BEGIN;",
        "",
        "-- ========== 1. 确保科室存在 ==========",
        f"INSERT INTO departments (name, description)",
        f"VALUES ('{sql_str(DEPARTMENT_NAME)}', '{sql_str(DEPARTMENT_NAME)}')",
        "ON CONFLICT (name) DO NOTHING;",
        "",
        "-- ========== 2. 抢救车（若已存在则跳过） ==========",
        "INSERT INTO crash_carts (department_id, cart_code, cart_name, location, manager_name, status)",
        "SELECT d.id,",
        f"       '{sql_str(CART_CODE)}',",
        f"       '{sql_str(CART_NAME)}',",
        "       '急诊大厅',",
        "       '值班护士',",
        "       'ACTIVE'",
        "FROM departments d",
        f"WHERE d.name = '{sql_str(DEPARTMENT_NAME)}' AND d.is_deleted = FALSE",
        "ON CONFLICT (cart_code) DO NOTHING;",
        "",
        "-- ========== 3. 五层抽屉 ==========",
    ]

    for layer_no in range(1, 6):
        lines.extend([
            "INSERT INTO crash_cart_layers (cart_id, layer_no, layer_name, sort_order)",
            "SELECT c.id,",
            f"       {layer_no},",
            f"       '{layer_no}',",
            f"       {layer_no}",
            "FROM crash_carts c",
            f"WHERE c.cart_code = '{sql_str(CART_CODE)}' AND c.is_deleted = FALSE",
            "ON CONFLICT (cart_id, layer_no) DO NOTHING;",
            "",
        ])

    lines.extend([
        "-- ========== 4. 物资主数据 ==========",
        "INSERT INTO items (item_code, item_name, item_type, warning_days, default_warning_tag)",
        "VALUES",
    ])

    item_values = []
    for name, (code, item_type) in items_map.items():
        item_values.append(
            f"    ('{code}', '{sql_str(name)}', '{item_type}', 180, '6个月预警')"
        )
    lines.append(",\n".join(item_values))
    lines.extend([
        "ON CONFLICT (item_code) DO UPDATE SET",
        "    item_name = EXCLUDED.item_name,",
        "    item_type = EXCLUDED.item_type,",
        "    updated_at = NOW();",
        "",
        "-- ========== 5. 清理该抢救车已有库存（先删标签打印记录，避免外键约束） ==========",
        "DELETE FROM label_print_records",
        "WHERE inventory_id IN (",
        "    SELECT inv.id FROM inventories inv",
        "    JOIN crash_carts c ON c.id = inv.cart_id",
        f"    WHERE c.cart_code = '{sql_str(CART_CODE)}' AND c.is_deleted = FALSE",
        ");",
        "",
        "DELETE FROM inventories",
        "WHERE cart_id = (",
        "    SELECT id FROM crash_carts",
        f"    WHERE cart_code = '{sql_str(CART_CODE)}' AND is_deleted = FALSE",
        ");",
        "",
        "-- ========== 6. 库存记录（效期字段按 CURRENT_DATE 自动计算） ==========",
        "INSERT INTO inventories (",
        "    item_id, cart_id, layer_id,",
        "    quantity, minimum_quantity, expiry_date,",
        "    warning_days, warning_tag,",
        "    remaining_days, expiry_status, label_color,",
        "    is_near_expiry, is_expired, is_low_stock",
        ")",
        "SELECT",
        "    i.id,",
        "    c.id,",
        "    l.id,",
        "    v.quantity,",
        "    v.quantity,",
        "    v.expiry_date,",
        "    180,",
        "    '6个月预警',",
        "    CASE WHEN v.expiry_date IS NULL THEN NULL ELSE (v.expiry_date - CURRENT_DATE) END,",
        "    CASE",
        "        WHEN v.expiry_date IS NULL THEN 'NORMAL'",
        "        WHEN v.expiry_date < CURRENT_DATE THEN 'EXPIRED'",
        "        WHEN v.expiry_date <= CURRENT_DATE + 180 THEN 'WARNING'",
        "        ELSE 'NORMAL'",
        "    END,",
        "    CASE",
        "        WHEN v.expiry_date IS NULL THEN 'GREEN'",
        "        WHEN v.expiry_date < CURRENT_DATE THEN 'RED'",
        "        WHEN v.expiry_date <= CURRENT_DATE + 180 THEN 'YELLOW'",
        "        ELSE 'GREEN'",
        "    END,",
        "    CASE",
        "        WHEN v.expiry_date IS NULL THEN FALSE",
        "        WHEN v.expiry_date < CURRENT_DATE THEN FALSE",
        "        WHEN v.expiry_date <= CURRENT_DATE + 180 THEN TRUE",
        "        ELSE FALSE",
        "    END,",
        "    CASE WHEN v.expiry_date IS NOT NULL AND v.expiry_date < CURRENT_DATE THEN TRUE ELSE FALSE END,",
        "    FALSE",
        "FROM (VALUES",
    ])

    inv_values = []
    for layer_no, name, qty, expiry, _ in CHECKLIST:
        code = items_map[name][0]
        expiry_sql = "NULL" if expiry is None else f"'{expiry}'::date"
        inv_values.append(
            f"    ({layer_no}, '{code}', {qty}, {expiry_sql})"
        )
    lines.append(",\n".join(inv_values))
    lines.extend([
        ") AS v(layer_no, item_code, quantity, expiry_date)",
        "JOIN items i ON i.item_code = v.item_code AND i.is_deleted = FALSE",
        f"JOIN crash_carts c ON c.cart_code = '{sql_str(CART_CODE)}' AND c.is_deleted = FALSE",
        "JOIN crash_cart_layers l ON l.cart_id = c.id AND l.layer_no = v.layer_no AND l.is_deleted = FALSE;",
        "",
        "COMMIT;",
        "",
        f"-- 共 {len(items_map)} 种物资，{len(CHECKLIST)} 条库存记录",
    ])

    out = Path(__file__).resolve().parents[1] / "sql" / "seed_cart_inventory.sql"
    out.write_text("\n".join(lines), encoding="utf-8")
    print(f"Generated: {out}")
    print(f"  Items: {len(items_map)}, Inventories: {len(CHECKLIST)}")


if __name__ == "__main__":
    main()
