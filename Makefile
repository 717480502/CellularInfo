
# ============================================
# CellularInfo - GitHub Actions Build
# 普通未越狱 iPhone / Sideloadly 测试版
# ============================================

ARCHS := arm64
TARGET := iphone:clang:latest:12.0

INSTALL_TARGET_PROCESSES = CellularInfo

# 项目信息
XCODEPROJ_NAME = CellularInfo
BUILD_VERSION = 1.1.2
FILE_NAME = com.developlab.cellularinfo

# Theos
include $(THEOS)/makefiles/common.mk
include $(THEOS_MAKE_PATH)/xcodeproj.mk

# ============================================
# 记录构建开始时间
# ============================================

before-all::
	@date +%s > "$(CURDIR)/.build_start"
	@echo "=================================="
	@echo "Starting CellularInfo build"
	@echo "=================================="

# ============================================
# RootHelper
# 普通未越狱 iPhone 不构建 RootHelper
# 因为它依赖特殊系统权限
# ============================================

# SUBPROJECTS += CellularInfoRootHelper
# include $(THEOS_MAKE_PATH)/aggregate.mk

# ============================================
# 保存 dSYM
# ============================================

after-stage::
	@echo "Collecting dSYM..."
	@mkdir -p "$(CURDIR)/packages"
	@DSYM_SRC="$$(find "$$HOME/Library/Developer/Xcode/DerivedData" -name "$(XCODEPROJ_NAME).app.dSYM" -type d 2>/dev/null | head -n 1)"; \
	if [ -n "$$DSYM_SRC" ] && [ -d "$$DSYM_SRC" ]; then \
		DSYM_DST="$(CURDIR)/packages/$(FILE_NAME)_$(BUILD_VERSION).dSYM"; \
		rm -rf "$$DSYM_DST"; \
		cp -R "$$DSYM_SRC" "$$DSYM_DST"; \
		echo "dSYM copied successfully"; \
	else \
		echo "No dSYM found, skipping"; \
	fi

# ============================================
# 打包前检查
# 不执行特权 ldid 重签名
# ============================================

before-package::
	@echo "=================================="
	@echo "Preparing application package"
	@echo "=================================="
	@APP="$(THEOS_STAGING_DIR)/Applications/$(XCODEPROJ_NAME).app"; \
	if [ ! -d "$$APP" ]; then \
		echo "ERROR: App directory not found"; \
		exit 1; \
	fi; \
	if [ ! -f "$$APP/Info.plist" ]; then \
		echo "ERROR: Info.plist missing"; \
		exit 1; \
	fi; \
	EXEC_NAME="$$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$$APP/Info.plist" 2>/dev/null || true)"; \
	if [ -z "$$EXEC_NAME" ]; then \
		echo "ERROR: CFBundleExecutable missing"; \
		exit 1; \
	fi; \
	if [ ! -f "$$APP/$$EXEC_NAME" ]; then \
		echo "ERROR: App executable not found"; \
		exit 1; \
	fi; \
	echo "Executable: $$EXEC_NAME"; \
	echo "App validation passed"

	@echo "Skipping privileged ldid signing"

# ============================================
# 不再复制 RootHelper
# ============================================

	@echo "RootHelper packaging disabled"

# ============================================
# 打包完成
# 保留 IPA 格式，供 Sideloadly 使用
# ============================================

after-package::
	@echo "=================================="
	@echo "Checking generated IPA"
	@echo "=================================="

	@FOUND=0; \
	for IPA in "$(CURDIR)"/packages/*.ipa; do \
		if [ -f "$$IPA" ]; then \
			echo "IPA found: $$IPA"; \
			ls -lh "$$IPA"; \
			FOUND=1; \
		fi; \
	done; \
	if [ "$$FOUND" -eq 0 ]; then \
		echo "ERROR: No IPA file generated"; \
		exit 1; \
	fi

	@START=$$(cat "$(CURDIR)/.build_start" 2>/dev/null || date +%s); \
	END=$$(date +%s); \
	DURATION=$$((END - START)); \
	echo "Build duration: $$DURATION seconds"; \
	rm -f "$(CURDIR)/.build_start"

	@echo "=================================="
	@echo "CellularInfo packaging completed"
	@echo "=================================="
