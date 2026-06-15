"""初始化种子数据：超级管理员、科室、示例物资与抢救车。"""

from datetime import date, datetime, timedelta, timezone
from decimal import Decimal

from sqlalchemy.orm import Session

from sqlalchemy import select

from app.core.config import get_settings
from app.core.security import get_password_hash
from app.models.crash_cart import CrashCart, CrashCartLayer
from app.models.department import Department
from app.models.enums import CartStatus, ItemType, UserRole, UserStatus
from app.models.inventory import Inventory
from app.models.item import Item
from app.models.user import User
from app.utils.helpers import calculate_expiry_fields, calculate_low_stock


def seed(db: Session) -> None:
    settings = get_settings()

    if db.scalar(select(User).where(User.username == settings.seed_admin_username)):
        print("Seed data already exists, skipping.")
        return

    # 科室
    er_dept = Department(name="急诊科", description="急诊医学科")
    icu_dept = Department(name="重症医学科", description="ICU")
    db.add_all([er_dept, icu_dept])
    db.flush()

    # 超级管理员
    admin = User(
        username=settings.seed_admin_username,
        password_hash=get_password_hash(settings.seed_admin_username),
        real_name="系统管理员",
        role=UserRole.SUPER_ADMIN,
        status=UserStatus.ACTIVE,
    )
    db.add(admin)
    db.flush()

    # 科室管理员
    dept_admin = User(
        username="dept_admin",
        password_hash=get_password_hash("dept_admin"),
        real_name="急诊科主任",
        department_id=er_dept.id,
        role=UserRole.DEPARTMENT_ADMIN,
        status=UserStatus.ACTIVE,
        created_by=admin.id,
    )
    nurse = User(
        username="nurse01",
        password_hash=get_password_hash("nurse01"),
        real_name="张护士",
        department_id=er_dept.id,
        role=UserRole.NURSE,
        status=UserStatus.ACTIVE,
        created_by=admin.id,
    )
    viewer = User(
        username="viewer01",
        password_hash=get_password_hash("viewer01"),
        real_name="李查看",
        department_id=er_dept.id,
        role=UserRole.VIEWER,
        status=UserStatus.ACTIVE,
        created_by=admin.id,
    )
    db.add_all([dept_admin, nurse, viewer])
    db.flush()

    # 抢救车
    cart = CrashCart(
        department_id=er_dept.id,
        cart_code="ER-CART-001",
        cart_name="急诊1号抢救车",
        location="急诊大厅东侧",
        manager_name="张护士",
        status=CartStatus.ACTIVE,
        created_by=admin.id,
    )
    db.add(cart)
    db.flush()

    layer1 = CrashCartLayer(cart_id=cart.id, layer_no=1, layer_name="第一层-急救药品", sort_order=1)
    layer2 = CrashCartLayer(cart_id=cart.id, layer_no=2, layer_name="第二层-耗材", sort_order=2)
    db.add_all([layer1, layer2])
    db.flush()

    # 物资主数据
    epinephrine = Item(
        item_code="MED-001",
        item_name="肾上腺素",
        item_type=ItemType.MEDICINE,
        specification="1mg/1ml",
        warning_days=180,
        default_warning_tag="6个月预警",
        created_by=admin.id,
    )
    defibrillator_pad = Item(
        item_code="CON-001",
        item_name="除颤电极片",
        item_type=ItemType.CONSUMABLE,
        specification="成人型",
        warning_days=90,
        default_warning_tag="3个月预警",
        created_by=admin.id,
    )
    oxygen_mask = Item(
        item_code="SUP-001",
        item_name="氧气面罩",
        item_type=ItemType.RESCUE_SUPPLY,
        specification="成人",
        warning_days=30,
        default_warning_tag="1个月预警",
        created_by=admin.id,
    )
    db.add_all([epinephrine, defibrillator_pad, oxygen_mask])
    db.flush()

    today = date.today()

    def make_inventory(item: Item, layer: CrashCartLayer, qty: str, min_qty: str, expiry: date):
        inv = Inventory(
            item_id=item.id,
            cart_id=cart.id,
            layer_id=layer.id,
            batch_no=f"B{item.id:03d}",
            quantity=Decimal(qty),
            minimum_quantity=Decimal(min_qty),
            expiry_date=expiry,
            warning_days=item.warning_days,
            warning_tag=item.default_warning_tag,
            created_by=admin.id,
        )
        fields = calculate_expiry_fields(expiry, item.warning_days, today)
        inv.remaining_days = fields["remaining_days"]
        inv.expiry_status = fields["expiry_status"]
        inv.label_color = fields["label_color"]
        inv.is_near_expiry = fields["is_near_expiry"]
        inv.is_expired = fields["is_expired"]
        inv.is_low_stock = calculate_low_stock(inv.quantity, inv.minimum_quantity)
        return inv

    inventories = [
        make_inventory(epinephrine, layer1, "10", "5", today + timedelta(days=200)),
        make_inventory(epinephrine, layer1, "3", "5", today + timedelta(days=60)),
        make_inventory(defibrillator_pad, layer2, "8", "4", today + timedelta(days=45)),
        make_inventory(oxygen_mask, layer2, "2", "5", today + timedelta(days=15)),
        make_inventory(oxygen_mask, layer2, "1", "3", today - timedelta(days=5)),
    ]
    db.add_all(inventories)
    db.commit()
    print("Seed data created successfully.")
    print(f"  Admin: {settings.seed_admin_username} / {settings.seed_admin_username}")
    print("  Dept Admin: dept_admin / dept_admin")
    print("  Nurse: nurse01 / nurse01")
    print("  Viewer: viewer01 / viewer01")


if __name__ == "__main__":
    from app.core.database import SessionLocal

    session = SessionLocal()
    try:
        seed(session)
    finally:
        session.close()
