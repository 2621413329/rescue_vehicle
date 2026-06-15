# 抢救车效期管理系统 - Flutter 移动端



## 技术栈



- Flutter 3.x + Material Design 3

- Riverpod（模块化 Provider）

- GoRouter（路由 + 底部导航 Shell）

- Dio + flutter_dotenv（API 对接）

- Clean Architecture 模块划分



## 快速启动



在项目根目录已启动后端的前提下：



```powershell

# 本机（Windows / 已连接的本机设备）

..\scripts\start-mobile.ps1



# Android 模拟器

..\scripts\start-mobile.ps1 emulator



# Android 真机

..\scripts\start-mobile.ps1 device

```



手动启动：



```powershell

cd mobile

flutter pub get

flutter run

flutter run --dart-define=ENV_FILE=.env.android.emulator

flutter run --dart-define=ENV_FILE=.env.android.device

```



## API 地址（`.env`，后端端口 7080）



| 场景 | `API_BASE_URL` | env 文件 |

|------|----------------|----------|

| 本机 Windows / iOS 模拟器 | `http://127.0.0.1:7080/api/v1` | `.env` |

| Android 模拟器 | `http://10.0.2.2:7080/api/v1` | `.env.android.emulator` |

| Android 真机 | `http://<局域网IP>:7080/api/v1` | `.env.android.device` |



首次配置：`copy .env.example .env`



真机联调：编辑 `.env.android.device` 中的 IP（`ipconfig` 查看），并确保后端 `.\scripts\start-backend.ps1` 已运行。

## 打包 APK（Release）

```powershell
cd D:\tradition\med

# 推荐：脚本（默认 API http://172.16.30.130:7080/api/v1）
.\scripts\build-apk.ps1

# 自定义 API 地址（注意必须带 /api/v1）
.\scripts\build-apk.ps1 -ApiBaseUrl "http://172.16.30.130:7080/api/v1"

# 或手动
cd mobile
flutter clean
flutter pub get
flutter build apk --release --dart-define=API_BASE_URL=http://172.16.30.130:7080/api/v1
```

输出：`mobile\build\app\outputs\flutter-apk\app-release.apk`

安装到已连接设备/模拟器：
```powershell
flutter install --release
# 或
adb install -r build\app\outputs\flutter-apk\app-release.apk
```

> 命令前不要有多余的 `>` 符号；`API_BASE_URL` 需包含完整路径 `/api/v1`。



默认账号：`admin` / `admin`（密码与用户名一致）



## 模块结构



```

lib/

├── core/           # 网络、env 配置

├── theme/          # 医疗蓝白主题

├── router/         # GoRouter + 底部导航

├── shared/widgets/ # 复用组件

└── modules/

    ├── auth/       # 登录

    ├── dashboard/  # 首页驾驶舱

    ├── inventory/  # 库存卡片

    ├── inspection/ # 巡检

    ├── warning/    # 任务通知

    ├── cart/       # 抢救车

    ├── label/      # 标签中心

    ├── audit/      # 审计日志

    └── profile/    # 我的

```



## 风险色彩



| 状态 | 色值 |

|------|------|

| 正常 | #52C41A |

| 关注 | #FAAD14 |

| 危险 | #FF4D4F |

| 库存不足 | #FA8C16 |

| 设备维护 | #722ED1 |

